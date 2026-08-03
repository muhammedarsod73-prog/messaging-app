import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../call/incoming_call_dialog.dart';
import '../call/video_call_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/search_bar_widget.dart';

class ChatScreen extends StatefulWidget {
  final bool isDesktop;
  const ChatScreen({Key? key, this.isDesktop = false}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.markAllAsRead(auth.currentUserId);

      // Subscribe to Realtime Call Signals
      SupabaseService().subscribeToCallSignals(
        pairCode: auth.pairCode,
        onCallSignal: (payload) {
          if (!mounted) return;
          final type = payload['type'];
          final senderId = payload['sender_id'];
          final callerName = payload['caller_name'] ?? 'Partner';
          final isVideo = payload['is_video'] ?? true;

          // Incoming Call Received from Partner
          if (senderId != auth.currentUserId && type == 'incoming_call') {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => IncomingCallDialog(
                callerName: callerName,
                isVideoCall: isVideo,
                onAccept: () {
                  Navigator.pop(ctx);
                  SupabaseService().sendCallSignal(
                    pairCode: auth.pairCode,
                    senderId: auth.currentUserId,
                    receiverId: auth.partnerUser.id,
                    callerName: auth.currentUser.name,
                    type: 'call_accepted',
                    isVideo: isVideo,
                  );
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
                  Navigator.pop(ctx);
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
            );
          }
        },
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.reloadMessages().then((_) {
        if (mounted) {
          chat.markAllAsRead(auth.currentUserId);
          _scrollToBottom();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _confirmClearChat(BuildContext context, ChatProvider chat) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear Chat for Both Sides?'),
          content: const Text(
            'This will permanently delete all messages in this 2-person room for both you and your partner. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                chat.clearAllMessagesForBoth();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All messages deleted for both sides'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
              label: const Text('Clear for Both'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chat = Provider.of<ChatProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      chat.markAllAsRead(auth.currentUserId);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partner = auth.partnerUser;
    final wallpaperBg = AppTheme.getWallpaperBackgroundColor(theme.wallpaperStyle, isDark);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isDesktop,
        titleSpacing: widget.isDesktop ? 16 : 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppTheme.whatsappAccent,
              child: Text(
                partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    partner.isTyping
                        ? 'typing...'
                        : (partner.isOnline ? 'online' : 'last seen recently'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: partner.isTyping ? FontWeight.bold : FontWeight.normal,
                      color: partner.isTyping
                          ? AppTheme.whatsappAccent
                          : (isDark ? AppTheme.darkTextSecondary : Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Video Call Button
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            tooltip: 'Video Call',
            onPressed: () => _startCall(context, isVideoCall: true),
          ),

          // Voice Call Button
          IconButton(
            icon: const Icon(Icons.call_rounded),
            tooltip: 'Voice Call',
            onPressed: () => _startCall(context, isVideoCall: false),
          ),

          // Search Button
          IconButton(
            icon: Icon(chat.isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => chat.toggleSearch(),
          ),

          // Instant Dual-Role Switcher Badge (for easy 1-device 2-person testing)
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppTheme.whatsappAccent.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.whatsappAccent, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    auth.isUserA ? 'User A' : 'User B',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Options Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearChat(context, chat);
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Clear Chat for Both', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: wallpaperBg,
        child: Column(
          children: [
            // Search Input if active
            if (chat.isSearching)
              SearchBarWidget(
                query: chat.searchQuery,
                onChanged: (q) => chat.setSearchQuery(q),
                onClose: () => chat.toggleSearch(),
              ),

            // Messages List View
            Expanded(
              child: chat.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No text messages yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Start your private 2-person conversation below!',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chat.messages[index];
                        final isMe = msg.senderId == auth.currentUserId;

                        return MessageBubble(
                          message: msg,
                          isMe: isMe,
                          onReply: (m) => chat.setReplyToMessage(m),
                          onReaction: (m, emoji) => chat.toggleReaction(m.id, emoji),
                          onStar: (m) => chat.toggleStar(m.id),
                          onDelete: (m) => chat.deleteMessage(m.id),
                        );
                      },
                    ),
            ),

            // Bottom Input Bar
            ChatInputBar(
              replyToMessage: chat.replyToMessage,
              onCancelReply: () => chat.cancelReply(),
              onTypingChanged: (isTyping) {
                chat.setTyping(auth.currentUserId, isTyping);
              },
              onSendText: (text) async {
                await chat.sendTextMessage(
                  senderId: auth.currentUserId,
                  receiverId: auth.partnerUser.id,
                  content: text,
                );
                _scrollToBottom();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startCall(BuildContext context, {required bool isVideoCall}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1. Send Realtime Call Signal over Postgres WebSockets to Partner
    SupabaseService().sendCallSignal(
      pairCode: auth.pairCode,
      senderId: auth.currentUserId,
      receiverId: auth.partnerUser.id,
      callerName: auth.currentUser.name,
      type: 'incoming_call',
      isVideo: isVideoCall,
    );

    // 2. Push Video Call View for Caller
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => VideoCallScreen(
          partnerName: auth.partnerUser.name,
          channelId: auth.pairCode,
          isVideoCall: isVideoCall,
          isCaller: true,
          onEndCall: () {
            SupabaseService().sendCallSignal(
              pairCode: auth.pairCode,
              senderId: auth.currentUserId,
              receiverId: auth.partnerUser.id,
              callerName: auth.currentUser.name,
              type: 'call_ended',
              isVideo: isVideoCall,
            );
          },
        ),
      ),
    );
  }
}
