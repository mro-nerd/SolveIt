import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/emotion_assessment/emotion_assessment_screen.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_screen.dart';
import 'package:ace_mobile/features/imitation/imitation_provider.dart';
import 'package:ace_mobile/features/imitation/imitation_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:ace_mobile/features/profile/profile_screen.dart';
import 'package:ace_mobile/features/therapy/therapy_checklist_card.dart';
import 'package:ace_mobile/features/progress/progress_provider.dart';
import 'package:ace_mobile/shared/ProgressCard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  String? _previousChildId;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void initState() {
    super.initState();
    // Auto-load sessions so the ProgressGraphCard shows real data on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousChildId =
          context.read<ProfileProvider>().currentChild?['id'] as String?;
      _loadSessions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect child switch and re-fetch data
    final currentChildId =
        context.read<ProfileProvider>().currentChild?['id'] as String?;
    if (_previousChildId != null &&
        currentChildId != null &&
        currentChildId != _previousChildId) {
      _previousChildId = currentChildId;
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    final profile = context.read<ProfileProvider>();
    final childId = profile.currentChild?['id'] as String?;
    final diagnosis =
        profile.currentChild?['diagnosis_status'] as String? ?? 'pending';
    if (childId != null && childId.isNotEmpty) {
      _previousChildId = childId;
      await context
          .read<ProgressProvider>()
          .loadSessions(childId, diagnosisStatus: diagnosis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        color: appColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    // ── Child switcher / static name ──────────────────────
                    Expanded(
                      child: Column(
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
                          if (profile.hasMultipleChildren)
                            // Dropdown when >1 child
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: profile.currentChild?['id'] as String?,
                                isDense: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 22,
                                ),
                                items: profile.children.map((child) {
                                  return DropdownMenuItem<String>(
                                    value: child['id'] as String,
                                    child: Text(
                                      child['child_name'] ?? 'Unnamed',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.85),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (id) {
                                  if (id == null) return;
                                  final selected = profile.children.firstWhere(
                                    (c) => c['id'] == id,
                                  );
                                  profile.switchChild(selected);
                                  _loadSessions();
                                },
                              ),
                            )
                          else
                            // Static name when 1 child
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
                    ),
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
                      DiagnosisCard(
                        title: 'Sensory',
                        icon: Icons.sensors,
                        onTap: () =>
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => const EmotionAssessmentScreen(),
                              ),
                            ),
                      ),
                      DiagnosisCard(
                        title: 'Imitation',
                        icon: Icons.accessibility_new,
                        onTap: () =>
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => ImitationProvider(),
                                  child: const ImitationScreen(),
                                ),
                              ),
                            ),
                      ),
                      DiagnosisCard(
                        title: 'Social\nSkills',
                        icon: Icons.people,
                      ),
                      DiagnosisCard(title: 'Behavior', icon: Icons.psychology),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Therapy checklist (realtime) ───────────────────────────
                Builder(builder: (context) {
                  final childId =
                      profile.currentChild?['id'] as String? ?? '';
                  if (childId.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TherapyChecklistCard(childId: childId),
                    );
                  }
                  return const SizedBox.shrink();
                }),

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
      ),
    );
  }
}

// ── Status Card ────────────────────────────────────────────────────────────────

class statusCard extends StatelessWidget {
  const statusCard({super.key});

  String _riskLabel(String risk) {
    switch (risk) {
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Moderate Risk';
      case 'low':
        return 'Low Risk';
      default:
        return 'Pending';
    }
  }

  Color _riskBgColor(String risk) {
    switch (risk) {
      case 'high':
        return const Color(0xFFFEE2E2);
      case 'medium':
        return const Color(0xFFFEF3C7);
      case 'low':
        return const Color(0xFFD1FAE5);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _riskTextColor(String risk) {
    switch (risk) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _summaryHeadline(String risk, double? avgScore) {
    if (avgScore == null) return 'No Data Yet';
    if (avgScore >= 75) return 'Great Progress!';
    if (avgScore >= 50) return 'Improving';
    if (avgScore >= 30) return 'Needs Attention';
    return 'Needs Support';
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final risk = progress.overallRisk;
    final avgScore = progress.averageLatestScore;
    final sessions = progress.allSessionsSorted;
    // Use the latest session's ai_summary if available
    final latestSummary = sessions.isNotEmpty
        ? sessions.first['ai_summary'] as String?
        : null;
    final summaryText = latestSummary != null && latestSummary.isNotEmpty
        ? latestSummary
        : avgScore != null
            ? 'Average score: ${avgScore.toStringAsFixed(0)}% across ${sessions.length} sessions. Keep going!'
            : 'Complete your first assessment to see a personalized summary here.';

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
                    _summaryHeadline(risk, avgScore),
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
                  color: _riskBgColor(risk),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _riskLabel(risk),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _riskTextColor(risk),
                  ),
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
                  summaryText,
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
