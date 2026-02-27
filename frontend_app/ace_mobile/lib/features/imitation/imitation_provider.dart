import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/pose_reference.dart';

/// State management for the Imitation (Copy the Pose) feature.
class ImitationProvider extends ChangeNotifier {
  List<PoseReference> poses = [];
  int currentPoseIndex = 0;
  bool poseMatched = false;
  bool sessionComplete = false;
  int score = 0;
  String feedbackMessage = 'Get ready!';

  // Timer
  static const int poseTimeLimit = 10; // seconds per pose
  int secondsRemaining = poseTimeLimit;
  Timer? _countdownTimer;

  // Best match tracking per pose
  double _bestMatchPercent = 0;
  final List<double> poseResults = []; // best % for each pose

  PoseReference? get currentPose =>
      poses.isNotEmpty ? poses[currentPoseIndex] : null;

  void loadPoses() {
    poses = PoseReference.simplePoses;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    secondsRemaining = poseTimeLimit;
    _bestMatchPercent = 0;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      secondsRemaining--;
      if (secondsRemaining <= 0) {
        _timeUp();
      }
      notifyListeners();
    });
  }

  void _timeUp() {
    _countdownTimer?.cancel();
    if (!poseMatched) {
      // Record best match for this pose
      poseResults.add(_bestMatchPercent);
      if (_bestMatchPercent >= 70) {
        score++;
        feedbackMessage = 'Good effort! ${_bestMatchPercent.toInt()}% 👍';
      } else {
        feedbackMessage = 'Time\'s up! ${_bestMatchPercent.toInt()}% ⏰';
      }
      notifyListeners();
      // Auto-advance after a brief delay
      Timer(const Duration(milliseconds: 1500), () {
        nextPose();
      });
    }
  }

  void evaluatePose(Map<String, double> detectedAngles) {
    if (currentPose == null || poseMatched) return;

    final thresholds = currentPose!.angleThresholds;

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
      // Match % = 100 when diff=0, 0 when diff>=90
      final matchPct = ((1.0 - (diff / 90.0)) * 100).clamp(0, 100).toDouble();
      totalMatch += matchPct;
      jointCount++;
      if (diff > 40) allWithinTolerance = false;

      print('  ${entry.key}: detected=${detected.toStringAsFixed(1)} expected=${entry.value} diff=${diff.toStringAsFixed(1)} match=${matchPct.toStringAsFixed(0)}%');
    }

    final overallMatch = jointCount > 0 ? totalMatch / jointCount : 0.0;
    if (overallMatch > _bestMatchPercent) {
      _bestMatchPercent = overallMatch;
    }

    // Update feedback based on closeness
    if (allWithinTolerance) {
      poseMatched = true;
      score++;
      _bestMatchPercent = overallMatch;
      poseResults.add(_bestMatchPercent);
      feedbackMessage = 'Perfect! 🎉';
      _countdownTimer?.cancel();
      // Auto-advance after celebration
      Timer(const Duration(milliseconds: 1500), () {
        nextPose();
      });
    } else if (overallMatch >= 60) {
      feedbackMessage = 'Almost there! ${overallMatch.toInt()}% 🔥';
    } else if (overallMatch >= 30) {
      feedbackMessage = 'Keep going! ${overallMatch.toInt()}% 💪';
    } else {
      feedbackMessage = 'Try the pose! ${currentPose!.emoji}';
    }
    notifyListeners();
  }

  void nextPose() {
    if (currentPoseIndex < poses.length - 1) {
      currentPoseIndex++;
      poseMatched = false;
      feedbackMessage = 'Get ready!';
      _startTimer();
    } else {
      // Record last pose result if not already
      if (poseResults.length < poses.length && !poseMatched) {
        poseResults.add(_bestMatchPercent);
      }
      completeSession();
    }
    notifyListeners();
  }

  void completeSession() {
    _countdownTimer?.cancel();
    sessionComplete = true;
    notifyListeners();
  }

  void reset() {
    _countdownTimer?.cancel();
    poses = [];
    currentPoseIndex = 0;
    poseMatched = false;
    sessionComplete = false;
    score = 0;
    feedbackMessage = 'Get ready!';
    secondsRemaining = poseTimeLimit;
    _bestMatchPercent = 0;
    poseResults.clear();
    notifyListeners();
  }
}
