import 'dart:convert';

/// Represents a single recorded answer to an M-CHAT-R question.
class MchatAnswer {
  final int questionId;
  final bool answer;
  final DateTime answeredAt;

  const MchatAnswer({
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });

  factory MchatAnswer.fromJson(Map<String, dynamic> json) {
    return MchatAnswer(
      questionId: json['question_id'] as int,
      answer: json['answer'] as bool,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer': answer,
    'answered_at': answeredAt.toIso8601String(),
  };

  static String encodeList(List<MchatAnswer> answers) =>
      jsonEncode(answers.map((a) => a.toJson()).toList());

  static List<MchatAnswer> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => MchatAnswer.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
