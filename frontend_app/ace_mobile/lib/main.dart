import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/assessment/providers/assessment_provider.dart';
import 'package:ace_mobile/features/assessment/providers/mchat_ai_provider.dart';
import 'package:ace_mobile/features/auth/auth_wrapper.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  // Pre-load profile prefs so the data is available immediately
  final profileProvider = ProfileProvider();
  await profileProvider.loadFromPrefs();

  runApp(MyApp(profileProvider: profileProvider));
}

class MyApp extends StatelessWidget {
  final ProfileProvider profileProvider;
  const MyApp({super.key, required this.profileProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profileProvider),
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
