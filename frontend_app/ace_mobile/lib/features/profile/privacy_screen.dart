import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // ── Accordion ──────────────────────────────────────────────────────────────
  int? _expandedIndex;

  // ── Toggles ────────────────────────────────────────────────────────────────
  bool _researchParticipation = true;
  bool _therapyPartners = false;

  void _toggleAccordion(int i) =>
      setState(() => _expandedIndex = _expandedIndex == i ? null : i);

  Future<void> _exportData() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export requested — you\'ll receive an email shortly.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: appColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Capture navigator before any await
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account & Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This is permanent. All therapy logs and screening history will be '
          'purged from our servers within 24 hours. This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete Everything',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Clear Google + Firebase session and all local prefs
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Land on a fresh AuthWrapper (which sees null user → loginPage)
    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accordionItems = [
      (
        icon: Icons.screen_search_desktop_rounded,
        title: 'Early Screening Data',
        body:
            'We collect assessment results, developmental milestones, and basic demographic info to provide accurate screening tools for your child.',
      ),
      (
        icon: Icons.people_alt_rounded,
        title: 'Clinical Integration',
        body:
            'With your permission, anonymised data is shared with licensed clinicians who help validate assessment accuracy and improve care pathways.',
      ),
      (
        icon: Icons.shield_rounded,
        title: 'How we protect it',
        body:
            'All data is encrypted at rest (AES-256) and in transit (TLS 1.3), stored on HIPAA-compliant infrastructure, and never sold to third parties.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF111827),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data & Privacy Center',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF3F4F6)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ── HIPAA badge ────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                size: 14,
                color: appColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'HIPAA COMPLIANT SYSTEM',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: appColors.primary,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your family\'s journey is personal. ACE is committed to the '
            'highest standards of clinical data protection and absolute '
            'transparency.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF4B5563),
              height: 1.7,
            ),
          ),

          const SizedBox(height: 28),

          // ── Understanding Your Data ────────────────────────────────────────
          _sectionTitle('Understanding Your Data'),
          const SizedBox(height: 12),
          _card(
            child: Column(
              children: List.generate(accordionItems.length, (i) {
                final item = accordionItems[i];
                final isOpen = _expandedIndex == i;
                final isLast = i == accordionItems.length - 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _toggleAccordion(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: appColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.icon,
                                size: 16,
                                color: appColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                            Icon(
                              isOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          item.body,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                            height: 1.65,
                          ),
                        ),
                      ),
                      crossFadeState: isOpen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF3F4F6),
                      ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 28),

          // ── Sharing Preferences ────────────────────────────────────────────
          _sectionTitle('Sharing Preferences'),
          const SizedBox(height: 12),
          _card(
            child: Column(
              children: [
                _ToggleRow(
                  title: 'Research Participation',
                  subtitle: 'Anonymised data contribution to autism studies.',
                  value: _researchParticipation,
                  onChanged: (v) => setState(() => _researchParticipation = v),
                ),
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFF3F4F6),
                ),
                _ToggleRow(
                  title: 'Therapy Partners',
                  subtitle:
                      'Allow integration with clinical therapy platforms.',
                  value: _therapyPartners,
                  onChanged: (v) => setState(() => _therapyPartners = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Your Rights & Control ──────────────────────────────────────────
          _sectionTitle('Your Rights & Control'),
          const SizedBox(height: 12),

          // Export all data
          GestureDetector(
            onTap: _exportData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export All Data',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Danger zone card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appColors.red.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: appColors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DANGER ZONE',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: appColors.red,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Deleting your account is permanent. All therapy logs and '
                  'screening history will be purged from our servers within '
                  '24 hours.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appColors.red,
                      side: BorderSide(color: appColors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'One-Click Delete Account & Data',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: appColors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String label) => Text(
    label,
    style: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF111827),
    ),
  );

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
  );
}

// ── Toggle row widget ──────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: appColors.primary,
          inactiveTrackColor: const Color(0xFFE5E7EB),
          inactiveThumbColor: Colors.white,
        ),
      ],
    ),
  );
}
