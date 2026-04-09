import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
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
    return ChangeNotifierProvider(
      create: (_) => DoctorDashboardProvider(),
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
        final provider = context.read<DoctorDashboardProvider>();
        provider.loadPatients(profile['id']);
        provider.startListening();
      }
    });
  }

  @override
  void dispose() {
    // Provider is scoped to this widget tree via ChangeNotifierProvider,
    // so its own dispose() handles stream cleanup.
    super.dispose();
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
      body: Consumer<DoctorDashboardProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              final profile = context.read<ProfileProvider>().currentProfile;
              if (profile != null && profile['id'] != null) {
                await provider.loadPatients(profile['id']);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary Stat Cards ────────────────────────────────
                    Row(
                      children: [
                        _SummaryChip(
                          title: 'Total Patients',
                          value: '${provider.totalPatients}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          title: 'Sessions Today',
                          value: '${provider.sessionsToday}',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          title: 'High Risk',
                          value: '${provider.highRiskThisWeek}',
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

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
                      Center(
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
                      )
                    else ...[
                      // ── Recent Patients section ────────────────────────
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

                      // ── View All Patients → ────────────────────────────
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

class _SummaryChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
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
        Navigator.push(
          context,
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
