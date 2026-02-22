import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/signInService.dart';
// import 'package:ace_mobile/shared/BottomNavbar.dart'; // Removed
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: appSize.defaultPadding),
          child: Column(
            children: [
              Spacer(),
              //heading text
              Text(
                "ACE",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Autism Care & Engagement",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 25),
              //image
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 10),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/poster.png",
                    scale: 1.2,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 25),
              //text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  children: [
                    TextSpan(text: "Every Child\nDeserves "),
                    TextSpan(
                      text: "Early\nCare",
                      style: TextStyle(color: textColors.secondary),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              //text
              Text(
                textAlign: TextAlign.center,
                "Empowering families with clinical autism screening and therapy integration.",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 20),
              //login button
              googleSignInButton(),
              Spacer(),
              //divider
              Container(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: Divider(
                  color: Colors.blueGrey.withValues(alpha: 0.6),
                  thickness: 0.5,
                ),
              ),
              SizedBox(height: 6),
              //text
              Text(
                textAlign: TextAlign.center,
                "Available in 27 languages",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class googleSignInButton extends StatefulWidget {
  const googleSignInButton({super.key});

  @override
  State<googleSignInButton> createState() => _googleSignInButtonState();
}

class _googleSignInButtonState extends State<googleSignInButton> {
  bool isLoading = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      child: TextButton.icon(
        onPressed: () async {
          setState(() => isLoading = true);
          try {
            final user = await _googleAuthService.signInWithGoogle();
            if (user == null) {
              // User cancelled login or something went wrong
              setState(() => isLoading = false);
            }
          } catch (e) {
            setState(() => isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
            }
          }
        },
        label: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                children: [
                  Spacer(),
                  Text(
                    "Get Started",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColors.tertiary,
                    ),
                  ),
                  SizedBox(width: 15),
                  Icon(
                    Icons.arrow_circle_right_rounded,
                    color: textColors.tertiary,
                    size: 26,
                  ),
                  Spacer(),
                ],
              ),

        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(appColors.primary),
          shadowColor: WidgetStatePropertyAll(appColors.primary),
          elevation: WidgetStatePropertyAll(2),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    );
  }
}
