import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ace_mobile/features/auth/loginPage.dart';
import 'package:ace_mobile/shared/BottomNavbar.dart';

/// The AuthWrapper is a "gatekeeper" widget.
/// It listens to the Firebase Auth state and decides which screen to show.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a StreamBuilder to listen to 'authStateChanges'.
    // This stream sends a new 'User' object whenever someone logs in or out.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If the connection is still starting, show a loading circle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If 'snapshot.hasData' is true, it means there is a logged-in User.
        // We take them straight to the main app dashboard.
        if (snapshot.hasData) {
          return const CustomBottomNavBar();
        }

        // 3. Otherwise, the user is NOT logged in. Show the Get Started / Login page.
        return const loginPage();
      },
    );
  }
}
