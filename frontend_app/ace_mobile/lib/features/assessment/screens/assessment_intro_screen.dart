import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import 'question_screen.dart';

/// Landing screen for the M-CHAT-R questionnaire.
/// Shows title, description, and start/resume controls.
class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: appColors.background,
            body: Center(
              child: CircularProgressIndicator(color: appColors.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: appColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [appColors.primary, Color(0xFF1A5C47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: appColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'M-CHAT-R\nScreening',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B3C),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Modified Checklist for Autism in Toddlers, Revised',
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.secondary.withValues(alpha: 0.65),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info cards
                  _InfoCard(
                    icon: Icons.quiz_outlined,
                    color: const Color(0xFF3B82F6),
                    title: '20 Questions',
                    subtitle: 'One question per screen',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF8B5CF6),
                    title: '5–10 Minutes',
                    subtitle: 'Estimated completion time',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.save_outlined,
                    color: appColors.green,
                    title: 'Auto-saved',
                    subtitle: 'Resume any time where you left off',
                  ),
                  const SizedBox(height: 32),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF97316).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF97316),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This screening tool is for informational purposes only and does not constitute a medical diagnosis. Always consult a qualified healthcare professional.',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF92400E,
                              ).withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Resume banner (shown when a session exists)
                  if (provider.hasSavedSession) ...[
                    _ResumeBanner(provider: provider),
                    const SizedBox(height: 16),
                  ],

                  // Start / Fresh start button
                  _PrimaryButton(
                    label: provider.hasSavedSession
                        ? 'Start New Assessment'
                        : 'Start Assessment',
                    icon: Icons.play_arrow_rounded,
                    onTap: () async {
                      await provider.startFresh();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          _slideRoute(const QuestionScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  final AssessmentProvider provider;
  const _ResumeBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final answered = provider.answers.length;
    return GestureDetector(
      onTap: () {
        provider.resumeSession();
        Navigator.push(context, _slideRoute(const QuestionScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: appColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.restore_rounded, color: appColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume saved session',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: appColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$answered of 20 questions answered',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: appColors.primary),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.secondary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [appColors.primary, Color(0xFF1A5C47)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
