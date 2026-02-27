import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'imitation_provider.dart';
import 'widgets/camera_pose_detector.dart';
import 'widgets/pose_display.dart';

/// Main screen for the Imitation (Copy the Pose) feature.
class ImitationScreen extends StatefulWidget {
  const ImitationScreen({super.key});

  @override
  State<ImitationScreen> createState() => _ImitationScreenState();
}

class _ImitationScreenState extends State<ImitationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImitationProvider>().loadPoses();
    });
  }

  void _handleAnglesDetected(Map<String, double> angles) {
    if (!mounted) return;
    context.read<ImitationProvider>().evaluatePose(angles);
  }

  void _handleError(String message) {
    debugPrint('CameraPoseDetector error: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImitationProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0F8FF),
          appBar: AppBar(
            title: const Text(
              'Copy the Pose',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                provider.reset();
                Navigator.pop(context);
              },
            ),
          ),
          body: provider.sessionComplete
              ? _buildResultsScreen(provider)
              : _buildGameScreen(provider),
        );
      },
    );
  }

  // ─── Active game ──────────────────────────────────────────────────────

  Widget _buildGameScreen(ImitationProvider provider) {
    final pose = provider.currentPose;
    if (pose == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final timerColor = provider.secondsRemaining <= 3
        ? Colors.red
        : const Color(0xFF6C63FF);

    return Column(
      children: [
        // Progress + Timer bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pose ${provider.currentPoseIndex + 1} of ${provider.poses.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C63FF),
                ),
              ),
              // Countdown timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: timerColor, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, size: 18, color: timerColor),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.secondsRemaining}s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Pose display card
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              child: PoseDisplay(
                pose: pose,
                poseMatched: provider.poseMatched,
                feedbackMessage: provider.feedbackMessage,
              ),
            ),
          ),
        ),

        // Divider with feedback
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFCBD5E0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Your turn!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFCBD5E0))),
            ],
          ),
        ),

        // Camera detector + feedback overlay
        Expanded(
          flex: 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Invisible camera detector
              CameraPoseDetector(
                onAnglesDetected: _handleAnglesDetected,
                onError: _handleError,
              ),

              // Centered feedback text
              Text(
                provider.feedbackMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: provider.poseMatched
                      ? Colors.green
                      : const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Results ──────────────────────────────────────────────────────────

  Widget _buildResultsScreen(ImitationProvider provider) {
    final totalPoses = provider.poses.length;
    final overallPercent = provider.poseResults.isNotEmpty
        ? (provider.poseResults.reduce((a, b) => a + b) /
                provider.poseResults.length)
            .toInt()
        : 0;

    // Stars based on overall percentage
    final starCount = overallPercent >= 80
        ? 3
        : overallPercent >= 50
            ? 2
            : overallPercent >= 25
                ? 1
                : 0;
    final stars = List.generate(
      starCount,
      (_) => const Text('⭐', style: TextStyle(fontSize: 36)),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎉 Great Job!',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),

            // Overall score
            Text(
              '${provider.score} of $totalPoses poses matched!',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Overall: $overallPercent%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: stars.isEmpty
                  ? [
                      const Text(
                        'Keep practising! 💪',
                        style: TextStyle(fontSize: 20),
                      )
                    ]
                  : stars,
            ),
            const SizedBox(height: 24),

            // Per-pose breakdown
            ...List.generate(
              provider.poses.length,
              (i) {
                final pose = provider.poses[i];
                final result = i < provider.poseResults.length
                    ? provider.poseResults[i].toInt()
                    : 0;
                final matched = result >= 70;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: matched
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: matched ? Colors.green : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(pose.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pose.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$result%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: matched ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        matched ? Icons.check_circle : Icons.timer_outlined,
                        color: matched ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Play Again
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  provider.reset();
                  provider.loadPoses();
                },
                child: const Text(
                  'Play Again 🔄',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Go Back
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  provider.reset();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
