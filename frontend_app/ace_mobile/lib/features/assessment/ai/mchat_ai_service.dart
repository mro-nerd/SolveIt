import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../data/models/mchat_question.dart';
import '../data/models/follow_up_conversation.dart';
import '../data/models/screening_session.dart';
import '../data/datasources/mchat_questions_data.dart';
import 'mchat_prompt_templates.dart';

/// OpenRouter-backed AI service for the M-CHAT-R intelligence layer.
/// Mirrors the pattern in AIChatService with exponential-backoff retry.
class MchatAiService {
  static const String _apiEndpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'google/gemini-2.0-flash-001';
  static const int _maxRetries = 3;

  String get _apiKey => dotenv.env['GENAI_KEY'] ?? '';

  // ─── Core SSE Stream ────────────────────────────────────────────────────────

  /// Internal streaming method. Handles SSE parsing + retry.
  Stream<String> _stream({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async* {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final request = http.Request('POST', Uri.parse(_apiEndpoint))
          ..headers.addAll({
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://ace-app.com',
            'X-Title': 'ACE M-CHAT AI',
          })
          ..body = jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': temperature,
            'stream': true,
          });

        final client = http.Client();
        final response = await client.send(request);

        if (response.statusCode == 200) {
          await for (final chunk
              in response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            if (chunk.trim().isEmpty) continue;
            if (!chunk.startsWith('data: ')) continue;
            final data = chunk.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'];
              if (content != null) yield content as String;
            } catch (_) {
              // Malformed chunk — skip
            }
          }
          return; // Success — exit retry loop
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          // Retryable error — fall through to retry
          attempt++;
          if (attempt < _maxRetries) {
            await Future.delayed(Duration(seconds: 1 << attempt)); // backoff
          }
        } else {
          yield '\n\n*[AI unavailable — status ${response.statusCode}]*';
          return;
        }
      } on SocketException {
        attempt++;
        if (attempt >= _maxRetries) {
          yield '\n\n*[Network error — please check your connection.]*';
          return;
        }
        await Future.delayed(Duration(seconds: 1 << attempt));
      } catch (e) {
        yield '\n\n*[Unexpected error: $e]*';
        return;
      }
    }
    yield '\n\n*[AI temporarily unavailable — please try again.]*';
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// First follow-up probe after a risk-positive answer.
  Stream<String> streamFirstFollowUp({
    required MchatQuestion question,
    required bool answer,
  }) {
    return _stream(
      systemPrompt: MchatPromptTemplates.followUpSystemPrompt,
      userPrompt: MchatPromptTemplates.buildFirstFollowUpPrompt(
        question: question,
        answer: answer,
      ),
      temperature: 0.6,
    );
  }

  /// Continuation follow-up after the parent replies.
  Stream<String> streamContinuationFollowUp({
    required MchatQuestion question,
    required bool originalAnswer,
    required FollowUpConversation conversation,
    required String latestParentReply,
  }) {
    return _stream(
      systemPrompt: MchatPromptTemplates.followUpSystemPrompt,
      userPrompt: MchatPromptTemplates.buildContinuationPrompt(
        question: question,
        originalAnswer: originalAnswer,
        aiMessages: conversation.aiMessages,
        parentReplies: conversation.parentReplies,
        latestParentReply: latestParentReply,
      ),
      temperature: 0.6,
    );
  }

  /// Full behaviour interpretation from all risk-positive questions + notes.
  Stream<String> streamInterpretation({
    required List<MchatQuestion> failedQuestions,
    required List<FollowUpConversation> conversations,
    required int riskScore,
    required String riskLevel,
  }) {
    return _stream(
      systemPrompt: MchatPromptTemplates.interpretationSystemPrompt,
      userPrompt: MchatPromptTemplates.buildInterpretationPrompt(
        failedQuestions: failedQuestions,
        conversations: conversations,
        riskScore: riskScore,
        riskLevel: riskLevel,
      ),
      temperature: 0.5,
    );
  }

  /// Structured clinical screening report.
  Stream<String> streamReport({
    required Map<int, bool> answers,
    required List<FollowUpConversation> conversations,
    required int riskScore,
    required String riskLevel,
    String? interpretationText,
  }) {
    return _stream(
      systemPrompt: MchatPromptTemplates.reportSystemPrompt,
      userPrompt: MchatPromptTemplates.buildReportPrompt(
        answers: answers,
        allQuestions: kMchatQuestions,
        conversations: conversations,
        riskScore: riskScore,
        riskLevel: riskLevel,
        interpretationText: interpretationText,
      ),
      temperature: 0.4,
    );
  }

  /// Progress comparison between two screening sessions.
  Stream<String> streamComparison({
    required ScreeningSession current,
    required ScreeningSession previous,
  }) {
    return _stream(
      systemPrompt: MchatPromptTemplates.comparisonSystemPrompt,
      userPrompt: MchatPromptTemplates.buildComparisonPrompt(
        current: current,
        previous: previous,
        allQuestions: kMchatQuestions,
      ),
      temperature: 0.5,
    );
  }
}
