import '../data/models/mchat_question.dart';
import '../data/models/follow_up_conversation.dart';
import '../data/models/screening_session.dart';

/// All LLM prompt strings for the M-CHAT-R AI intelligence layer.
/// Separated fully from the service so they can be tuned independently.
class MchatPromptTemplates {
  MchatPromptTemplates._();

  // ─── System Prompts ──────────────────────────────────────────────────────────

  /// System persona for follow-up probing conversations.
  static const String followUpSystemPrompt = '''
### ROLE
You are a **Developmental Specialist Copilot** — a warm, empathetic AI assistant supporting parents during the M-CHAT-R screening process.

### CONTEXT
A parent just answered a screening question in a way that indicates a potential developmental concern. Your job is to gently explore this further to give their healthcare provider richer context. You are NOT diagnosing — you are gathering observational detail.

### BEHAVIOUR GUIDELINES
1. **One question at a time.** Never ask more than one question per message.
2. **Be warm and non-alarmist.** Use phrases like "That's helpful to know" or "Many parents notice this."
3. **Be specific and concrete.** Ask about frequency, context, duration — not vague generalities.
4. **Acknowledge first, then probe.** Always validate the parent's response before asking the next question.
5. **Stop after 3 exchanges.** Do not probe endlessly — wrap up gracefully.

### OUTPUT FORMAT
Plain conversational text. No bullet points, no headers. Keep responses under 60 words.
''';

  /// System persona for behaviour interpretation.
  static const String interpretationSystemPrompt = '''
### ROLE
You are a **Child Development Interpreter** AI. You receive M-CHAT-R screening results and parent-provided notes, then produce a clear, compassionate developmental summary.

### CRITICAL RULES
- You NEVER diagnose autism or any condition.
- You NEVER override the clinical score.
- You ONLY interpret observed behaviours in developmental terms.
- Always include a reassurance paragraph.
- Always recommend professional consultation.

### OUTPUT FORMAT
Use Markdown with these exact sections:
## Behaviour Summary
## Developmental Meaning
## Strengths to Celebrate
## Reassurance
## Next Steps
''';

  /// System persona for full structured report generation.
  static const String reportSystemPrompt = '''
### ROLE
You are a **Pediatric Screening Report Assistant**. Generate a structured, professional-grade but parent-friendly screening report based on M-CHAT-R results and parent notes.

### CRITICAL RULES
- Do NOT diagnose. Use language like "may suggest", "warrants further evaluation".
- The risk score and level are clinically determined — present them as-is without modification.
- Write for a parent audience: clear, warm, empowering.

### OUTPUT FORMAT
Use Markdown with these exact sections:
## Screening Summary
## Strengths Observed
## Areas of Concern
## Risk Explanation
## Recommended Next Steps
## Therapy Activity Suggestions
## Important Disclaimer
''';

  /// System persona for history comparison.
  static const String comparisonSystemPrompt = '''
### ROLE
You are a **Developmental Progress Analyst** AI. Compare two M-CHAT-R screening sessions and highlight meaningful changes.

### CRITICAL RULES
- Do NOT diagnose.
- Focus on observable, concrete changes between sessions.
- Be encouraging about improvements, honest about persistent concerns.

### OUTPUT FORMAT
Use Markdown:
## What's Changed
## Areas of Improvement
## Persistent Areas of Concern
## Progress Reflection
## Suggested Focus Areas
''';

  // ─── User Prompt Builders ────────────────────────────────────────────────────

  /// Builds the first follow-up probe after a risk-positive answer.
  static String buildFirstFollowUpPrompt({
    required MchatQuestion question,
    required bool answer,
  }) {
    final answerText = answer ? 'Yes' : 'No';
    return '''
The parent answered "$answerText" to the following M-CHAT-R question:

**Question:** "${question.question}"
${question.examples.isNotEmpty ? '**Examples given:** "${question.examples}"' : ''}

This answer is a potential developmental concern indicator. Please ask one warm, specific follow-up question to understand this better. Focus on frequency, context, or circumstances.
''';
  }

