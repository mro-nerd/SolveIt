import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/pose_reference.dart';

/// State management for the Imitation (Copy the Pose) feature.
class ImitationProvider extends ChangeNotifier {
  List<PoseReference> poses = [];
  int currentPoseIndex = 0;
  bool sessionComplete = false;
  int score = 0;

  // Timer
  static const int poseTimeLimit = 10; // seconds per pose
  int secondsRemaining = poseTimeLimit;
  Timer? _countdownTimer;

  // Ready countdown (3-2-1-Go)
  int readyCountdown = 3;
  bool get isReady => readyCountdown <= 0;

  // Live match tracking
  double currentMatchPercent = 0;
  double bestMatchPercent = 0;
  int matchedFrames = 0; // frames where all joints were within tolerance
  int totalFrames = 0;
  String feedbackMessage = 'Get ready!';

  // Per-pose results
  final List<PoseResult> poseResults = [];

  PoseReference? get currentPose =>
      poses.isNotEmpty && currentPoseIndex < poses.length
          ? poses[currentPoseIndex]
          : null;

  void loadPoses() {
    poses = PoseReference.simplePoses;
    _startReadyCountdown();
    notifyListeners();
  }

  void _startReadyCountdown() {
    readyCountdown = 3;
    feedbackMessage = '3';
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      readyCountdown--;
      if (readyCountdown > 0) {
        feedbackMessage = '$readyCountdown';
      } else if (readyCountdown == 0) {
        feedbackMessage = 'Go! ${currentPose?.emoji ?? ""}';
      } else {
        timer.cancel();
        _startPoseTimer();
      }
      notifyListeners();
    });
  }

  void _startPoseTimer() {
    secondsRemaining = poseTimeLimit;
    currentMatchPercent = 0;
    bestMatchPercent = 0;
    matchedFrames = 0;
    totalFrames = 0;
    feedbackMessage = 'Try the pose! ${currentPose?.emoji ?? ""}';

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      secondsRemaining--;
      if (secondsRemaining <= 0) {
        _poseTimeUp();
      }
      notifyListeners();
    });
  }

  void _poseTimeUp() {
    _countdownTimer?.cancel();

    // Calculate final score for this pose
    final matchRatio =
        totalFrames > 0 ? (matchedFrames / totalFrames * 100) : 0.0;
    final finalScore = (bestMatchPercent * 0.5 + matchRatio * 0.5).clamp(0, 100);
    final matched = finalScore >= 50;

    poseResults.add(PoseResult(
      pose: currentPose!,
      bestMatchPercent: bestMatchPercent,
      matchedFrames: matchedFrames,
      totalFrames: totalFrames,
      finalScore: finalScore.toDouble(),
    ));

    if (matched) score++;

    if (finalScore >= 70) {
      feedbackMessage = 'Great! ${finalScore.toInt()}% 🎉';
    } else if (finalScore >= 40) {
      feedbackMessage = 'Nice try! ${finalScore.toInt()}% 👍';
    } else {
      feedbackMessage = 'Keep practising! ${finalScore.toInt()}% 💪';
    }
    notifyListeners();

    // Auto-advance after brief pause
    Timer(const Duration(milliseconds: 2000), () {
      _advanceToNextPose();
    });
  }

  void _advanceToNextPose() {
    if (currentPoseIndex < poses.length - 1) {
      currentPoseIndex++;
      _startReadyCountdown();
    } else {
      _completeSession();
    }
    notifyListeners();
  }

  void evaluatePose(Map<String, double> detectedAngles) {
    if (currentPose == null || !isReady || secondsRemaining <= 0) return;

    final thresholds = currentPose!.angleThresholds;
    totalFrames++;

    // Calculate match percentage for each joint
    double totalMatch = 0;
    int jointCount = 0;
    bool allWithinTolerance = true;

    for (final entry in thresholds.entries) {
      final detected = detectedAngles[entry.key];
      if (detected == null) {
        allWithinTolerance = false;
        continue;
      }
      final diff = (detected - entry.value).abs();
      // Match % = 100 when diff=0, 0 when diff>=80
      final matchPct = ((1.0 - (diff / 80.0)) * 100).clamp(0, 100).toDouble();
      totalMatch += matchPct;
      jointCount++;
      if (diff > 35) allWithinTolerance = false;

      print(
          '  ${entry.key}: detected=${detected.toStringAsFixed(1)} expected=${entry.value} diff=${diff.toStringAsFixed(1)} match=${matchPct.toStringAsFixed(0)}%');
    }

    final overallMatch = jointCount > 0 ? totalMatch / jointCount : 0.0;
    currentMatchPercent = overallMatch;
    if (overallMatch > bestMatchPercent) bestMatchPercent = overallMatch;
    if (allWithinTolerance) matchedFrames++;

    // Live feedback
    if (allWithinTolerance) {
      feedbackMessage = 'Perfect! Hold it! 🎯';
    } else if (overallMatch >= 60) {
      feedbackMessage = 'Almost there! 🔥';
    } else if (overallMatch >= 30) {
      feedbackMessage = 'Keep going! 💪';
    } else {
      feedbackMessage = 'Try the pose! ${currentPose!.emoji}';
    }
    notifyListeners();
  }

  void _completeSession() {
    _countdownTimer?.cancel();
    sessionComplete = true;
    notifyListeners();
  }

  void reset() {
    _countdownTimer?.cancel();
    poses = [];
    currentPoseIndex = 0;
    sessionComplete = false;
    score = 0;
    feedbackMessage = 'Get ready!';
    secondsRemaining = poseTimeLimit;
    readyCountdown = 3;
    currentMatchPercent = 0;
    bestMatchPercent = 0;
    matchedFrames = 0;
    totalFrames = 0;
    poseResults.clear();
    notifyListeners();
  }
}

/// Result data for a single pose attempt.
class PoseResult {
  final PoseReference pose;
  final double bestMatchPercent;
  final int matchedFrames;
  final int totalFrames;
  final double finalScore;

  const PoseResult({
    required this.pose,
    required this.bestMatchPercent,
    required this.matchedFrames,
    required this.totalFrames,
    required this.finalScore,
  });
}
