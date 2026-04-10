import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/features/doctor/doctor_bottom_navbar.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ace_mobile/features/auth/loginPage.dart';
import 'package:ace_mobile/shared/BottomNavbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides where the app lands after the splash screen.
///
/// • Active Supabase session + saved role → correct dashboard (fast path)
/// • Otherwise → [loginPage] (GetStarted → ChooseProfession)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in via Supabase
    final isLoggedIn = SupabaseClientManager.isLoggedIn;

    if (!isLoggedIn) {
      return const loginPage();
    }

    // Active session → check saved role for fast routing
    return FutureBuilder<String?>(
      future: _getSavedRole(),
      builder: (context, roleSnap) {
        // ── Loading ──
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(message: 'Loading your profile…');
        }

        // ── Error reading SharedPreferences ──
        if (roleSnap.hasError) {
          debugPrint('[AuthWrapper] _getSavedRole error: ${roleSnap.error}');
          // Treat as unauthenticated so the user can re-enter credentials.
          return const loginPage();
        }

        final savedRole = roleSnap.data;

        // No saved role → user never completed role selection.
        // Send them to GetStarted → ChooseProfession.
        if (savedRole == null || savedRole.isEmpty) {
          return const loginPage();
        }

        // ── Initialize profile from Supabase ──
        return FutureBuilder<void>(
          future: _initProfile(context),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold(message: 'Loading your profile…');
            }

            // ── Profile init error — show retry / login option ──
            if (profileSnap.hasError) {
              debugPrint('[AuthWrapper] _initProfile error: ${profileSnap.error}');
              return _ErrorScaffold(
                message: 'Could not load your profile. Please check your connection.',
                onRetry: () {
                  // Restart the app from the login page so the user can sign in again.
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const loginPage()),
                    (route) => false,
                  );
                },
              );
            }

            // Route to the correct dashboard based on saved role.
            if (savedRole == 'doctor') {
              return const DoctorBottomNavBar();
            }
            return const CustomBottomNavBar();
          },
        );
      },
    );
  }

  /// Returns the saved role from SharedPreferences, or null.
  /// Propagates any unexpected errors so [FutureBuilder] can surface them.
  Future<String?> _getSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role');
    } catch (e) {
      debugPrint('[AuthWrapper] _getSavedRole error: $e');
      rethrow;
    }
  }

  /// Initializes the profile from Supabase (once per session).
  /// Propagates errors so [FutureBuilder] can surface them.
  Future<void> _initProfile(BuildContext context) async {
    final profile = context.read<ProfileProvider>();
    if (!profile.profileExists && !profile.isLoaded) {
      await profile.initializeFromSupabase();
    }
  }
}

// ── Shared loading scaffold ──────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  final String message;
  const _LoadingScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF2EC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error scaffold with retry ────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF2EC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9C7C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
