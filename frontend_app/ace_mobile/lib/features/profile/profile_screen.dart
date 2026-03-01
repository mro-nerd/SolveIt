import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/auth_wrapper.dart';
import 'package:ace_mobile/features/auth/role_selection_screen.dart';
import 'package:ace_mobile/features/profile/privacy_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // controllers
  late TextEditingController _parentNameCtrl;
  late TextEditingController _parentEmailCtrl;
  late TextEditingController _childNameCtrl;
  late TextEditingController _childDobCtrl;
  late TextEditingController _childDiagnosisCtrl;

  String? _selectedGender;
  bool _editing = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();
    _parentNameCtrl = TextEditingController(text: p.parentName);
    _parentEmailCtrl = TextEditingController(text: p.parentEmail);
    _childNameCtrl = TextEditingController(text: p.childName);
    _childDobCtrl = TextEditingController(text: p.childDob);
    _childDiagnosisCtrl = TextEditingController(text: p.childDiagnosis);
    _selectedGender = p.childGender.isNotEmpty ? p.childGender : null;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _parentNameCtrl.dispose();
    _parentEmailCtrl.dispose();
    _childNameCtrl.dispose();
    _childDobCtrl.dispose();
    _childDiagnosisCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Photo picker ─────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
      await context.read<ProfileProvider>().updatePhotoPath(picked.path);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final p = context.read<ProfileProvider>();
    
    // Update local preferences and state first (without triggering individual syncs)
    await p.updateParentName(_parentNameCtrl.text.trim(), sync: false);
    await p.updateParentEmail(_parentEmailCtrl.text.trim(), sync: false);
    await p.updateChildName(_childNameCtrl.text.trim(), sync: false);
    await p.updateChildDob(_childDobCtrl.text.trim(), sync: false);
    await p.updateChildGender(_selectedGender ?? '', sync: false);
    await p.updateChildDiagnosis(_childDiagnosisCtrl.text.trim(), sync: false);
    
    // Trigger a single sync to Supabase once all state is updated
    await p.syncToSupabase();
    
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile saved!',
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
  }

  // ── Switch role ────────────────────────────────────────────────────────────
  void _switchRole() {
    final profile = context.read<ProfileProvider>();
    profile.updateUserRole('');
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    // ⚠️ Capture the ROOT navigator BEFORE any await.
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(),
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
            child: Text('Sign Out', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Clear onboarding flag so next login sees onboarding again
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');

    // Sign out from both Firebase and Google
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    // Remove every route and land on AuthWrapper which now shows loginPage.
    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const _AuthWrapperRedirect(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: appColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ─────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              floating: false,
              pinned: true,
              backgroundColor: appColors.primary,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    if (_editing) {
                      _save();
                    } else {
                      setState(() => _editing = true);
                    }
                  },
                  icon: Icon(
                    _editing ? Icons.check_rounded : Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _editing ? 'Save' : 'Edit',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A5C44),
                        Color(0xFF2D7B60),
                        Color(0xFF3DA882),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundImage:
                                    firebaseUser?.photoURL != null &&
                                        (profile.photoPath == null)
                                    ? NetworkImage(firebaseUser!.photoURL!)
                                          as ImageProvider
                                    : profile.avatarImage,
                              ),
                            ),
                            GestureDetector(
                              onTap: _pickPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: appColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.displayParentName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile.parentEmail.isNotEmpty
                              ? profile.parentEmail
                              : (firebaseUser?.email ?? ''),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Caring for ${profile.displayChildName}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parent section
                      _SectionHeader(
                        icon: Icons.person_rounded,
                        label: 'Parent / Guardian',
                      ),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _Field(
                            label: 'Full Name',
                            icon: Icons.badge_rounded,
                            controller: _parentNameCtrl,
                            enabled: _editing,
                            hint: 'e.g. Sarah Johnson',
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter your name'
                                : null,
                          ),
                          _divider(),
                          _Field(
                            label: 'Email',
                            icon: Icons.email_rounded,
                            controller: _parentEmailCtrl,
                            enabled: _editing,
                            hint: 'your@email.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Child section
                      _SectionHeader(
                        icon: Icons.child_care_rounded,
                        label: 'Child Details',
                      ),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _Field(
                            label: 'Child\'s Name',
                            icon: Icons.face_rounded,
                            controller: _childNameCtrl,
                            enabled: _editing,
                            hint: 'e.g. Diego',
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter child\'s name'
                                : null,
                          ),
                          _divider(),
                          _Field(
                            label: 'Date of Birth',
                            icon: Icons.cake_rounded,
                            controller: _childDobCtrl,
                            enabled: _editing,
                            hint: 'DD / MM / YYYY',
                            keyboardType: TextInputType.datetime,
                            onTap: _editing ? () => _pickDate() : null,
                            readOnly: true,
                          ),
                          _divider(),
                          // Gender picker
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wc_rounded,
                                  size: 20,
                                  color: appColors.primary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gender',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: const Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _editing
                                          ? DropdownButtonFormField<String>(
                                              value: _selectedGender,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              hint: Text(
                                                'Select gender',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ),
                                                ),
                                              ),
                                              items: ['Male', 'Female', 'Other']
                                                  .map(
                                                    (g) => DropdownMenuItem(
                                                      value: g,
                                                      child: Text(
                                                        g,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (v) => setState(
                                                () => _selectedGender = v,
                                              ),
                                            )
                                          : Text(
                                              _selectedGender ??
                                                  'Not specified',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: _selectedGender != null
                                                    ? const Color(0xFF111827)
                                                    : const Color(0xFF9CA3AF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _divider(),
                          _Field(
                            label: 'Diagnosis / Notes',
                            icon: Icons.medical_information_rounded,
                            controller: _childDiagnosisCtrl,
                            enabled: _editing,
                            hint: 'e.g. ASD Level 1',
                            maxLines: 2,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Options section
                      _SectionHeader(
                        icon: Icons.settings_rounded,
                        label: 'Options',
                      ),
                      const SizedBox(height: 12),
                      _ProfileCard(
                        children: [
                          _OptionTile(
                            icon: Icons.notifications_rounded,
                            label: 'Notifications',
                            color: const Color(0xFF4F6BFF),
                            onTap: () {},
                          ),
                          _divider(),
                          _OptionTile(
                            icon: Icons.privacy_tip_rounded,
                            label: 'Privacy & Data',
                            color: const Color(0xFF059669),
                            onTap: () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyScreen(),
                                  ),
                                ),
                          ),
                          _divider(),
                          _OptionTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            color: const Color(0xFFF97316),
                            onTap: () {},
                          ),
                          _divider(),
                          _OptionTile(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Sign in as Doctor',
                            color: const Color(0xFF7C3AED),
                            onTap: () => _switchRole(),
                          ),
                          _divider(),
                          _OptionTile(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            color: appColors.red,
                            onTap: _signOut,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // App version
                      Center(
                        child: Text(
                          'ACE Mobile · v1.0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date picker helper ────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: appColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      _childDobCtrl.text =
          '${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}';
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: appColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: appColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

Widget _divider() =>
    Divider(height: 1, indent: 50, color: const Color(0xFFF3F4F6));

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const _Field({
    required this.label,
    required this.icon,
    required this.controller,
    required this.enabled,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: appColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: enabled ? hint : '—',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                    disabledBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: label == 'Sign Out'
                    ? appColors.red
                    : const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            if (label != 'Sign Out')
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// Thin redirect widget — placed at the bottom of the stack after sign-out
// so AuthWrapper re-evaluates the Firebase auth state and shows loginPage.
class _AuthWrapperRedirect extends StatelessWidget {
  const _AuthWrapperRedirect();

  @override
  Widget build(BuildContext context) => const AuthWrapper();
}
