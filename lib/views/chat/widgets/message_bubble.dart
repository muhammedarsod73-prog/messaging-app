import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/message_model.dart';
import '../../../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(MessageModel) onReply;
  final Function(MessageModel, String) onReaction;
  final Function(MessageModel) onDelete;
  final Function(MessageModel) onStar;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onReaction,
    required this.onDelete,
    required this.onStar,
  }) : super(key: key);

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reaction Bar Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '😂', '👍', '😮', '😢', '🔥'].map((emoji) {
                      final isSelected = message.reaction == emoji;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          onReaction(message, emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.whatsappAccent.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 26)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: AppTheme.whatsappAccent),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onReply(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Colors.grey),
                  title: const Text('Copy Text'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied to clipboard')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    message.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(message.isStarred ? 'Unstar Message' : 'Star Message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onStar(message);
                  },
                ),
                if (isMe && !message.isDeleted)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete(message);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTicks(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    switch (message.status) {
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 15, color: AppTheme.tickGrey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 15, color: AppTheme.tickGrey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 15, color: AppTheme.tickBlue);
    }
  }

  double _calculateFontSize(String text) {
    if (text.trim().isEmpty) return 15.0;
    final clean = text.trim().replaceAll(RegExp(r'\s+'), '');
    final chars = clean.characters;

    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
    );

    if (emojiRegex.hasMatch(clean)) {
      if (chars.length == 1) return 46.0; // Giant single emoji
      if (chars.length == 2) return 36.0; // Large double emoji
      if (chars.length == 3) return 28.0; // Medium triple emoji
    }
    return 15.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormatted = DateFormat('h:mm a').format(message.createdAt.toLocal());

    final bubbleBg = isMe
        ? (isDark ? AppTheme.darkSentBubble : AppTheme.lightSentBubble)
        : (isDark ? AppTheme.darkReceivedBubble : AppTheme.lightReceivedBubble);

    final fontSize = _calculateFontSize(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            child: GestureDetector(
              onLongPress: () => _showContextMenu(context),
              onDoubleTap: () => onReaction(message, '❤️'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bubbleBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quoted Reply Preview inside bubble
                        if (message.replyToContent != null && message.replyToContent!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border(
                                left: BorderSide(
                                  color: isMe ? AppTheme.whatsappAccent : AppTheme.tealPrimary,
                                  width: 3.5,
                                ),
                              ),
                            ),
                            child: Text(
                              message.replyToContent!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),

                        // Message Text Content
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                            color: message.isDeleted
                                ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                          ),
                        ),

                        const SizedBox(height: 3),

                        // Time & Ticks & Star Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.isStarred)
                              const Padding(
                                padding: EdgeInsets.only(right: 3),
                                child: Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                              ),
                            Text(
                              timeFormatted,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            if (isMe) const SizedBox(width: 4),
                            _buildStatusTicks(context),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating Reaction Emoji Badge
                  if (message.reaction != null && message.reaction!.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: isMe ? null : -4,
                      left: isMe ? -4 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF26343D) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 3,
                            )
                          ],
                        ),
                        child: Text(
                          message.reaction!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
