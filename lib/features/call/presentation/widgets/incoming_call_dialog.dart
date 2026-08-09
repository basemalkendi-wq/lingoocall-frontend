import 'package:flutter/material.dart';
import 'package:lingoocall/core/constants/app_colors.dart';

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final String callerAvatar;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    required this.callerAvatar,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1E1E2C),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_rounded,
              color: AppColors.accent,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'مكالمة فيديو واردة...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              child: Text(
                callerName.isNotEmpty ? callerName.substring(0, 1) : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // زر الرفض
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'rejectCallBtn',
                      backgroundColor: AppColors.error,
                      onPressed: onReject,
                      child: const Icon(Icons.call_end_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text('رفض', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                // زر القبول
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'acceptCallBtn',
                      backgroundColor: AppColors.success,
                      onPressed: onAccept,
                      child: const Icon(Icons.call_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text('قبول', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}