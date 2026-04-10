import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `clinical_notes` table.
///
/// Notes are linked to the **parent's profile UID** (not child ID), so a
/// single note covers all children managed by that parent.
class ClinicalNotesService {
  SupabaseClient get _db => SupabaseClientManager.client;

  // ── Doctor-side: Send Notes ────────────────────────────────────────────

  /// Inserts a new clinical note / message.
  ///
  /// [targetType] must be `'all'` (broadcast) or `'specific'`.
  /// [targetParentUid] is required when [targetType] is `'specific'`.
  Future<Map<String, dynamic>> sendNote({
    required String doctorId,
    required String targetType,
    String? targetParentUid,
    required String message,
  }) async {
    assert(targetType == 'all' || targetType == 'specific');
    if (targetType == 'specific' && (targetParentUid == null || targetParentUid.isEmpty)) {
      throw Exception('targetParentUid is required for specific notes');
    }

    try {
      final response = await _db
          .from('clinical_notes')
          .insert({
            'doctor_id': doctorId,
            'target_type': targetType,
            'target_parent_uid': targetType == 'specific' ? targetParentUid : null,
            'message': message,
          })
          .select()
          .single();

      debugPrint('[ClinicalNotesService] Note sent: ${response['id']}');
      return response;
    } catch (e) {
      throw Exception('ClinicalNotesService.sendNote failed: $e');
    }
  }

  // ── Patient-side: Fetch Notes ──────────────────────────────────────────

  /// Fetches clinical notes addressed to this parent (specific) OR
  /// broadcast to all patients (target_type = 'all').
  ///
  /// Joins the doctor's `display_name` from `profiles`.
  Future<List<Map<String, dynamic>>> getNotesForParent(
    String parentUid, {
    int limit = 20,
  }) async {
    try {
      final response = await _db
          .from('clinical_notes')
          .select('*, profiles!clinical_notes_doctor_id_fkey(display_name)')
          .or('target_type.eq.all,target_parent_uid.eq.$parentUid')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[ClinicalNotesService] getNotesForParent error: $e');
      // Fallback: try without the join in case the FK alias fails
      try {
        final response = await _db
            .from('clinical_notes')
            .select()
            .or('target_type.eq.all,target_parent_uid.eq.$parentUid')
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        throw Exception('ClinicalNotesService.getNotesForParent failed: $e2');
      }
    }
  }

  // ── Doctor-side: Fetch Sent Notes ──────────────────────────────────────

  /// Fetches notes previously sent by this doctor.
  Future<List<Map<String, dynamic>>> getNotesForDoctor(
    String doctorId, {
    int limit = 20,
  }) async {
    try {
      final response = await _db
          .from('clinical_notes')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('ClinicalNotesService.getNotesForDoctor failed: $e');
    }
  }

  // ── Doctor-side: Parent list for targeting ─────────────────────────────

  /// Returns a list of distinct parents whose children are assigned to
  /// this doctor. Each entry includes `parent_id`, `parent_name`, and
  /// a list of `child_names` for display in the send-to dropdown.
  Future<List<Map<String, dynamic>>> getParentListForDoctor(
    String doctorId,
  ) async {
    try {
      // Get children assigned to this doctor with their parent info
      final children = await _db
          .from('children')
          .select('parent_id, child_name, profiles!children_parent_id_fkey(display_name)')
          .eq('assigned_doctor_id', doctorId)
          .order('child_name');

      // Group by parent_id
      final Map<String, Map<String, dynamic>> parentMap = {};
      for (final child in children) {
        final parentId = child['parent_id'] as String;
        if (!parentMap.containsKey(parentId)) {
          final profileData = child['profiles'];
          final parentName = profileData is Map
              ? (profileData['display_name'] as String? ?? 'Unknown')
              : 'Unknown';
          parentMap[parentId] = {
            'parent_id': parentId,
            'parent_name': parentName,
            'child_names': <String>[],
          };
        }
        (parentMap[parentId]!['child_names'] as List<String>)
            .add(child['child_name'] as String? ?? 'Unnamed');
      }

      return parentMap.values.toList();
    } catch (e) {
      debugPrint('[ClinicalNotesService] getParentListForDoctor error: $e');
      // Fallback without join
      try {
        final children = await _db
            .from('children')
            .select('parent_id, child_name')
            .eq('assigned_doctor_id', doctorId);

        final Map<String, Map<String, dynamic>> parentMap = {};
        for (final child in children) {
          final parentId = child['parent_id'] as String;
          if (!parentMap.containsKey(parentId)) {
            parentMap[parentId] = {
              'parent_id': parentId,
              'parent_name': 'Parent',
              'child_names': <String>[],
            };
          }
          (parentMap[parentId]!['child_names'] as List<String>)
              .add(child['child_name'] as String? ?? 'Unnamed');
        }
        return parentMap.values.toList();
      } catch (e2) {
        throw Exception('ClinicalNotesService.getParentListForDoctor failed: $e2');
      }
    }
  }
}
