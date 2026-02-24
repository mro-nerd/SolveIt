import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_provider.dart';

/// A semi-transparent overlay that gives real-time gaze feedback.
/// Shows a pulsing ring (green = aligned, red = not aligned) and
/// a small score badge in the top-right corner.
class EyeTrackingOverlay extends StatelessWidget {
  const EyeTrackingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EyeContactProvider>();

    if (!provider.sessionActive) return const SizedBox.shrink();

    final isAligned = provider.gazeAligned;
    final ringColor = isAligned ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final scorePercent = (provider.score * 100).toStringAsFixed(0);

    return Stack(
      children: [
        // ── Gaze feedback ring ───────────────────────────────────────────
        Center(
          child: AnimatedContainer(
            duration: 300.ms,
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 4),
              color: ringColor.withValues(alpha: 0.08),
            ),
            child: Icon(
              isAligned ? Icons.visibility : Icons.visibility_off_outlined,
              color: ringColor,
              size: 40,
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.06, 1.06),
                duration: 600.ms,
                curve: Curves.easeInOut,
              ),
        ),

        // ── Score badge ──────────────────────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: AnimatedContainer(
            duration: 250.ms,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ringColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ringColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.remove_red_eye, color: ringColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$scorePercent%',
                  style: TextStyle(
                    color: ringColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Frame counter ────────────────────────────────────────────────
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${provider.alignedFrameCount} / ${provider.totalFrameCount} frames aligned',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
