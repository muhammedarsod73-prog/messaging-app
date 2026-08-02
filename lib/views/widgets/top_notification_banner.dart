import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TopNotificationBanner {
  static OverlayEntry? _overlayEntry;
  static Timer? _dismissTimer;

  static void show({
    required BuildContext context,
    required String senderName,
    required String messageContent,
    required VoidCallback onTap,
  }) {
    dismiss();

    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return _TopNotificationWidget(
          senderName: senderName,
          messageContent: messageContent,
          isDark: isDark,
          onTap: () {
            dismiss();
            onTap();
          },
          onDismiss: () => dismiss(),
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String senderName;
  final String messageContent;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    Key? key,
    required this.senderName,
    required this.messageContent,
    required this.isDark,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF202C33) : Colors.white;
    final textColor = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onTap,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    widget.onDismiss();
                  }
                },
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.whatsappAccent.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Partner Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.whatsappAccent,
                        child: Text(
                          widget.senderName.isNotEmpty
                              ? widget.senderName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Notification Content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.senderName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.whatsappAccent,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'Just now',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.messageContent,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Dismiss Button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: widget.onDismiss,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
