import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/assessment/providers/assessment_provider.dart';
import 'package:ace_mobile/features/assessment/providers/mchat_ai_provider.dart';
import 'package:ace_mobile/features/auth/auth_wrapper.dart'; // Added AuthWrapper
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => MchatAiProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ACE Mobile',
        theme: appTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}
