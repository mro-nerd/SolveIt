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

    // Show 3-2-1 countdown overlay
    if (!provider.isReady) {
      return _buildReadyCountdown(provider);
    }

    final timerFraction =
        provider.secondsRemaining / ImitationProvider.poseTimeLimit;
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
            children: [
              // Pose counter
              Text(
                'Pose ${provider.currentPoseIndex + 1}/${provider.poses.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const Spacer(),
              // Best match badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Best: ${provider.bestMatchPercent.toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Circular timer
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: timerFraction,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(timerColor),
                    ),
                    Text(
                      '${provider.secondsRemaining}',
                      style: TextStyle(
                        fontSize: 16,
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

        // Live match progress bar
        Container(
          width: double.infinity,
          height: 6,
          color: Colors.grey.shade200,
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width *
                (provider.currentMatchPercent / 100).clamp(0.0, 1.0),
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: provider.currentMatchPercent >= 70
                    ? [Colors.green, Colors.greenAccent]
                    : provider.currentMatchPercent >= 40
                        ? [Colors.orange, Colors.amber]
                        : [Colors.red.shade300, Colors.red],
              ),
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
                poseMatched: provider.currentMatchPercent >= 70,
                feedbackMessage: provider.feedbackMessage,
              ),
            ),
          ),
        ),

        // Divider with match count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFCBD5E0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${provider.matchedFrames} hits 🎯',
                  style: TextStyle(
                    fontSize: 14,
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
              CameraPoseDetector(
                onAnglesDetected: _handleAnglesDetected,
                onError: _handleError,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  provider.feedbackMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: provider.currentMatchPercent >= 70
                        ? Colors.green
                        : const Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 3-2-1 Countdown ────────────────────────────────────────────────

  Widget _buildReadyCountdown(ImitationProvider provider) {
    final pose = provider.currentPose;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pose?.emoji ?? '',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            pose?.name ?? '',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pose?.instruction ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 40),
          // Big countdown number
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              provider.readyCountdown > 0
                  ? '${provider.readyCountdown}'
                  : 'Go!',
              key: ValueKey(provider.readyCountdown),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: provider.readyCountdown > 0
                    ? const Color(0xFF6C63FF)
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Results ──────────────────────────────────────────────────────────

  Widget _buildResultsScreen(ImitationProvider provider) {
    final totalPoses = provider.poses.length;
    final overallPercent = provider.poseResults.isNotEmpty
        ? (provider.poseResults
                    .map((r) => r.finalScore)
                    .reduce((a, b) => a + b) /
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
      (_) => const Text('⭐', style: TextStyle(fontSize: 40)),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎉 Great Job!',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),

            // Overall score circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: overallPercent >= 60
                      ? [Colors.green.shade400, Colors.green.shade700]
                      : overallPercent >= 30
                          ? [Colors.orange.shade400, Colors.orange.shade700]
                          : [Colors.red.shade300, Colors.red.shade600],
                ),
              ),
              child: Center(
                child: Text(
                  '$overallPercent%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.score} of $totalPoses poses matched',
              style: const TextStyle(fontSize: 16, color: Color(0xFF718096)),
            ),
            const SizedBox(height: 12),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: stars.isEmpty
                  ? [
                      const Text('Keep practising! 💪',
                          style: TextStyle(fontSize: 18))
                    ]
                  : stars,
            ),
            const SizedBox(height: 20),

            // Per-pose breakdown cards
            ...provider.poseResults.map((result) {
              final matched = result.finalScore >= 50;
              final scoreColor = result.finalScore >= 70
                  ? Colors.green
                  : result.finalScore >= 40
                      ? Colors.orange
                      : Colors.red;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scoreColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(result.pose.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.pose.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${result.matchedFrames} matching frames',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score
                    Text(
                      '${result.finalScore.toInt()}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      matched ? Icons.check_circle : Icons.cancel_outlined,
                      color: scoreColor,
                      size: 22,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 28),

            // Play Again
            SizedBox(
              width: double.infinity,
              height: 52,
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
            const SizedBox(height: 12),

            // Go Back
            SizedBox(
              width: double.infinity,
              height: 52,
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
