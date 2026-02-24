import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/assessment/providers/assessment_provider.dart';
import 'package:ace_mobile/features/assessment/providers/mchat_ai_provider.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_provider.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:ace_mobile/features/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        // ProfileProvider is created here; SplashScreen will call loadFromPrefs
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => MchatAiProvider()),
        ChangeNotifierProvider(create: (_) => EyeContactProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ACE Mobile',
        theme: appTheme.lightTheme,
        // SplashScreen is the entry point; it hands off to AuthWrapper
        home: const SplashScreen(),
        routes: {
          '/eye-contact': (_) => const EyeContactScreen(),
        },
      ),
    );
  }
}
