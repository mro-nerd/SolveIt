import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Sign up a new user and create their profile row
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'doctor' or 'patient'
  }) async {
    final res = await _db.auth.signUp(email: email, password: password);
    if (res.user == null) throw Exception('Sign up failed');

    // Create profile row — id matches auth.uid() automatically
    await _db.from('profiles').insert({
      'id': res.user!.id,
      'email': email,
      'display_name': displayName,
      'role': role,
    });

    debugPrint('[Auth] Signed up: ${res.user!.email} as $role');
    return res;
  }

  /// Sign in existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _db.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Sign in failed');
    debugPrint('[Auth] Signed in: ${res.user!.email}');
    return res;
  }

  /// Sign out
  Future<void> signOut() async {
    await _db.auth.signOut();
    debugPrint('[Auth] Signed out');
  }

  /// Restore session on app cold start (Supabase does this automatically
  /// but call this to be explicit)
  Future<void> restoreSession() async {
    final session = _db.auth.currentSession;
    if (session != null) {
      debugPrint('[Auth] Session restored for: ${session.user.email}');
    } else {
      debugPrint('[Auth] No active session found');
    }
  }

  /// Fetch the logged-in user profile from Supabase
  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final user = SupabaseClientManager.currentUser;
    if (user == null) return null;
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return data;
  }
}
