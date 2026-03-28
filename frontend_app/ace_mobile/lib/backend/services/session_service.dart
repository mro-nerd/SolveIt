import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `sessions` table.
class SessionService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Inserts a new session and returns the session id.
  /// Automatically computes and stores the `risk_flag`.
  Future<String> saveSession({
    required String childId,
    required String sessionType,
    required double score,
    required Map<String, dynamic> rawMetrics,
  }) async {
    try {
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

      return response['id'] as String;
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
}
