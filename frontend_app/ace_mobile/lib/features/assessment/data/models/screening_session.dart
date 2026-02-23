import 'dart:convert';
import 'follow_up_conversation.dart';

/// A single completed M-CHAT-R screening session persisted to local storage.
class ScreeningSession {
  final String id;
  final DateTime completedAt;
  final Map<int, bool> answers;
  final int riskScore;
  final String riskLevel;
  final List<FollowUpConversation> conversations;
  final String? interpretationReport; // markdown
  final String? fullReport; // markdown

  const ScreeningSession({
    required this.id,
    required this.completedAt,
    required this.answers,
    required this.riskScore,
    required this.riskLevel,
    required this.conversations,
    this.interpretationReport,
    this.fullReport,
  });

  ScreeningSession copyWith({
    String? interpretationReport,
    String? fullReport,
  }) {
    return ScreeningSession(
      id: id,
      completedAt: completedAt,
      answers: answers,
      riskScore: riskScore,
      riskLevel: riskLevel,
      conversations: conversations,
      interpretationReport: interpretationReport ?? this.interpretationReport,
      fullReport: fullReport ?? this.fullReport,
    );
  }

  factory ScreeningSession.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>;
    final rawConvs = json['conversations'] as List<dynamic>? ?? [];

    return ScreeningSession(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      answers: rawAnswers.map((k, v) => MapEntry(int.parse(k), v as bool)),
      riskScore: json['risk_score'] as int,
      riskLevel: json['risk_level'] as String,
      conversations: rawConvs
          .map((e) => FollowUpConversation.fromJson(e as Map<String, dynamic>))
          .toList(),
      interpretationReport: json['interpretation_report'] as String?,
      fullReport: json['full_report'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'completed_at': completedAt.toIso8601String(),
    'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    'risk_score': riskScore,
    'risk_level': riskLevel,
    'conversations': conversations.map((c) => c.toJson()).toList(),
    'interpretation_report': interpretationReport,
    'full_report': fullReport,
  };

  static String encodeList(List<ScreeningSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());

  static List<ScreeningSession> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => ScreeningSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
