import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts a raw Supabase / network exception into a sanitised, user-facing
/// message. Always returns a non-null, non-empty string.
String _authErrorMessage(Object e) {
  if (e is AuthException) {
    // Map well-known Supabase auth codes to friendly strings.
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid password') ||
        msg.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('email already')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('network') || msg.contains('socket') ||
        msg.contains('connection')) {
      return 'No internet connection. Please check your network and retry.';
    }
    // Fall back to the SDK message stripped of technical noise.
    return e.message.isNotEmpty ? e.message : 'Authentication failed.';
  }
  if (e is PostgrestException) {
    debugPrint('[Auth] DB error: ${e.code} – ${e.message}');
    return 'A database error occurred. Please try again.';
  }
  // Generic fallback.
  final raw = e.toString();
  if (raw.toLowerCase().contains('socket') ||
      raw.toLowerCase().contains('network') ||
      raw.toLowerCase().contains('connection')) {
    return 'No internet connection. Please check your network and retry.';
  }
  return 'Something went wrong. Please try again.';
}

class AuthService {
  SupabaseClient get _db => SupabaseClientManager.client;

  /// Sign up a new user and create their profile row.
  /// Throws a user-friendly [Exception] on any failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'doctor' or 'parent'
  }) async {
    // Basic client-side validation before hitting the network.
    if (email.trim().isEmpty) throw Exception('Please enter your email address.');
    if (password.isEmpty) throw Exception('Please enter a password.');
    if (password.length < 6) throw Exception('Password must be at least 6 characters.');
    if (displayName.trim().isEmpty) throw Exception('Please enter your full name.');

    try {
      final res = await _db.auth.signUp(email: email.trim(), password: password);
      if (res.user == null) throw Exception('Sign up failed. Please try again.');

      // Create profile row — id matches auth.uid() automatically.
      await _db.from('profiles').insert({
        'id': res.user!.id,
        'email': email.trim(),
        'display_name': displayName.trim(),
        'role': role,
      });

      debugPrint('[Auth] Signed up: ${res.user!.email} as $role');
      return res;
    } catch (e) {
      // Re-throw clean messages; don't wrap our own Exceptions twice.
      if (e is Exception &&
          e.toString().startsWith('Exception: Please') ||
          e.toString().startsWith('Exception: Password') ||
          e.toString().startsWith('Exception: Sign up')) {
        rethrow;
      }
      debugPrint('[Auth] signUp error: $e');
      throw Exception(_authErrorMessage(e));
    }
  }

  /// Sign in an existing user.
  /// Throws a user-friendly [Exception] on any failure.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) throw Exception('Please enter your email address.');
    if (password.isEmpty) throw Exception('Please enter your password.');

    try {
      final res = await _db.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) throw Exception('Sign in failed. Please try again.');
      debugPrint('[Auth] Signed in: ${res.user!.email}');
      return res;
    } catch (e) {
      if (e is Exception &&
          (e.toString().startsWith('Exception: Please') ||
           e.toString().startsWith('Exception: Sign in'))) {
        rethrow;
      }
      debugPrint('[Auth] signIn error: $e');
      throw Exception(_authErrorMessage(e));
    }
  }

  /// Sign out the current user.
  /// Throws a user-friendly [Exception] on failure.
  Future<void> signOut() async {
    try {
      await _db.auth.signOut();
      debugPrint('[Auth] Signed out');
    } catch (e) {
      debugPrint('[Auth] signOut error: $e');
      throw Exception(_authErrorMessage(e));
    }
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

  /// Fetch the logged-in user profile from Supabase.
  /// Returns null if no user is logged in or no profile row exists.
  /// Throws a user-friendly [Exception] on network / DB errors.
  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final user = SupabaseClientManager.currentUser;
    if (user == null) return null;
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('[Auth] fetchCurrentProfile error: $e');
      throw Exception(_authErrorMessage(e));
    }
  }
}
