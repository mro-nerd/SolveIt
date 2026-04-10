import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/clinical_notes_provider.dart';
import 'package:ace_mobile/features/doctor/doctor_bottom_navbar.dart';
import 'package:ace_mobile/features/doctor/doctor_dashboard_provider.dart';
import 'package:ace_mobile/features/doctor/screens/patient_detail_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DoctorDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ClinicalNotesProvider()),
      ],
      child: const _DoctorDashboardView(),
    );
  }
}

class _DoctorDashboardView extends StatefulWidget {
  const _DoctorDashboardView();

  @override
  State<_DoctorDashboardView> createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends State<_DoctorDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>().currentProfile;
      if (profile != null && profile['id'] != null) {
        final doctorId = profile['id'] as String;
        final provider = context.read<DoctorDashboardProvider>();
        provider.loadPatients(doctorId);
        provider.startListening();

        // Load clinical notes data
        final notesProvider = context.read<ClinicalNotesProvider>();
        notesProvider.loadParentList(doctorId);
        notesProvider.loadSentNotes(doctorId);
      }
    });
  }

  void _showAddPatientBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _AddPatientSheet(
            onLinkSuccess: () {
              Navigator.pop(ctx);
              final profile = context.read<ProfileProvider>().currentProfile;
              if (profile != null && profile['id'] != null) {
                context.read<DoctorDashboardProvider>().loadPatients(profile['id']);
              }
            },
          ),
        );
      },
    );
  }

  /// Navigate to the Patients tab (index 1) in the parent DoctorBottomNavBar.
  void _navigateToPatientsTab() {
    final navState = context.findAncestorStateOfType<DoctorBottomNavBarState>();
    navState?.switchToTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
            onPressed: _showAddPatientBottomSheet,
            tooltip: 'Add Patient',
          ),
        ],
      ),
      body: Consumer2<DoctorDashboardProvider, ClinicalNotesProvider>(
        builder: (context, provider, notesProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              final profile = context.read<ProfileProvider>().currentProfile;
              if (profile != null && profile['id'] != null) {
                final doctorId = profile['id'] as String;
                await provider.loadPatients(doctorId);
                await notesProvider.loadSentNotes(doctorId);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick Stats ─────────────────────────────────────
                    _QuickStatsGrid(provider: provider),
                    const SizedBox(height: 24),

                    // ── Clinical Note Composer ──────────────────────────
                    _NoteComposerCard(notesProvider: notesProvider),
                    const SizedBox(height: 24),

                    if (provider.isLoading)
                      const _LoadingSkeletons()
                    else if (provider.error != null)
                      Center(
                        child: Text(
                          'Error: ${provider.error}',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      )
                    else if (provider.patients.isEmpty)
                      _EmptyPatientsState()
                    else ...[
                      // ── Patient Activity Feed ─────────────────────────
                      _ActivityFeedSection(provider: provider),
                      const SizedBox(height: 24),

                      // ── Recent Patients ───────────────────────────────
                      Text(
                        'Recent Patients',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...provider.recentPatients.map(
                        (patient) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecentPatientCard(patient: patient),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── View All Patients → ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _navigateToPatientsTab,
                          icon: const Icon(Icons.people_rounded),
                          label: Text(
                            'View All Patients →',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: appColors.primary,
                            side: BorderSide(color: appColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Backfill AI Summaries ──────────────────────────
                      _BackfillSummariesButton(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Quick Stats Grid — 4 stat chips
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickStatsGrid extends StatelessWidget {
  final DoctorDashboardProvider provider;
  const _QuickStatsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatChip(
              title: 'Total Patients',
              value: '${provider.totalPatients}',
              icon: Icons.people_rounded,
              color: Colors.blue,
            ),
            const SizedBox(width: 10),
            _StatChip(
              title: 'This Week',
              value: '${provider.assessmentsThisWeek}',
              icon: Icons.assignment_turned_in_rounded,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatChip(
              title: 'High Risk',
              value: '${provider.highRiskCount}',
              icon: Icons.warning_rounded,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            _StatChip(
              title: 'Avg Score',
              value: provider.avgLastScore > 0
                  ? '${provider.avgLastScore.toStringAsFixed(0)}%'
                  : '—',
              icon: Icons.analytics_rounded,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Clinical Note Composer
// ═══════════════════════════════════════════════════════════════════════════════

class _NoteComposerCard extends StatefulWidget {
  final ClinicalNotesProvider notesProvider;
  const _NoteComposerCard({required this.notesProvider});

  @override
  State<_NoteComposerCard> createState() => _NoteComposerCardState();
}

class _NoteComposerCardState extends State<_NoteComposerCard> {
  final _messageController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final np = widget.notesProvider;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_note_rounded,
                        size: 20, color: appColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Notes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Send notes to patients',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Expandable composer body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Target type toggle
                  Row(
                    children: [
                      _TargetToggle(
                        label: 'All Patients',
                        isSelected: np.targetType == 'all',
                        onTap: () => np.setTargetType('all'),
                      ),
                      const SizedBox(width: 8),
                      _TargetToggle(
                        label: 'Specific Patient',
                        isSelected: np.targetType == 'specific',
                        onTap: () => np.setTargetType('specific'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Parent dropdown (specific only)
                  if (np.targetType == 'specific') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: np.selectedParentUid,
                          isExpanded: true,
                          hint: Text(
                            'Select patient\'s parent',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          items: np.parentList.map((parent) {
                            final childNames =
                                (parent['child_names'] as List)
                                    .join(', ');
                            return DropdownMenuItem<String>(
                              value: parent['parent_id'] as String,
                              child: Text(
                                '${parent['parent_name']} ($childNames)',
                                style: GoogleFonts.poppins(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => np.setSelectedParent(val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Message text field
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Write your clinical note...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: appColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    onChanged: (val) => np.setMessageText(val),
                  ),
                  const SizedBox(height: 12),

                  // Error / success feedback
                  if (np.sendError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        np.sendError!,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (np.sendSuccess)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            'Note sent successfully!',
                            style: GoogleFonts.poppins(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: np.isSending
                          ? null
                          : () {
                              final profile = context
                                  .read<ProfileProvider>()
                                  .currentProfile;
                              if (profile != null) {
                                np.setMessageText(_messageController.text);
                                np.sendNote(profile['id']).then((_) {
                                  if (np.sendSuccess) {
                                    _messageController.clear();
                                  }
                                });
                              }
                            },
                      icon: np.isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        np.isSending ? 'Sending...' : 'Send Note',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _TargetToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TargetToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? appColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? appColors.primary.withValues(alpha: 0.4)
                  : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? appColors.primary : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Patient Activity Feed
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivityFeedSection extends StatelessWidget {
  final DoctorDashboardProvider provider;
  const _ActivityFeedSection({required this.provider});

  String _formatSessionType(String? type) {
    switch (type) {
      case 'mchat':
        return 'M-CHAT';
      case 'emotion_assessment':
        return 'Emotion';
      case 'eye_contact':
        return 'Eye Contact';
      case 'imitation':
        return 'Imitation';
      default:
        return type?.split('_').map((w) =>
            w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ') ?? '';
    }
  }

  Color _getRiskColor(String? risk) {
    switch (risk) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRiskLabel(String? risk) {
    switch (risk) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Moderate';
      case 'low':
        return 'Low';
      default:
        return 'Pending';
    }
  }

  String _formatTimeAgo(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = provider.activityFeed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Patient Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            if (feed.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: appColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${feed.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (provider.isLoadingFeed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (feed.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.event_note_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No recent activity',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...feed.take(10).map((session) {
            final childName = session['child_name'] as String? ?? 'Unknown';
            final sessionType = session['session_type'] as String?;
            final score = (session['score'] as num?)?.toDouble();
            final riskFlag = session['risk_flag'] as String?;
            final completedAt = session['completed_at'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Risk indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getRiskColor(riskFlag),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  childName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(completedAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Session type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatSessionType(sessionType),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Score
                              if (score != null) ...[
                                Icon(Icons.trending_up_rounded,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${score.toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Risk badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(riskFlag)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getRiskLabel(riskFlag),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getRiskColor(riskFlag),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Supporting Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyPatientsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No patients linked yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ask a parent for their child's join code to get started",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeletons extends StatelessWidget {
  const _LoadingSkeletons();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _AddPatientSheet extends StatefulWidget {
  final VoidCallback onLinkSuccess;

  const _AddPatientSheet({required this.onLinkSuccess});

  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _linkPatient() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _errorMsg = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final profile = context.read<ProfileProvider>().currentProfile;
      if (profile == null || profile['id'] == null) {
        throw Exception('Doctor profile not found');
      }
      final success = await ChildService().assignDoctor(code, profile['id']);
      if (success) {
        widget.onLinkSuccess();
      } else {
        setState(() => _errorMsg = 'Code not found. Check again.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error linking patient. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Link New Patient',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Enter the 6-character join code provided by the patient\'s parent.',
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Join Code',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _errorMsg,
              prefixIcon: const Icon(Icons.link),
            ),
            onChanged: (v) {
              if (_errorMsg != null) setState(() => _errorMsg = null);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: appColors.primary,
            ),
            onPressed: _isLoading ? null : _linkPatient,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Link Patient',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

// ── Recent Patient Card ─────────────────────────────────────────────────────

class _RecentPatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _RecentPatientCard({required this.patient});

  String _formatDaysAgo(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '$diff days ago';
    } catch (_) {
      return '';
    }
  }

  int _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 0;
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'high': return Colors.red;
      case 'medium': return Colors.amber;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatSessionType(String? type) {
    if (type == null) return '';
    switch (type) {
      case 'mchat': return 'M-CHAT';
      case 'emotion_assessment': return 'Emotion';
      case 'eye_contact': return 'Eye Contact';
      case 'imitation': return 'Imitation';
      default:
        return type.split('_').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = patient['child_name'] ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final status = patient['diagnosis_status'] ?? 'pending';
    final session = patient['latest_session'];
    final sessionType = session?['session_type'] as String?;
    final sessionDate = session?['completed_at'] as String?;
    final age = _calculateAge(patient['date_of_birth']);

    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              patient: PatientData(
                name: name,
                age: age,
                diagnosis: status,
                lastVisit: session != null ? _formatDaysAgo(session['completed_at']) : 'None',
                status: 'Active',
                since: 'Recently',
                childId: patient['id'] as String?,
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (sessionType != null) ...[
                        Icon(Icons.assessment_outlined, size: 13, color: Colors.indigo.shade300),
                        const SizedBox(width: 4),
                        Text(
                          _formatSessionType(sessionType),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (sessionDate != null)
                        Text(
                          _formatDaysAgo(sessionDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Backfill AI Summaries Button
// ═══════════════════════════════════════════════════════════════════════════════

class _BackfillSummariesButton extends StatefulWidget {
  @override
  State<_BackfillSummariesButton> createState() =>
      _BackfillSummariesButtonState();
}

class _BackfillSummariesButtonState extends State<_BackfillSummariesButton> {
  bool _isRunning = false;
  int? _result;

  Future<void> _runBackfill() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backfilling AI summaries… This may take a moment.'),
        duration: Duration(seconds: 3),
      ),
    );

    final count = await AiSummaryService().backfillAll();

    if (mounted) {
      setState(() {
        _isRunning = false;
        _result = count;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Backfill complete: $count summaries generated.'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: _isRunning ? null : _runBackfill,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurple,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded,
                        size: 20, color: Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backfill AI Summaries',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      _result != null
                          ? '$_result summaries generated'
                          : 'Generate summaries for past sessions',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isRunning)
                Icon(Icons.play_arrow_rounded,
                    color: Colors.deepPurple.shade300, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

