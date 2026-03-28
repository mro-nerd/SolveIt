import 'package:ace_mobile/features/auth/role_selection_screen.dart';
import 'package:ace_mobile/features/doctor/doctor_bottom_navbar.dart';
import 'package:ace_mobile/features/onboarding/onboarding_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ace_mobile/features/auth/loginPage.dart';
import 'package:ace_mobile/shared/BottomNavbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still connecting to Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in → show login
        if (!snapshot.hasData) {
          return const loginPage();
        }

        final firebaseUser = snapshot.data!;

        // Logged in → check if onboarding has been seen
        return FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, onboardingSnap) {
            if (onboardingSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFDFF2EC),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasSeenOnboarding = onboardingSnap.data ?? false;

            // First login → show onboarding before main app
            if (!hasSeenOnboarding) {
              return const OnboardingScreen();
            }

            // ── Initialize profile from Supabase ──
            return FutureBuilder<void>(
              future: _initProfile(context, firebaseUser),
              builder: (context, profileSnap) {
                if (profileSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFFDFF2EC),
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading your profile…',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final profile = context.watch<ProfileProvider>();

                // No Supabase profile yet (first login) → role selection
                if (!profile.profileExists && !profile.hasSelectedRole) {
                  return const RoleSelectionScreen();
                }

                // Route based on role
                if (profile.isDoctor) {
                  return const DoctorBottomNavBar();
                }

                // Default: parent flow
                return const CustomBottomNavBar();
              },
            );
          },
        );
      },
    );
  }

  /// Initializes the profile from Supabase. This is called once
  /// when the user is logged in and onboarding is done.
  Future<void> _initProfile(BuildContext context, User firebaseUser) async {
    final profile = context.read<ProfileProvider>();
    // Only initialize once per app session
    if (!profile.profileExists && !profile.isLoaded) {
      await profile.initializeFromFirebase(firebaseUser);
    }
  }

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done') ?? false;
  }
}
