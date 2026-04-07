import 'package:ace_mobile/features/doctor/doctor_bottom_navbar.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ace_mobile/features/auth/loginPage.dart';
import 'package:ace_mobile/shared/BottomNavbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides where the app lands after the splash screen.
///
/// • Active Firebase session + saved role → correct dashboard (fast path)
/// • Otherwise → [loginPage] (GetStarted → ChooseProfession)
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
            backgroundColor: Color(0xFFDFF2EC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // No active Firebase session → GetStarted
        if (!snapshot.hasData) {
          return const loginPage();
        }

        final firebaseUser = snapshot.data!;

        // Active session → check saved role for fast routing
        return FutureBuilder<String?>(
          future: _getSavedRole(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
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

            final savedRole = roleSnap.data;

            // No saved role → user never completed role selection
            // Send them to GetStarted → ChooseProfession
            if (savedRole == null || savedRole.isEmpty) {
              return const loginPage();
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

                // Route to the correct dashboard based on saved role
                if (savedRole == 'doctor') {
                  return const DoctorBottomNavBar();
                }
                return const CustomBottomNavBar();
              },
            );
          },
        );
      },
    );
  }

  /// Returns the saved role from SharedPreferences, or null.
  Future<String?> _getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  /// Initializes the profile from Supabase (once per session).
  Future<void> _initProfile(BuildContext context, User firebaseUser) async {
    final profile = context.read<ProfileProvider>();
    if (!profile.profileExists && !profile.isLoaded) {
      await profile.initializeFromFirebase(firebaseUser);
    }
  }
}
