import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import '../../../theme/app_theme.dart';
import 'reply_preview_bar.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSendText;
  final Function(bool) onTypingChanged;
  final MessageModel? replyToMessage;
  final VoidCallback onCancelReply;

  const ChatInputBar({
    Key? key,
    required this.onSendText,
    required this.onTypingChanged,
    this.replyToMessage,
    required this.onCancelReply,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      widget.onTypingChanged(_isTyping);
    }
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    widget.onSendText(text);
    _textController.clear();
    setState(() {
      _isTyping = false;
    });
    widget.onTypingChanged(false);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quoted Reply Preview
        if (widget.replyToMessage != null)
          ReplyPreviewBar(
            message: widget.replyToMessage!,
            onCancel: widget.onCancelReply,
          ),

        Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 8, top: 4),
          child: Row(
            children: [
              // Text Field Container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        onPressed: () {
                          // Quick emoji tip
                          _textController.text += '😊';
                          _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                          ),
                        ),
                      ),
                      if (_isTyping)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () => _textController.clear(),
                        ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Circular WhatsApp Send Floating Button
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppTheme.whatsappAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
