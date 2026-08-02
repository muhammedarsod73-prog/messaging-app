import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class ChatProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  final SupabaseService _supabase = SupabaseService();

  List<MessageModel> _messages = [];
  MessageModel? _replyToMessage;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = false;

  ChatProvider(this._storage) {
    _loadInitialMessages();
  }

  List<MessageModel> get messages {
    if (_searchQuery.isEmpty) return _messages;
    return _messages
        .where(
            (m) => m.content.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  MessageModel? get replyToMessage => _replyToMessage;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;

  Future<void> _loadInitialMessages() async {
    _isLoading = true;
    notifyListeners();

    // Load from local storage cache first
    _messages = _storage.getCachedMessages();

    // Try fetching from Supabase if connected
    if (SupabaseService.isConfigured) {
      final remoteMsgs = await _supabase.fetchMessages(_storage.getPairCode());
      if (remoteMsgs.isNotEmpty) {
        _messages = remoteMsgs;
        await _storage.saveCachedMessages(_messages);
      }

      _supabase.subscribeToMessages(
        pairCode: _storage.getPairCode(),
        onNewMessage: (newMsg) => onReceiveRealtimeMessage(newMsg),
        onUpdateMessage: (updatedMsg) => onUpdateRealtimeMessage(updatedMsg),
        onDeleteAllMessages: () => onClearAllRealtimeMessages(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reloadMessages() async {
    if (SupabaseService.isConfigured) {
      final remoteMsgs = await _supabase.fetchMessages(_storage.getPairCode());
      _messages = remoteMsgs;
      await _storage.saveCachedMessages(_messages);
      notifyListeners();
    } else {
      _messages = _storage.getCachedMessages();
      notifyListeners();
    }
  }

  // Clear all messages for both sides
  Future<void> clearAllMessagesForBoth() async {
    _messages.clear();
    _replyToMessage = null;
    await _storage.saveCachedMessages([]);
    notifyListeners();

    if (SupabaseService.isConfigured) {
      await _supabase.clearAllMessages(_storage.getPairCode());
    }
  }

  void onClearAllRealtimeMessages() {
    _messages.clear();
    _replyToMessage = null;
    _storage.saveCachedMessages([]);
    notifyListeners();
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    final newMsg = MessageModel(
      id: const Uuid().v4(),
      pairCode: _storage.getPairCode(),
      senderId: senderId,
      receiverId: receiverId,
      content: content.trim(),
      replyToId: _replyToMessage?.id,
      replyToContent: _replyToMessage?.content,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    // Clear reply target
    _replyToMessage = null;

    // Append locally for immediate instant UI response
    _messages.add(newMsg);
    notifyListeners();

    await _storage.saveCachedMessages(_messages);

    // Send to Supabase Database if configured
    if (SupabaseService.isConfigured) {
      await _supabase.sendMessage(newMsg);
    }
  }

  // Set message reply target
  void setReplyToMessage(MessageModel? msg) {
    _replyToMessage = msg;
    notifyListeners();
  }

  void cancelReply() {
    _replyToMessage = null;
    notifyListeners();
  }

  // Toggle reaction emoji (❤️, 😂, 👍, 😮, 😢, 🔥)
  Future<void> toggleReaction(String messageId, String emoji) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final currentReaction = _messages[index].reaction;
      final newReaction = currentReaction == emoji ? null : emoji;

      _messages[index] = _messages[index].copyWith(reaction: newReaction);
      notifyListeners();

      await _storage.saveCachedMessages(_messages);

      if (SupabaseService.isConfigured) {
        await _supabase.updateReaction(messageId, newReaction);
      }
    }
  }

  // Star / Favorite a text message
  Future<void> toggleStar(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final isStarred = !_messages[index].isStarred;
      _messages[index] = _messages[index].copyWith(isStarred: isStarred);
      notifyListeners();
      await _storage.saveCachedMessages(_messages);
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        isDeleted: true,
        content: 'This message was deleted',
      );
      notifyListeners();
      await _storage.saveCachedMessages(_messages);

      if (SupabaseService.isConfigured) {
        await _supabase.deleteMessage(messageId);
      }
    }
  }

  // Mark all incoming messages as read
  void markAllAsRead(String currentUserId) {
    bool hasUpdates = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].receiverId == currentUserId &&
          _messages[i].status != MessageStatus.read) {
        _messages[i] = _messages[i].copyWith(status: MessageStatus.read);
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      _storage.saveCachedMessages(_messages);
      notifyListeners();
      if (SupabaseService.isConfigured) {
        _supabase.markAllMessagesAsRead(_storage.getPairCode(), currentUserId);
      }
    }
  }

  // Search filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSearch() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchQuery = '';
    }
    notifyListeners();
  }

  Function(MessageModel)? onNewIncomingMessage;

  // Realtime callbacks from Supabase
  void onReceiveRealtimeMessage(MessageModel msg) {
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx == -1) {
      _messages.add(msg);
      _storage.saveCachedMessages(_messages);
      notifyListeners();
      onNewIncomingMessage?.call(msg);
    } else {
      _messages[idx] = msg;
      _storage.saveCachedMessages(_messages);
      notifyListeners();
    }
  }

  void onUpdateRealtimeMessage(MessageModel msg) {
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx != -1) {
      _messages[idx] = msg;
      _storage.saveCachedMessages(_messages);
      notifyListeners();
    } else {
      _messages.add(msg);
      _storage.saveCachedMessages(_messages);
      notifyListeners();
    }
  }

  // Update typing indicator
  void setTyping(String userId, bool isTyping) {
    if (SupabaseService.isConfigured) {
      _supabase.updateTypingStatus(userId, isTyping);
    }
  }

  @override
  void dispose() {
    _supabase.unsubscribe();
    super.dispose();
  }
}
