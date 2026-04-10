import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ace_mobile/backend/supabase_client.dart';
import 'session_service.dart';

/// Generates AI summaries for completed sessions via OpenRouter and persists
/// them to the `sessions.ai_summary` column in Supabase.
///
/// Uses the same OpenRouter endpoint, API key, and model as [MchatAiService].
class AiSummaryService {
  static const String _apiEndpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'google/gemma-3n-e2b-it:free';

  final SessionService _sessionService = SessionService();

  String get _apiKey => dotenv.env['GENAI_KEY'] ?? '';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Generates an AI summary for a single session and writes it to Supabase.
  ///
  /// This is designed to be called fire-and-forget after a session is saved.
  /// Errors are logged but never thrown — the user flow is never blocked.
  Future<void> generateAndSave({
    required String sessionId,
    required String sessionType,
    required double score,
    required String riskFlag,
    required Map<String, dynamic> rawMetrics,
    String? childName,
  }) async {
    try {
      // If child name not provided, look it up from the session's child_id
      String resolvedChildName = childName ?? 'the child';
      if (childName == null || childName.isEmpty) {
        try {
          final sessionRow = await SupabaseClientManager.client
              .from('sessions')
              .select('child_id, children(child_name)')
              .eq('id', sessionId)
              .maybeSingle();
          if (sessionRow != null) {
            final childData = sessionRow['children'] as Map<String, dynamic>?;
            resolvedChildName = childData?['child_name'] as String? ?? 'the child';
          }
        } catch (e) {
          debugPrint('[AiSummaryService] Could not look up child name: $e');
        }
      }

      final prompt = _buildPrompt(
        sessionType: sessionType,
        score: score,
        riskFlag: riskFlag,
        rawMetrics: rawMetrics,
        childName: resolvedChildName,
      );

      final summary = await _callOpenRouter(prompt);
      if (summary == null || summary.trim().isEmpty) {
        debugPrint('[AiSummaryService] LLM returned empty response for $sessionId');
        return;
      }

      await _sessionService.updateAiSummary(sessionId, summary.trim());
      debugPrint('[AiSummaryService] ✅ Summary saved for session $sessionId');
    } catch (e) {
      debugPrint('[AiSummaryService] ❌ Failed for session $sessionId: $e');
      // Intentionally swallowed — ai_summary stays NULL, user flow continues
    }
  }

  /// Backfills AI summaries for all sessions where `ai_summary IS NULL`.
  ///
  /// Returns the number of sessions successfully backfilled.
  /// Inserts a 300ms delay between calls to avoid rate limiting.
  Future<int> backfillAll() async {
    int count = 0;
    try {
      final sessions = await SupabaseClientManager.client
          .from('sessions')
          .select('id, session_type, score, risk_flag, raw_metrics, children(child_name)')
          .isFilter('ai_summary', null)
          .order('completed_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(sessions);
      debugPrint('[AiSummaryService] Backfill: ${rows.length} sessions to process');

      for (final row in rows) {
        try {
          final childData = row['children'] as Map<String, dynamic>?;
          final childName = childData?['child_name'] as String? ?? 'the child';
          await generateAndSave(
            sessionId: row['id'] as String,
            sessionType: row['session_type'] as String? ?? 'unknown',
            score: (row['score'] as num?)?.toDouble() ?? 0,
            riskFlag: row['risk_flag'] as String? ?? 'low',
            rawMetrics: row['raw_metrics'] as Map<String, dynamic>? ?? {},
            childName: childName,
          );
          count++;
        } catch (e) {
          debugPrint('[AiSummaryService] Backfill skip ${row['id']}: $e');
        }
        // Rate-limit: 300ms between calls
        await Future.delayed(const Duration(milliseconds: 300));
      }

      debugPrint('[AiSummaryService] Backfill complete: $count/${rows.length} succeeded');
    } catch (e) {
      debugPrint('[AiSummaryService] Backfill query failed: $e');
    }
    return count;
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  /// Builds the prompt following the spec's template.
  String _buildPrompt({
    required String sessionType,
    required double score,
    required String riskFlag,
    required Map<String, dynamic> rawMetrics,
    required String childName,
  }) {
    return '''You are an autism care assistant. Based on the following session data, write a short 2-3 sentence plain-English summary for the parent. Use the child's actual name "$childName" in the summary. Mention what the session measured, how $childName performed, and the risk level. Keep it warm, simple, and non-alarming.

IMPORTANT: Do NOT use placeholder text like "[child's name]" or "[Parent Name]" or any bracketed placeholders. Use the actual name "$childName" directly.

Child's name: $childName
Session type: $sessionType
Score: ${score.toStringAsFixed(1)}
Risk level: $riskFlag
Raw data: ${jsonEncode(rawMetrics)}''';
  }

  /// Calls OpenRouter with a non-streaming request and returns the full
  /// response text, or null on failure.
  Future<String?> _callOpenRouter(String prompt) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse(_apiEndpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://ace-app.com',
            'X-Title': 'ACE AI Summary',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.6,
            'max_tokens': 200,
            'stream': false,
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final content = json['choices']?[0]?['message']?['content'];
          return content as String?;
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          // Retryable — exponential backoff
          attempt++;
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: 1 << attempt));
          }
        } else {
          debugPrint('[AiSummaryService] Non-retryable error: ${response.statusCode}');
          return null;
        }
      } on SocketException {
        attempt++;
        if (attempt >= maxRetries) return null;
        await Future.delayed(Duration(seconds: 1 << attempt));
      } catch (e) {
        debugPrint('[AiSummaryService] Unexpected error: $e');
        return null;
      }
    }
    return null;
  }
}
