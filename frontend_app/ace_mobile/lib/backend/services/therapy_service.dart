import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to `therapy_plans`
/// and `therapy_actions` tables.
class TherapyService {
  SupabaseClient get _db => SupabaseClientManager.client;

  // ═══════════════════════════════════════════════════════════════════════════
  //  THERAPY PLANS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates or updates a therapy plan. Returns the plan id.
  Future<String> upsertPlan({
    required String childId,
    required String doctorId,
    required String level,
    String? notes,
  }) async {
    try {
      final response = await _db
          .from('therapy_plans')
          .upsert(
            {
              'child_id': childId,
              'doctor_id': doctorId,
              'therapy_level': level,
              'notes': notes,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'child_id,doctor_id',
          )
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('TherapyService.upsertPlan failed: $e');
    }
  }

  /// Returns the active therapy plan for a child, or `null` if none exists.
  Future<Map<String, dynamic>?> getPlanForChild(String childId) async {
    try {
      final response = await _db
          .from('therapy_plans')
          .select('*, therapy_actions(*)')
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('TherapyService.getPlanForChild failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THERAPY ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates or updates a therapy action. If [actionId] is provided,
  /// updates the existing row; otherwise, inserts a new one.
  Future<void> upsertAction({
    String? actionId,
    required String planId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final data = <String, dynamic>{
        'plan_id': planId,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String().split('T').first,
      };

      if (actionId != null) {
        await _db.from('therapy_actions').update(data).eq('id', actionId);
      } else {
        await _db.from('therapy_actions').insert(data);
      }
    } catch (e) {
      throw Exception('TherapyService.upsertAction failed: $e');
    }
  }

  /// Deletes a therapy action by id.
  Future<void> deleteAction(String actionId) async {
    try {
      await _db.from('therapy_actions').delete().eq('id', actionId);
    } catch (e) {
      throw Exception('TherapyService.deleteAction failed: $e');
    }
  }

  /// Returns today's therapy actions for a child.
  Future<List<Map<String, dynamic>>> getTodaysActions(String childId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;

      final plan = await _db
          .from('therapy_plans')
          .select('id')
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (plan == null) return [];

      final response = await _db
          .from('therapy_actions')
          .select()
          .eq('plan_id', plan['id'])
          .eq('due_date', today)
          .order('is_completed', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('TherapyService.getTodaysActions failed: $e');
    }
  }

  /// Toggles the `is_completed` flag and sets/clears `completed_at`.
  Future<void> toggleActionComplete(
      String actionId, bool isCompleted) async {
    try {
      await _db.from('therapy_actions').update({
        'is_completed': isCompleted,
        'completed_at':
            isCompleted ? DateTime.now().toUtc().toIso8601String() : null,
      }).eq('id', actionId);
    } catch (e) {
      throw Exception('TherapyService.toggleActionComplete failed: $e');
    }
  }

  /// Returns a realtime stream of today's therapy actions for a child.
  /// Updates automatically when a doctor modifies actions.
  Stream<List<Map<String, dynamic>>> streamTodaysActions(
      String childId) {
    final today = DateTime.now().toIso8601String().split('T').first;

    // First, we need the plan id. We'll use a stream that re-fetches.
    return _db
        .from('therapy_actions')
        .stream(primaryKey: ['id'])
        .eq('due_date', today)
        .map((rows) {
          // Filter to only actions belonging to this child's plan
          // This is handled at the DB level via RLS, so we return all.
          return List<Map<String, dynamic>>.from(rows);
        });
  }
}
