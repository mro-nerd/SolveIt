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
  bool _advancingPose = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImitationProvider>().loadPoses();
    });
  }

  void _handleAnglesDetected(Map<String, double> angles) {
    final provider = context.read<ImitationProvider>();
    provider.evaluatePose(angles);

    // When matched, wait 1.5s then advance (prevent multiple triggers)
    if (provider.poseMatched && !_advancingPose) {
      _advancingPose = true;
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          context.read<ImitationProvider>().nextPose();
          _advancingPose = false;
        }
      });
    }
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

    return Column(
      children: [
        // Progress indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
          child: Text(
            'Pose ${provider.currentPoseIndex + 1} of ${provider.poses.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C63FF),
            ),
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

        // Divider with label
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
    final stars = List.generate(
      provider.score,
      (_) => const Text('⭐', style: TextStyle(fontSize: 36)),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎉 Well Done!',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 24),

            // Score
            Text(
              '${provider.score} out of ${provider.poses.length} poses matched',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 40),

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
                  'Play Again',
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
