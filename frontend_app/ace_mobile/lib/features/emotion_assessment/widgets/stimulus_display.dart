import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/stimulus.dart';

/// Full-screen animated display for a stimulus.
///
/// Shows the cartoon image with engaging animations, title, description,
/// and a colored progress bar. Falls back to emoji if no image is available.
class StimulusDisplay extends StatelessWidget {
  final Stimulus stimulus;
  final int secondsLeft;
  final int totalSeconds;

  const StimulusDisplay({
    super.key,
    required this.stimulus,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Visual stimulus (cartoon image or emoji fallback) ──
          _buildVisual(),

          const SizedBox(height: 20),

          // ── Title ──
          Text(
                stimulus.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333355),
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),

          const SizedBox(height: 8),

          // ── Description ──
          Text(
            stimulus.description,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF555577).withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 28),

          // ── Round progress bar ──
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalSeconds > 0
                    ? (secondsLeft / totalSeconds).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 6,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _emotionColor(stimulus.expectedEmotion),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisual() {
    if (stimulus.imagePath != null) {
      // Show cartoon image with engaging animations
      return ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              stimulus.imagePath!,
              width: 260,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emojiVisual(),
            ),
          )
          .animate()
          .fadeIn(duration: 300.ms)
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.elasticOut,
          )
          .then()
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.04, 1.04),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          );
    }
    return _emojiVisual();
  }

  /// Fallback emoji visual.
  Widget _emojiVisual() {
    return Text(
          stimulus.emoji,
          style: const TextStyle(fontSize: 80),
          textAlign: TextAlign.center,
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 600.ms,
          curve: Curves.easeInOut,
        );
  }

  Color _emotionColor(ExpectedEmotion emotion) {
    switch (emotion) {
      case ExpectedEmotion.happy:
        return const Color(0xFFFFB74D); // warm orange
      case ExpectedEmotion.surprise:
        return const Color(0xFF7E57C2); // purple
      case ExpectedEmotion.sad:
        return const Color(0xFF42A5F5); // blue
    }
  }
}
