import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `sessions` table.
class SessionService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Inserts a new session and returns the session id.
  /// Automatically computes and stores the `risk_flag`.
  ///
  /// Each completed session always creates a new row — no duplicate guard.
  Future<SaveSessionResult> saveSession({
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

  // ── Doctor-side queries ──────────────────────────────────────────────────

  /// Returns recent sessions across all patients assigned to [doctorId].
  /// Each row includes the child's name and parent_id for display.
  Future<List<Map<String, dynamic>>> getRecentSessionsForDoctor(
    String doctorId, {
    int limit = 20,
  }) async {
    try {
      // Get all children assigned to this doctor
      final children = await _db
          .from('children')
          .select('id, child_name, parent_id')
          .eq('assigned_doctor_id', doctorId);

      if (children.isEmpty) return [];

      final childIds = (children as List)
          .map((c) => c['id'] as String)
          .toList();

      // Build a lookup map: childId → {child_name, parent_id}
      final childLookup = <String, Map<String, dynamic>>{};
      for (final c in children) {
        childLookup[c['id'] as String] = {
          'child_name': c['child_name'],
          'parent_id': c['parent_id'],
        };
      }

      // Fetch recent sessions for those children
      final sessions = await _db
          .from('sessions')
          .select()
          .inFilter('child_id', childIds)
          .order('completed_at', ascending: false)
          .limit(limit);

      // Enrich each session with child name
      return List<Map<String, dynamic>>.from(sessions).map((s) {
        final childInfo = childLookup[s['child_id']];
        return {
          ...s,
          'child_name': childInfo?['child_name'] ?? 'Unknown',
          'parent_id': childInfo?['parent_id'],
        };
      }).toList();
    } catch (e) {
      throw Exception('SessionService.getRecentSessionsForDoctor failed: $e');
    }
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
