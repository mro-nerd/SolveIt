import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `children` table.
class ChildService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Creates a new child row. The Postgres trigger will auto-generate
  /// `join_code` if not supplied.
  Future<Map<String, dynamic>> createChild({
    required String parentId,
    required String name,
    required DateTime dob,
    required String gender,
  }) async {
    try {
      final response = await _db
          .from('children')
          .insert({
            'parent_id': parentId,
            'child_name': name,
            'date_of_birth': dob.toIso8601String().split('T').first,
            'gender': gender,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('ChildService.createChild failed: $e');
    }
  }

  /// Returns all children belonging to [parentId], ordered newest first.
  Future<List<Map<String, dynamic>>> getChildrenForParent(
      String parentId) async {
    try {
      final response = await _db
          .from('children')
          .select()
          .eq('parent_id', parentId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('ChildService.getChildrenForParent failed: $e');
    }
  }

  /// Returns all children assigned to [doctorId], including a joined
  /// `latest_session` subquery with the most recent session data per child.
  Future<List<Map<String, dynamic>>> getChildrenForDoctor(
      String doctorId) async {
    try {
      // Fetch children assigned to this doctor
      final children = await _db
          .from('children')
          .select()
          .eq('assigned_doctor_id', doctorId)
          .order('created_at', ascending: false);

      final result = <Map<String, dynamic>>[];
      for (final child in children) {
        // Get the latest session for this child
        final latestSession = await _db
            .from('sessions')
            .select()
            .eq('child_id', child['id'])
            .order('completed_at', ascending: false)
            .limit(1)
            .maybeSingle();

        result.add({
          ...Map<String, dynamic>.from(child),
          'latest_session': latestSession,
        });
      }
      return result;
    } catch (e) {
      throw Exception('ChildService.getChildrenForDoctor failed: $e');
    }
  }

  /// Links a doctor to a child via the 6-char join code.
  /// Returns `true` on success, `false` if the code was not found.
  Future<bool> assignDoctor(String joinCode, String doctorId) async {
    try {
      final child = await _db
          .from('children')
          .select('id')
          .eq('join_code', joinCode.toUpperCase().trim())
          .maybeSingle();

      if (child == null) return false;

      await _db.from('children').update({
        'assigned_doctor_id': doctorId,
      }).eq('id', child['id']);

      return true;
    } catch (e) {
      throw Exception('ChildService.assignDoctor failed: $e');
    }
  }

  /// Updates the diagnosis status for a child.
  /// Valid values: 'pending', 'low', 'medium', 'high'.
  Future<void> updateDiagnosisStatus(String childId, String status) async {
    try {
      await _db.from('children').update({
        'diagnosis_status': status,
      }).eq('id', childId);
    } catch (e) {
      throw Exception('ChildService.updateDiagnosisStatus failed: $e');
    }
  }
}
