/// Pure data class representing a reference pose for the imitation feature.
class PoseReference {
  final String name;
  final String emoji;
  final String instruction;

  /// Joint-angle thresholds (in degrees) that define this pose.
  /// Keys: left_elbow, right_elbow, left_shoulder, right_shoulder
  final Map<String, double> angleThresholds;

  const PoseReference({
    required this.name,
    required this.emoji,
    required this.instruction,
    required this.angleThresholds,
  });

  static const List<PoseReference> simplePoses = [
    PoseReference(
      name: 'Arms Up',
      emoji: '🙌',
      instruction: 'Raise both arms above your head!',
      angleThresholds: {
        'left_shoulder': 140,
        'right_shoulder': 140,
      },
    ),
    PoseReference(
      name: 'Wave',
      emoji: '👋',
      instruction: 'Raise your right arm out to your side!',
      angleThresholds: {
        'right_shoulder': 80,
      },
    ),
    PoseReference(
      name: 'Namaste',
      emoji: '🙏',
      instruction: 'Bring both hands together in front of your chest!',
      angleThresholds: {
        'left_shoulder': 50,
        'right_shoulder': 50,
      },
    ),
  ];
}
