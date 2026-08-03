import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final bool isVideoCall;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallDialog({
    Key? key,
    required this.callerName,
    required this.isVideoCall,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111B21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Caller Avatar Circle
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.whatsappAccent,
              child: Text(
                callerName.isNotEmpty ? callerName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Caller Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Call Type Subtitle (Silent Ringing - Zero Audio)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                  color: AppTheme.whatsappAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isVideoCall ? 'Incoming Video Call...' : 'Incoming Voice Call...',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Action Buttons: Decline (Red) and Accept (Green)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Decline Button
                InkWell(
                  onTap: onDecline,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Accept Button
                InkWell(
                  onTap: onAccept,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
