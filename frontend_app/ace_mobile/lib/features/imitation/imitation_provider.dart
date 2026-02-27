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
  int holdDurationSeconds = 2;
  int _holdCounter = 0;

  PoseReference? get currentPose =>
      poses.isNotEmpty ? poses[currentPoseIndex] : null;

  void loadPoses() {
    poses = PoseReference.simplePoses;
    notifyListeners();
  }

  void evaluatePose(Map<String, double> detectedAngles) {
    if (currentPose == null) return;

    final thresholds = currentPose!.angleThresholds;
    final allMatched = thresholds.entries.every((entry) {
      final detected = detectedAngles[entry.key];
      if (detected == null) return false;
      final diff = (detected - entry.value).abs();
      print('  ${entry.key}: detected=${detected.toStringAsFixed(1)} expected=${entry.value} diff=${diff.toStringAsFixed(1)} ${diff <= 40 ? "✅" : "❌"}');
      return diff <= 40;
    });

    if (allMatched) {
      _holdCounter++;
      feedbackMessage = 'Hold it...';
      if (_holdCounter >= holdDurationSeconds * 2) {
        poseMatched = true;
        score++;
        feedbackMessage = 'Amazing! 🎉';
      }
    } else {
      _holdCounter = 0;
      feedbackMessage = 'Try again!';
    }
    notifyListeners();
  }

  void nextPose() {
    if (currentPoseIndex < poses.length - 1) {
      currentPoseIndex++;
      poseMatched = false;
      _holdCounter = 0;
      feedbackMessage = 'Get ready!';
    } else {
      completeSession();
    }
    notifyListeners();
  }

  void completeSession() {
    sessionComplete = true;
    notifyListeners();
  }

  void reset() {
    poses = [];
    currentPoseIndex = 0;
    poseMatched = false;
    sessionComplete = false;
    score = 0;
    feedbackMessage = 'Get ready!';
    _holdCounter = 0;
    notifyListeners();
  }
}
