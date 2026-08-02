import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import '../../../theme/app_theme.dart';

class ReplyPreviewBar extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    Key? key,
    required this.message,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5),
        border: const Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.whatsappAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Replying to partner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whatsappAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
