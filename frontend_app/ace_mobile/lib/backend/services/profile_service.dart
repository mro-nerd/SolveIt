import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase operations related to the `profiles` table.
class ProfileService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Creates or updates a profile row keyed by Supabase auth [userId].
  Future<void> upsertProfile({
    required String userId,
    required String role,
    required String displayName,
    required String email,
  }) async {
    try {
      await _db.from('profiles').upsert(
        {
          'id': userId,
          'display_name': displayName,
          'email': email,
          'role': role,
        },
        onConflict: 'id',
      );
    } catch (e) {
      throw Exception('ProfileService.upsertProfile failed: $e');
    }
  }

  /// Fetches the full profile row for the given Supabase user ID.
  /// Returns `null` if no profile exists yet (first-time user).
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
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
