import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:ace_mobile/features/profile/profile_screen.dart';
import 'package:ace_mobile/shared/ProgressCard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Row(
                  children: [
                    // Avatar → navigate to ProfileScreen
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                      child: Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: appColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: profile.avatarImage,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARING FOR',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.6),
                                fontSize: 11,
                                letterSpacing: 1.0,
                              ),
                        ),
                        Text(
                          profile.displayChildName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.85),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: appColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── Salutation ─────────────────────────────────────────────
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.black),
                        ),
                        Text(
                          profile.displayParentName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Status card ────────────────────────────────────────────
                statusCard(),
                const SizedBox(height: 20),

                // ── Scrollable diagnosis cards ─────────────────────────────
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      DiagnosisCard(
                        title: 'Speech\nDelay',
                        icon: Icons.record_voice_over,
                      ),
                      DiagnosisCard(
                        title: 'Eye\nContact',
                        icon: Icons.visibility,
                        onTap: () =>
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => const EyeContactScreen(),
                              ),
                            ),
                      ),
                      DiagnosisCard(title: 'Sensory', icon: Icons.sensors),
                      DiagnosisCard(
                        title: 'Social\nSkills',
                        icon: Icons.people,
                      ),
                      DiagnosisCard(title: 'Behavior', icon: Icons.psychology),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ProgressGraphCard(),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ' Recent Clinical Notes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Clinical note ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Dr. Adarsh Sen',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            'Feb 20, 2026',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColors.secondary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        softWrap: true,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        'Showing great progress in assessments, 30% improvement in eye contact, next Screening due in 12 days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status Card ────────────────────────────────────────────────────────────────

class statusCard extends StatefulWidget {
  const statusCard({super.key});

  @override
  State<statusCard> createState() => _statusCardState();
}

class _statusCardState extends State<statusCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Summary",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColors.secondary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Great!!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: appColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Moderate Risk',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  'Showing great progress in assessments, 30% improvement in eye contact, next Screening due in 12 days',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: textColors.secondary),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: appColors.primary.withValues(alpha: 0.3),
                      blurRadius: 3,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_sharp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Diagnosis Card ─────────────────────────────────────────────────────────────

class DiagnosisCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const DiagnosisCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          border: onTap != null
              ? Border.all(
                  color: appColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appColors.background,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, size: 28, color: appColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
