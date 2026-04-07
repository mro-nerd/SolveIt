import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `sessions` table.
class SessionService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Inserts a new session and returns the session id.
  /// Automatically computes and stores the `risk_flag`.
  ///
  /// **Duplicate guard:** If a session with the same child_id, session_type,
  /// and completed_at date (today) already exists, returns that session's id
  /// instead of inserting a duplicate.
  Future<SaveSessionResult> saveSession({
    required String childId,
    required String sessionType,
    required double score,
    required Map<String, dynamic> rawMetrics,
  }) async {
    try {
      // ── Check for duplicate session today ──
      final todayStart = DateTime.now().toUtc();
      final todayStr =
          '${todayStart.year}-${todayStart.month.toString().padLeft(2, '0')}-${todayStart.day.toString().padLeft(2, '0')}';

      final existing = await _db
          .from('sessions')
          .select('id')
          .eq('child_id', childId)
          .eq('session_type', sessionType)
          .gte('completed_at', '${todayStr}T00:00:00')
          .lt('completed_at', '${todayStr}T23:59:59.999999')
          .maybeSingle();

      if (existing != null) {
        debugPrint(
            '[SessionService] Duplicate session found for $sessionType today');
        return SaveSessionResult(
          sessionId: existing['id'] as String,
          wasDuplicate: true,
        );
      }

      // ── Insert new session ──
      final riskFlag = _computeRiskFlag(sessionType, score);

      final response = await _db
          .from('sessions')
          .insert({
            'child_id': childId,
            'session_type': sessionType,
            'score': score,
            'raw_metrics': rawMetrics,
            'risk_flag': riskFlag,
          })
          .select('id')
          .single();

      return SaveSessionResult(
        sessionId: response['id'] as String,
        wasDuplicate: false,
      );
    } catch (e) {
      throw Exception('SessionService.saveSession failed: $e');
    }
  }

  /// Returns sessions for a child, optionally filtered by [sessionType],
  /// ordered newest first, limited to [limit] rows.
  Future<List<Map<String, dynamic>>> getSessionsForChild(
    String childId, {
    String? sessionType,
    int limit = 10,
  }) async {
    try {
      var query = _db
          .from('sessions')
          .select()
          .eq('child_id', childId);

      if (sessionType != null) {
        query = query.eq('session_type', sessionType);
      }

      final response = await query
          .order('completed_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('SessionService.getSessionsForChild failed: $e');
    }
  }

  /// Updates the AI-generated summary text for a session.
  Future<void> updateAiSummary(String sessionId, String summary) async {
    try {
      await _db
          .from('sessions')
          .update({'ai_summary': summary})
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('SessionService.updateAiSummary failed: $e');
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Determines the risk flag based on session type and score.
  ///
  /// M-CHAT uses an inverted scale (higher score = higher risk):
  ///   score >= 8 → 'high', 3–7 → 'medium', < 3 → 'low'
  ///
  /// All other types use a direct scale (higher score = better):
  ///   score < 40 → 'high', 40–65 → 'medium', > 65 → 'low'
  String _computeRiskFlag(String sessionType, double score) {
    if (sessionType == 'mchat') {
      if (score >= 8) return 'high';
      if (score >= 3) return 'medium';
      return 'low';
    }

    // emotion_assessment, eye_contact, imitation
    if (score < 40) return 'high';
    if (score <= 65) return 'medium';
    return 'low';
  }

  // ── Debug helpers ────────────────────────────────────────────────────────

  /// Quick smoke-test: saves a dummy session to verify Supabase writes work.
  /// Usage: await sessionService.testSave(childId)
  Future<String> testSave(String childId) async {
    debugPrint('[SessionService] testSave called with childId: $childId');
    final result = await saveSession(
      childId: childId,
      sessionType: 'test',
      score: 99.0,
      rawMetrics: {'test': true, 'timestamp': DateTime.now().toIso8601String()},
    );
    return result.sessionId;
  }
}

/// Result of [SessionService.saveSession] indicating whether a new session
/// was created or an existing duplicate was returned.
class SaveSessionResult {
  final String sessionId;
  final bool wasDuplicate;

  const SaveSessionResult({
    required this.sessionId,
    required this.wasDuplicate,
  });
}