  /// Builds a continuation prompt given prior conversation history.
  static String buildContinuationPrompt({
    required MchatQuestion question,
    required bool originalAnswer,
    required List<String> aiMessages,
    required List<String> parentReplies,
    required String latestParentReply,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('M-CHAT-R Question: "${question.question}"');
    buffer.writeln('Original answer: ${originalAnswer ? "Yes" : "No"}\n');
    buffer.writeln('Conversation so far:');

    for (int i = 0; i < aiMessages.length; i++) {
      buffer.writeln('Specialist: ${aiMessages[i]}');
      if (i < parentReplies.length) {
        buffer.writeln('Parent: ${parentReplies[i]}');
      }
    }

    buffer.writeln('\nParent just replied: "$latestParentReply"');
    buffer.writeln(
      '\nAcknowledge briefly and ask ONE more specific follow-up question, OR if you have enough context, say "Thank you — this is very helpful." and stop.',
    );

    return buffer.toString();
  }

  /// Builds the interpretation prompt from all failed questions + conversations.
  static String buildInterpretationPrompt({
    required List<MchatQuestion> failedQuestions,
    required List<FollowUpConversation> conversations,
    required int riskScore,
    required String riskLevel,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('M-CHAT-R Risk Score: $riskScore/20 → $riskLevel\n');
    buffer.writeln('Risk-indicator questions and parent context:\n');

    for (final q in failedQuestions) {
      buffer.writeln('─── Question ${q.id}: ${q.question}');
      final conv = conversations.where((c) => c.questionId == q.id).firstOrNull;
      if (conv != null && conv.parentReplies.isNotEmpty) {
        buffer.writeln('Parent observations:');
        for (final reply in conv.parentReplies) {
          buffer.writeln('  • $reply');
        }
      } else {
        buffer.writeln('  (No additional parent notes)');
      }
      buffer.writeln();
    }

    buffer.writeln(
      'Based on the above, provide a developmental interpretation following the specified format.',
    );
    return buffer.toString();
  }

  /// Builds the full report prompt.
  static String buildReportPrompt({
    required Map<int, bool> answers,
    required List<MchatQuestion> allQuestions,
    required List<FollowUpConversation> conversations,
    required int riskScore,
    required String riskLevel,
    required String? interpretationText,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('## M-CHAT-R Screening Data\n');
    buffer.writeln('Risk Score: $riskScore/20');
    buffer.writeln('Risk Level: $riskLevel\n');

    buffer.writeln('### Full Answer Record');
    for (final q in allQuestions) {
      final ans = answers[q.id];
      if (ans == null) continue;
      final isRisk =
          (q.riskWhenAnswerYes && ans) || (!q.riskWhenAnswerYes && !ans);
      buffer.writeln(
        '[${isRisk ? "CONCERN" : "OK"}] Q${q.id}: ${q.question} → ${ans ? "Yes" : "No"}',
      );
    }

    if (conversations.isNotEmpty) {
      buffer.writeln('\n### Parent Follow-up Notes');
      for (final conv in conversations) {
        final q = allQuestions.firstWhere((q) => q.id == conv.questionId);
        buffer.writeln('\nQ${q.id}: ${q.question}');
        for (int i = 0; i < conv.parentReplies.length; i++) {
          buffer.writeln('  Parent: ${conv.parentReplies[i]}');
        }
      }
    }

    if (interpretationText != null && interpretationText.isNotEmpty) {
      buffer.writeln('\n### Prior AI Interpretation\n$interpretationText');
    }

    buffer.writeln(
      '\nGenerate a comprehensive screening report following the specified format.',
    );
    return buffer.toString();
  }

  /// Builds the comparison prompt between two screening sessions.
  static String buildComparisonPrompt({
    required ScreeningSession current,
    required ScreeningSession previous,
    required List<MchatQuestion> allQuestions,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Comparing two M-CHAT-R screenings for the same child:\n');
    buffer.writeln(
      'PREVIOUS SCREENING: ${previous.completedAt.toLocal().toString().split('.').first}',
    );
    buffer.writeln('Score: ${previous.riskScore}/20 → ${previous.riskLevel}');
    buffer.writeln(
      '\nCURRENT SCREENING: ${current.completedAt.toLocal().toString().split('.').first}',
    );
    buffer.writeln('Score: ${current.riskScore}/20 → ${current.riskLevel}');

    buffer.writeln('\n### Answer Changes');
    for (final q in allQuestions) {
      final prev = previous.answers[q.id];
      final curr = current.answers[q.id];
      if (prev != null && curr != null && prev != curr) {
        final prevRisk =
            (q.riskWhenAnswerYes && prev) || (!q.riskWhenAnswerYes && !prev);
        final currRisk =
            (q.riskWhenAnswerYes && curr) || (!q.riskWhenAnswerYes && !curr);
        final direction = prevRisk && !currRisk ? '✅ IMPROVED' : '⚠️ CHANGED';
        buffer.writeln(
          '$direction - Q${q.id}: ${q.question.substring(0, q.question.length > 60 ? 60 : q.question.length)}...',
        );
        buffer.writeln(
          '  Before: ${prev ? "Yes" : "No"} → After: ${curr ? "Yes" : "No"}',
        );
      }
    }

    buffer.writeln(
      '\nProvide a progress comparison following the specified format.',
    );
    return buffer.toString();
  }
}
