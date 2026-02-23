/// Immutable data model representing a single M-CHAT-R question.
class MchatQuestion {
  final int id;
  final String question;
  final String examples;
  final bool riskWhenAnswerYes;
  final String category;

  const MchatQuestion({
    required this.id,
    required this.question,
    required this.examples,
    required this.riskWhenAnswerYes,
    required this.category,
  });

  factory MchatQuestion.fromJson(Map<String, dynamic> json) {
    return MchatQuestion(
      id: json['id'] as int,
      question: json['question'] as String,
      examples: json['examples'] as String? ?? '',
      riskWhenAnswerYes: json['risk_when_answer_yes'] as bool,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'examples': examples,
    'risk_when_answer_yes': riskWhenAnswerYes,
    'category': category,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MchatQuestion && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
