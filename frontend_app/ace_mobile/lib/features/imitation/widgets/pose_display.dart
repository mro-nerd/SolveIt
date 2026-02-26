import 'package:flutter/material.dart';
import '../models/pose_reference.dart';

/// Child-friendly card that displays the target pose emoji, name,
/// instruction, and match status.
class PoseDisplay extends StatelessWidget {
  final PoseReference pose;
  final bool poseMatched;
  final String feedbackMessage;

  const PoseDisplay({
    super.key,
    required this.pose,
    required this.poseMatched,
    required this.feedbackMessage,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = poseMatched ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large emoji
          Text(
            pose.emoji,
            style: const TextStyle(fontSize: 100),
          ),
          const SizedBox(height: 12),

          // Pose name
          Text(
            pose.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),

          // Instruction
          Text(
            pose.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 20),

          // Animated match status icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: poseMatched
                ? const Icon(
                    Icons.check_circle,
                    key: ValueKey('matched'),
                    color: Colors.green,
                    size: 60,
                  )
                : const Icon(
                    Icons.sync,
                    key: ValueKey('trying'),
                    color: Colors.orange,
                    size: 60,
                  ),
          ),
          const SizedBox(height: 12),

          // Feedback message
          Text(
            feedbackMessage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
