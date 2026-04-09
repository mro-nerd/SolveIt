import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/loginPage.dart';
import 'package:ace_mobile/features/auth/role_selection_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {

  // ── Profile data from Supabase ──
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  // ── Edit mode ──
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = SupabaseClientManager.currentUser?.id;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await AuthService().fetchCurrentProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameCtrl.text = profile?['display_name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDisplayName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final uid = SupabaseClientManager.currentUser?.id;
      if (uid == null) throw Exception('Not signed in');

      await SupabaseClientManager.client
          .from('profiles')
          .update({'display_name': newName})
          .eq('id', uid);

      if (mounted) {
        setState(() {
          _profile?['display_name'] = newName;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: appColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ── Helpers ──
  String get _displayName =>
      _profile?['display_name'] as String? ?? 'Doctor';
  String get _email =>
      _profile?['email'] as String? ?? '';
  String get _role =>
      _profile?['role'] as String? ?? 'doctor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Header ──
                Row(
                  children: [
                    Text(
                      'Profile & Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    // Edit / Save button
                    if (!_isLoading && _profile != null)
                      _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: () {
                                if (_isEditing) {
                                  _saveDisplayName();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              icon: Icon(
                                _isEditing
                                    ? Icons.check_rounded
                                    : Icons.edit_rounded,
                                size: 18,
                                color: appColors.primary,
                              ),
                              label: Text(
                                _isEditing ? 'Save' : 'Edit',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: appColors.primary,
                                ),
                              ),
                            ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Loading / Error states ──
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade300, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // ── Avatar & Name ──
                  _buildProfileHeader(context),
                  const SizedBox(height: 28),

                  // ── Stats ──
                  Row(
                    children: [
                      _ProfileStat(value: '42', label: 'Patients'),
                      _ProfileStat(value: '4.9', label: 'Rating'),
                      _ProfileStat(value: '15', label: 'Exp. Years'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Notification Preferences ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Notification Preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _NotificationToggle(
                    title: 'Appointment Reminders',
                    subtitle: 'Get notified for upcoming cases',
                    value: true,
                  ),
                  _NotificationToggle(
                    title: 'Patient Messages',
                    subtitle: 'Direct messages from parents',
                    value: true,
                  ),
                  _NotificationToggle(
                    title: 'Lab Results',
                    subtitle: 'Automated patient check',
                    value: false,
                  ),
                  const SizedBox(height: 28),

                  // ── General Settings ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'General Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _SettingsItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy & Security',
                  ),
                  _SettingsItem(
                    icon: Icons.share_outlined,
                    title: 'Data Sharing Policies',
                  ),
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                  ),
                  // ── Switch Role ──
                  GestureDetector(
                    onTap: () {
                      final profile = Provider.of<ProfileProvider>(
                        context,
                        listen: false,
                      );
                      profile.updateUserRole('');
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const RoleSelectionScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 400),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF7C3AED)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sign in as Parent',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Log Out ──
                  GestureDetector(
                    onTap: () => _handleLogout(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFDC2626).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDC2626)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Log Out',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Version ──
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile Header (avatar + name/email/role) ──
  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: appColors.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: appColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Display Name (editable) ──
        if (_isEditing)
          SizedBox(
            width: 260,
            child: TextField(
              controller: _nameCtrl,
              textAlign: TextAlign.center,
              autofocus: true,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF9CA3AF),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: appColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: appColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          )
        else
          Text(
            _displayName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),

        const SizedBox(height: 4),

        // ── Role badge ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _role[0].toUpperCase() + _role.substring(1),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF0284C7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // ── Email ──
        if (_email.isNotEmpty)
          Text(
            _email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    // 1. Clear all cached profile / SharedPreferences state
    await context.read<ProfileProvider>().clearAll();

    // 2. Sign out from Supabase
    await AuthService().signOut();

    // 3. Navigate to the Get Started screen, removing all routes
    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const loginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }
}

// ── Profile Stat ──────────────────────────────────────────────────────────────

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Toggle ───────────────────────────────────────────────────────

class _NotificationToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isOn,
              onChanged: (v) => setState(() => _isOn = v),
              activeColor: appColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Item ─────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SettingsItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
