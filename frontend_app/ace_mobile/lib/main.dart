import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/auth_wrapper.dart'; // Added AuthWrapper
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Cleaner UI
      title: 'ACE Mobile',
      theme: appTheme.lightTheme,
      home: const AuthWrapper(), // 🚀 Now gated by Auth State
    );
  }
}
