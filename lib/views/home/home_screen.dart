import 'dart:async';
import 'dart:convert';
import 'package:duo_chat/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../call/incoming_call_dialog.dart';
import '../call/video_call_screen.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _sidebarSearchQuery = '';
  bool _isCallDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Request OS System Notification Permission
      NotificationService.requestPermission();

      // 1. Subscribe to Realtime WebSocket Call Signals
      SupabaseService().subscribeToCallSignals(
        pairCode: auth.pairCode,
        onCallSignal: (payload) {
          if (!mounted) return;
          final type = payload['signal_type'] ?? payload['type'];
          final senderId = payload['sender_id'];
          final callerName = payload['caller_name'] ?? auth.partnerUser.name;
          final isVideo = payload['is_video'] ?? true;

          if (senderId != auth.currentUserId && type == 'incoming_call') {
            _handleIncomingCall(callerName, isVideo);
          }
        },
      );

      // 2. Subscribe to Incoming Chat Stream (Handles Background Database Signals)
      chat.onNewIncomingMessage = (msg) {
        if (msg.receiverId == auth.currentUserId && mounted) {
          // Check if message is a Realtime Call Signal
          if (msg.content.startsWith('[CALL_SIGNAL]:')) {
            try {
              final jsonString = msg.content.substring('[CALL_SIGNAL]:'.length);
              Map<String, dynamic> data = {};
              if (jsonString.startsWith('{')) {
                data = jsonDecode(jsonString);
              } else {
                final parts = msg.content.split(':');
                data = {
                  'type': parts.length > 1 ? parts[1] : '',
                  'is_video': parts.length > 2 ? (parts[2] == 'video') : true,
                  'caller_name':
                      parts.length > 3 ? parts[3] : auth.partnerUser.name,
                };
              }

              final type = data['type'];
              final isVideo = data['is_video'] ?? true;
              final callerName = data['caller_name'] ?? auth.partnerUser.name;

              if (type == 'incoming_call') {
                _handleIncomingCall(callerName, isVideo);
              }
            } catch (e) {
              debugPrint("Call signal JSON decode error: $e");
            }
            return;
          }

          // System-Level OS Notification for regular text messages
          NotificationService.showSystemNotification(
            title: auth.partnerUser.name,
            body: msg.content,
          );
        }
      };
    });
  }

  /// Unified Helper to trigger IncomingCallDialog with stacking guard
  void _handleIncomingCall(String callerName, bool isVideo) {
    if (_isCallDialogShowing) return;
    _isCallDialogShowing = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        callerName: callerName,
        isVideoCall: isVideo,
        onAccept: () {
          _isCallDialogShowing = false;
          Navigator.pop(ctx); // Close Dialog

          // Send Acceptance Signal
          SupabaseService().sendCallSignal(
            pairCode: auth.pairCode,
            senderId: auth.currentUserId,
            receiverId: auth.partnerUser.id,
            callerName: auth.currentUser.name,
            type: 'call_accepted',
            isVideo: isVideo,
          );

          // Route to Video Call Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (callCtx) => VideoCallScreen(
                partnerName: callerName,
                channelId: auth.pairCode,
                isVideoCall: isVideo,
                isCaller: false,
                onEndCall: () {
                  SupabaseService().sendCallSignal(
                    pairCode: auth.pairCode,
                    senderId: auth.currentUserId,
                    receiverId: auth.partnerUser.id,
                    callerName: auth.currentUser.name,
                    type: 'call_ended',
                    isVideo: isVideo,
                  );
                },
              ),
            ),
          );
        },
        onDecline: () {
          _isCallDialogShowing = false;
          Navigator.pop(ctx); // Close Dialog

          // Send Decline Signal
          SupabaseService().sendCallSignal(
            pairCode: auth.pairCode,
            senderId: auth.currentUserId,
            receiverId: auth.partnerUser.id,
            callerName: auth.currentUser.name,
            type: 'call_declined',
            isVideo: isVideo,
          );
        },
      ),
    ).then((_) {
      _isCallDialogShowing = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.reloadMessages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (2-COLUMN SPLIT VIEW)
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? const Color(0xFF111B21) : const Color(0xFFF0F2F5);

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Panel (360px)
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF222D34) : Colors.black12,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(context),
                _buildSidebarSearch(context),
                Expanded(
                  child: _buildChatListContent(context, isDesktop: true),
                ),
              ],
            ),
          ),

          // Right Chat Panel (Fills remaining width)
          const Expanded(
            child: ChatScreen(isDesktop: true),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT (SINGLE COLUMN VIEW)
  // ==========================================
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DuoChat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.whatsappGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '2-Person',
                style: TextStyle(
                  color: AppTheme.whatsappGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildChatListContent(context, isDesktop: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const ChatScreen()),
          );
        },
        backgroundColor: AppTheme.whatsappAccent,
        child: const Icon(Icons.message_rounded, color: Colors.white),
      ),
    );
  }

  // Sidebar Header for Desktop
  Widget _buildSidebarHeader(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isDark ? AppTheme.darkCardColor : const Color(0xFFF0F2F5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.whatsappAccent,
            child: Text(
              auth.currentUser.name.isNotEmpty
                  ? auth.currentUser.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.currentUser.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Key: ${auth.pairCode}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Instant Role Switcher Badge
          InkWell(
            onTap: () {
              auth.switchRole();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched view to ${auth.currentUser.name}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppTheme.whatsappAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.whatsappAccent, width: 1),
              ),
              child: Text(
                auth.isUserA ? 'User A' : 'User B',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Settings
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Sidebar Search for Desktop
  Widget _buildSidebarSearch(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (q) {
                  setState(() {
                    _sidebarSearchQuery = q;
                  });
                },
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search chat history...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Common Chat List Body
  Widget _buildChatListContent(BuildContext context,
      {required bool isDesktop}) {
    final auth = Provider.of<AuthProvider>(context);
    final chat = Provider.of<ChatProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partner = auth.partnerUser;
    final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;

    final formattedTime = lastMsg != null
        ? DateFormat('h:mm a').format(lastMsg.createdAt.toLocal())
        : '';

    final matchesSearch = _sidebarSearchQuery.isEmpty ||
        partner.name
            .toLowerCase()
            .contains(_sidebarSearchQuery.toLowerCase()) ||
        (lastMsg != null &&
            lastMsg.content
                .toLowerCase()
                .contains(_sidebarSearchQuery.toLowerCase()));

    if (!matchesSearch) {
      return const Center(
        child: Text('No search matches', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      children: [
        // Banner Info Card for Pair Connection
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.whatsappAccent.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Colors.redAccent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paired Room: ${auth.pairCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Texting with ${partner.name} • ${auth.currentUser.name}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'CHATS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.whatsappAccent,
            ),
          ),
        ),

        // The 2-Person Chat ListTile
        Container(
          color: isDesktop
              ? (isDark ? const Color(0xFF2A3942) : const Color(0xFFE9EDEF))
              : Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isDesktop) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const ChatScreen()),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Avatar with Online indicator dot
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.whatsappAccent,
                        child: Text(
                          partner.name.isNotEmpty
                              ? partner.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (partner.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.whatsappGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBackground
                                    : AppTheme.lightBackground,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Chat Info (Name, Last Message, Typing status)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              partner.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (formattedTime.isNotEmpty)
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.whatsappAccent,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (lastMsg != null &&
                                lastMsg.senderId == auth.currentUserId) ...[
                              Icon(
                                lastMsg.status == MessageStatus.read
                                    ? Icons.done_all
                                    : Icons.check,
                                size: 15,
                                color: lastMsg.status == MessageStatus.read
                                    ? AppTheme.tickBlue
                                    : AppTheme.tickGrey,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                partner.isTyping
                                    ? 'typing...'
                                    : (lastMsg?.content ??
                                        'Tap to start texting...'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: partner.isTyping
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: partner.isTyping
                                      ? AppTheme.whatsappAccent
                                      : (isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Divider(indent: 72),
      ],
    );
  }
}
