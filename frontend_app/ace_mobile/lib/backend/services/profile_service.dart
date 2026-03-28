import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `profiles` table.
class ProfileService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Creates or updates a profile row keyed by [firebaseUid].
  Future<void> upsertProfile({
    required String firebaseUid,
    required String role,
    required String displayName,
    required String email,
  }) async {
    try {
      await _db.from('profiles').upsert(
        {
          'firebase_uid': firebaseUid,
          'display_name': displayName,
          'email': email,
          'role': role,
        },
        onConflict: 'firebase_uid',
      );
    } catch (e) {
      throw Exception('ProfileService.upsertProfile failed: $e');
    }
  }

  /// Fetches the full profile row for the given Firebase UID.
  /// Returns `null` if no profile exists yet (first-time user).
  Future<Map<String, dynamic>?> getProfile(String firebaseUid) async {
    try {
      final response = await _db
          .from('profiles')
          .select()
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('ProfileService.getProfile failed: $e');
    }
  }

  /// Updates only the role column for a given profile id.
  Future<void> updateRole(String profileId, String role) async {
    try {
      await _db
          .from('profiles')
          .update({'role': role})
          .eq('id', profileId);
    } catch (e) {
      throw Exception('ProfileService.updateRole failed: $e');
    }
  }
}
