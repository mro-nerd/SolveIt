import 'dart:convert';

/// Records the AI follow-up conversation after a risk-positive answer.
class FollowUpConversation {
  final int questionId;

  /// AI-generated probing messages.
  final List<String> aiMessages;

  /// Parent replies, aligned index-wise with aiMessages.
  final List<String> parentReplies;

  FollowUpConversation({
    required this.questionId,
    List<String>? aiMessages,
    List<String>? parentReplies,
  }) : aiMessages = aiMessages ?? [],
       parentReplies = parentReplies ?? [];

  bool get hasContent => parentReplies.isNotEmpty;

  /// Returns a plain-text summary of the parent's notes for this question.
  String get parentNotesSummary => parentReplies.join(' ');

  FollowUpConversation copyWith({
    List<String>? aiMessages,
    List<String>? parentReplies,
  }) {
    return FollowUpConversation(
      questionId: questionId,
      aiMessages: aiMessages ?? List.from(this.aiMessages),
      parentReplies: parentReplies ?? List.from(this.parentReplies),
    );
  }

  factory FollowUpConversation.fromJson(Map<String, dynamic> json) {
    return FollowUpConversation(
      questionId: json['question_id'] as int,
      aiMessages: List<String>.from(json['ai_messages'] as List),
      parentReplies: List<String>.from(json['parent_replies'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'ai_messages': aiMessages,
    'parent_replies': parentReplies,
  };

  static String encodeList(List<FollowUpConversation> list) =>
      jsonEncode(list.map((c) => c.toJson()).toList());

  static List<FollowUpConversation> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => FollowUpConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
