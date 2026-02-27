/// The expected emotion the child should display in response to a stimulus.
enum ExpectedEmotion { happy, surprise, sad }

/// A single stimulus shown to the child during the assessment.
class Stimulus {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final ExpectedEmotion expectedEmotion;
  final int durationSeconds;

  /// Asset path to the cartoon image (e.g. 'assets/images/stimuli/funny_faces.png').
  final String? imagePath;

  const Stimulus({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.expectedEmotion,
    this.durationSeconds = 5,
    this.imagePath,
  });
}
