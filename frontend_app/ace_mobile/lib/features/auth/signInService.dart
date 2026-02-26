import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on PlatformException catch (e) {
      developer.log(
        'Google Sign-In PlatformException: ${e.code} - ${e.message}',
        name: 'GoogleAuthService',
      );
      return null;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth Error: ${e.code} - ${e.message}',
        name: 'GoogleAuthService',
      );
      return null;
    } catch (e) {
      developer.log(
        'Sign-In unexpected error: $e',
        name: 'GoogleAuthService',
      );
      return null;
    }
  }
}
