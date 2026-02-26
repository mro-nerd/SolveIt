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
        'left_shoulder': 170,
        'right_shoulder': 170,
        'left_elbow': 160,
        'right_elbow': 160,
      },
    ),
    PoseReference(
      name: 'Wave',
      emoji: '👋',
      instruction: 'Raise one arm out to your side!',
      angleThresholds: {
        'right_shoulder': 90,
        'left_shoulder': 10,
        'right_elbow': 170,
        'left_elbow': 30,
      },
    ),
    PoseReference(
      name: 'Clap',
      emoji: '👏',
      instruction: 'Stretch both arms forward!',
      angleThresholds: {
        'left_shoulder': 80,
        'right_shoulder': 80,
        'left_elbow': 170,
        'right_elbow': 170,
      },
    ),
  ];
}
