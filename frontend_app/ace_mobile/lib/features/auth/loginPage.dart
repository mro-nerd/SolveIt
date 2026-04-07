import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/role_selection_screen.dart';
import 'package:flutter/material.dart';

class loginPage extends StatelessWidget {
  const loginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: appSize.defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              // ── ACE branding ──
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              // ── Poster image ──
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
              const SizedBox(height: 25),
              // ── Tagline ──
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  children: [
                    const TextSpan(text: "Every Child\nDeserves "),
                    TextSpan(
                      text: "Early\nCare",
                      style: TextStyle(color: textColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                textAlign: TextAlign.center,
                "Empowering families with clinical autism screening and therapy integration.",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              // ── Get Started button (navigates to role selection, NO sign-in) ──
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            const RoleSelectionScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration:
                            const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  label: Row(
                    children: [
                      const Spacer(),
                      Text(
                        "Get Started",
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Icon(
                        Icons.arrow_circle_right_rounded,
                        color: textColors.tertiary,
                        size: 26,
                      ),
                      const Spacer(),
                    ],
                  ),
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStatePropertyAll(appColors.primary),
                    shadowColor:
                        WidgetStatePropertyAll(appColors.primary),
                    elevation: const WidgetStatePropertyAll(2),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // ── Footer ──
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: Divider(
                  color: Colors.blueGrey.withValues(alpha: 0.6),
                  thickness: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                textAlign: TextAlign.center,
                "Available in 27 languages",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
