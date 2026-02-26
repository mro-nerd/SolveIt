import 'stimulus.dart';

/// A single emotion sample captured from the camera during one frame.
class EmotionSample {
  final double smilingProbability;
  final double avgEyeOpenProbability;
  final int timestampMs;

  const EmotionSample({
    required this.smilingProbability,
    required this.avgEyeOpenProbability,
    required this.timestampMs,
  });

  /// Derive the detected emotion from ML Kit probabilities.
  DetectedEmotion get detectedEmotion {
    if (smilingProbability > 0.5) return DetectedEmotion.happy;
    if (avgEyeOpenProbability > 0.85 && smilingProbability < 0.3) {
      return DetectedEmotion.surprise;
    }
    if (smilingProbability < 0.15 && avgEyeOpenProbability < 0.6) {
      return DetectedEmotion.sad;
    }
    return DetectedEmotion.neutral;
  }

  /// How well this sample matches the expected emotion (0.0–1.0).
  double matchScore(ExpectedEmotion expected) {
    switch (expected) {
      case ExpectedEmotion.happy:
        return smilingProbability.clamp(0.0, 1.0);
      case ExpectedEmotion.surprise:
        // High eye openness + low smiling → surprise
        final eyeScore = ((avgEyeOpenProbability - 0.5) * 2).clamp(0.0, 1.0);
        final notSmiling = (1.0 - smilingProbability).clamp(0.0, 1.0);
        return (eyeScore * 0.6 + notSmiling * 0.4).clamp(0.0, 1.0);
      case ExpectedEmotion.sad:
        // Low smiling + lower eye openness → sad/empathy
        final notSmiling = (1.0 - smilingProbability).clamp(0.0, 1.0);
        final lowEyes = (1.0 - avgEyeOpenProbability).clamp(0.0, 1.0);
        return (notSmiling * 0.7 + lowEyes * 0.3).clamp(0.0, 1.0);
    }
  }
}

enum DetectedEmotion { happy, surprise, sad, neutral }

/// The result of a single assessment round.
class RoundResult {
  final Stimulus stimulus;
  final List<EmotionSample> samples;
  final int reactionTimeMs;
  final double emotionMatchScore; // 0–100
  final double peakIntensity; // 0–1

  const RoundResult({
    required this.stimulus,
    required this.samples,
    required this.reactionTimeMs,
    required this.emotionMatchScore,
    required this.peakIntensity,
  });
}

/// The overall assessment summary after all rounds.
class AssessmentSummary {
  final List<RoundResult> roundResults;
  final double overallScore; // 0–100
  final double avgReactionTimeMs;
  final double emotionalVariability; // 0–1 (lower = more consistent)
  final double empathyScore; // 0–100 (based on sad stimulus rounds)

  const AssessmentSummary({
    required this.roundResults,
    required this.overallScore,
    required this.avgReactionTimeMs,
    required this.emotionalVariability,
    required this.empathyScore,
  });
}
