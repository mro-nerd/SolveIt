import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/assessment/screens/assessment_intro_screen.dart';
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
import 'package:intl/intl.dart';
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

                // ── Clinical Notes (real data from Supabase) ──────────────
                _ClinicalNotesSection(
                  parentUid: profile.currentProfile?['id'] as String?,
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

// ── Status Card (with M-CHAT gate) ─────────────────────────────────────────

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

    // ── M-CHAT gate: Show prompt if no M-CHAT session exists ────────────
    if (!progress.hasMchatSession) {
      return _MchatPromptCard();
    }

    // ── M-CHAT exists: show real data ───────────────────────────────────
    final risk = progress.latestMchatRiskFlag ?? progress.overallRisk;
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

// ── M-CHAT Prompt Card ─────────────────────────────────────────────────────

class _MchatPromptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            appColors.primary.withValues(alpha: 0.08),
            appColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: appColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: appColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete the M-CHAT Screening',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the M-CHAT screening to see your child\'s summary and risk assessment here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColors.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const AssessmentIntroScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'Start M-CHAT Screening',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clinical Notes Section (real data) ─────────────────────────────────────

class _ClinicalNotesSection extends StatefulWidget {
  final String? parentUid;
  const _ClinicalNotesSection({this.parentUid});

  @override
  State<_ClinicalNotesSection> createState() => _ClinicalNotesSectionState();
}

class _ClinicalNotesSectionState extends State<_ClinicalNotesSection> {
  final ClinicalNotesService _service = ClinicalNotesService();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void didUpdateWidget(covariant _ClinicalNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentUid != widget.parentUid) {
      _loadNotes();
    }
  }

  Future<void> _loadNotes() async {
    if (widget.parentUid == null || widget.parentUid!.isEmpty) {
      setState(() {
        _notes = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notes = await _service.getNotesForParent(widget.parentUid!);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[_ClinicalNotesSection] Error: $e');
      if (mounted) {
        setState(() {
          _notes = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, y').format(date);
    } catch (_) {
      return '';
    }
  }

  String _getDoctorName(Map<String, dynamic> note) {
    final profiles = note['profiles'];
    if (profiles is Map) {
      return profiles['display_name'] as String? ?? 'Your Doctor';
    }
    return 'Your Doctor';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services_outlined,
                size: 18, color: appColors.primary),
            const SizedBox(width: 8),
            Text(
              'From Your Doctor',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_notes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 32, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'No clinical notes yet.\nYour doctor\'s messages will appear here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColors.secondary.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Most recent note — prominently displayed
          _ClinicalNoteCard(
            note: _notes.first,
            doctorName: _getDoctorName(_notes.first),
            dateText: _formatDate(_notes.first['created_at'] as String?),
            isLatest: true,
          ),

          // Older notes
          if (_notes.length > 1) ...[
            const SizedBox(height: 8),
            if (_showAll)
              ..._notes.skip(1).map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ClinicalNoteCard(
                  note: note,
                  doctorName: _getDoctorName(note),
                  dateText: _formatDate(note['created_at'] as String?),
                  isLatest: false,
                ),
              ))
            else if (_notes.length > 1)
              GestureDetector(
                onTap: () => setState(() => _showAll = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      'View ${_notes.length - 1} older note${_notes.length - 1 > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}

class _ClinicalNoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final String doctorName;
  final String dateText;
  final bool isLatest;

  const _ClinicalNoteCard({
    required this.note,
    required this.doctorName,
    required this.dateText,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final message = note['message'] as String? ?? '';
    final targetType = note['target_type'] as String? ?? 'all';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isLatest ? 24 : 16),
        color: Colors.white,
        border: isLatest
            ? Border.all(
                color: appColors.primary.withValues(alpha: 0.15),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLatest) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: appColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medical_services,
                      size: 14, color: appColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                doctorName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (targetType == 'all') ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Broadcast',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                dateText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColors.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            softWrap: true,
            maxLines: isLatest ? 6 : 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColors.secondary,
              height: 1.5,
            ),
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
