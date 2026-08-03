import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  // Priority: 1. Local .env file (if initialized)  2. --dart-define flag  3. Project default
  static String get supabaseUrl {
    try {
      if (dotenv.isInitialized) {
        final envVal = dotenv.env['SUPABASE_URL'];
        if (envVal != null && envVal.isNotEmpty) return envVal;
      }
    } catch (_) {}
    const envFlag = String.fromEnvironment('SUPABASE_URL');
    if (envFlag.isNotEmpty) return envFlag;
    return '';
  }

  static String get supabaseAnonKey {
    try {
      if (dotenv.isInitialized) {
        final envVal = dotenv.env['SUPABASE_ANON_KEY'];
        if (envVal != null && envVal.isNotEmpty) return envVal;
      }
    } catch (_) {}
    const envFlag = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envFlag.isNotEmpty) return envFlag;
    return '';
  }

  static bool _isInitialized = false;
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_SUPABASE_URL');

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _profileChannel;
  RealtimeChannel? _callChannel;

  // Send real-time WebRTC & Call Signal via in-memory WebSockets broadcast
  Future<void> sendCallSignal({
    required String pairCode,
    required String senderId,
    required String receiverId,
    required String callerName,
    required String type,
    required bool isVideo,
    Map<String, dynamic>? extraData,
  }) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      final Map<String, dynamic> signalPayload = {
        'type': type,
        'is_video': isVideo,
        'caller_name': callerName,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'pair_code': pairCode,
      };
      if (extraData != null) {
        signalPayload.addAll(extraData);
      }

      // If incoming_call, also insert lightweight record so background notification triggers
      if (type == 'incoming_call') {
        final msgId = 'call_${DateTime.now().millisecondsSinceEpoch}_$senderId';
        final content = '[CALL_SIGNAL]:${jsonEncode(signalPayload)}';
        await Supabase.instance.client.from('messages').insert({
          'id': msgId,
          'pair_code': pairCode,
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content': content,
          'status': 'sent',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Broadcast over in-memory WebSocket channel (0 DB writes, 0 UI freeze)
      _callChannel ??= Supabase.instance.client.channel('call_room_$pairCode');
      await _callChannel!.subscribe();
      await _callChannel!.sendBroadcastMessage(
        event: 'call_signal',
        payload: signalPayload,
      );
    } catch (e) {
      if (kDebugMode) print('Send call signal error: $e');
    }
  }

  // Subscribe to real-time WebSockets Call signals
  void subscribeToCallSignals({
    required String pairCode,
    required Function(Map<String, dynamic> payload) onCallSignal,
  }) {
    if (!_isInitialized || !isConfigured) return;

    _callChannel?.unsubscribe();

    _callChannel =
        Supabase.instance.client.channel('call_room_$pairCode').onBroadcast(
              event: 'call_signal',
              callback: (payload) {
                try {
                  Map<String, dynamic> data = {};
                  if (payload is Map) {
                    if (payload.containsKey('payload') && payload['payload'] is Map) {
                      data = Map<String, dynamic>.from(payload['payload'] as Map);
                    } else {
                      data = Map<String, dynamic>.from(payload);
                    }
                  }
                  onCallSignal(data);
                } catch (e) {
                  if (kDebugMode) print('Broadcast signal payload parse error: $e');
                }
              },
            );

    _callChannel?.subscribe();
  }

  static Future<void> init() async {
    if (!isConfigured) return;
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
    }
  }

  // Fetch messages from Supabase Database
  Future<List<MessageModel>> fetchMessages(String pairCode) async {
    if (!_isInitialized || !isConfigured) return [];
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('pair_code', pairCode)
          .order('created_at', ascending: true);

      final List data = response as List;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Fetch messages error: $e');
      return [];
    }
  }

  // Send a new text message
  Future<MessageModel?> sendMessage(MessageModel msg) async {
    if (!_isInitialized || !isConfigured) return msg;
    try {
      final data = msg.toJson();
      final response = await Supabase.instance.client
          .from('messages')
          .insert(data)
          .select()
          .single();

      return MessageModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) print('Send message error: $e');
      return msg;
    }
  }

  // Update reaction on a message
  Future<void> updateReaction(String messageId, String? reaction) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'reaction': reaction}).eq('id', messageId);
    } catch (e) {
      if (kDebugMode) print('Update reaction error: $e');
    }
  }

  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'status': 'read'}).eq('id', messageId);
    } catch (e) {
      if (kDebugMode) print('Mark read error: $e');
    }
  }

  // Mark all unread messages for receiver as read in Supabase
  Future<void> markAllMessagesAsRead(
      String pairCode, String currentUserId) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'status': 'read'})
          .eq('pair_code', pairCode)
          .eq('receiver_id', currentUserId)
          .neq('status', 'read');
    } catch (e) {
      if (kDebugMode) print('Mark all read error: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      await Supabase.instance.client.from('messages').update({
        'is_deleted': true,
        'content': 'This message was deleted'
      }).eq('id', messageId);
    } catch (e) {
      if (kDebugMode) print('Delete message error: $e');
    }
  }

  // Update online / typing status
  Future<void> updateTypingStatus(String userId, bool isTyping) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      await Supabase.instance.client.from('profiles').update({
        'is_typing': isTyping,
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) print('Update typing error: $e');
    }
  }

  // Fetch profiles for the pair
  Future<List<UserModel>> fetchProfiles(String pairCode) async {
    if (!_isInitialized || !isConfigured) return [];
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('pair_code', pairCode);
      final List list = response as List;
      return list.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) print('Fetch profiles error: $e');
      return [];
    }
  }

  // Clear all messages for both sides from Supabase
  Future<void> clearAllMessages(String pairCode) async {
    if (!_isInitialized || !isConfigured) return;
    try {
      await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('pair_code', pairCode);
    } catch (e) {
      if (kDebugMode) print('Clear all messages error: $e');
    }
  }

  // Subscribe to real-time message stream
  void subscribeToMessages({
    required String pairCode,
    required Function(MessageModel) onNewMessage,
    required Function(MessageModel) onUpdateMessage,
    required VoidCallback onDeleteAllMessages,
  }) {
    if (!_isInitialized || !isConfigured) return;

    _messageChannel?.unsubscribe();

    _messageChannel = Supabase.instance.client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final record = payload.newRecord;
            if (record != null &&
                (record['pair_code'] == pairCode ||
                    record['pair_code'] == null)) {
              final newMsg = MessageModel.fromJson(record);
              onNewMessage(newMsg);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final record = payload.newRecord;
            if (record != null &&
                (record['pair_code'] == pairCode ||
                    record['pair_code'] == null)) {
              final updatedMsg = MessageModel.fromJson(record);
              onUpdateMessage(updatedMsg);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            onDeleteAllMessages();
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _messageChannel?.unsubscribe();
    _profileChannel?.unsubscribe();
  }
}
