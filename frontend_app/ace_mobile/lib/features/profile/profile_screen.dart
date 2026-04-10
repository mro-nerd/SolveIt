import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/auth/loginPage.dart';
import 'package:ace_mobile/features/profile/add_child_screen.dart';
import 'package:ace_mobile/features/profile/join_code_card.dart';
import 'package:ace_mobile/features/profile/privacy_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:ace_mobile/backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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

    // 1. Clear all cached profile / SharedPreferences state
    if (mounted) await context.read<ProfileProvider>().clearAll();

    // 2. Sign out from Supabase
    try {
      await AuthService().signOut();
    } catch (e) {
      // Sign-out failed (e.g. network issue), but we still clear local state
      // and navigate away so the user isn't stuck.
      debugPrint('[ProfileScreen] signOut error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign out encountered an issue, but you have been logged out locally.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

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

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final supabaseUser = SupabaseClientManager.currentUser;

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
                                    supabaseUser?.userMetadata?['avatar_url'] != null &&
                                        (profile.photoPath == null)
                                    ? NetworkImage(supabaseUser!.userMetadata!['avatar_url'])
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
                              : (supabaseUser?.email ?? ''),
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

                      // Manage Children — only for parents with children
                      if (profile.isParent && profile.children.isNotEmpty)
                        ..._buildManageChildrenSection(profile),

                      // Join code — only for parents with a child
                      if (profile.isParent &&
                          profile.currentChild?['join_code'] != null)
                        ..._buildJoinCodeSection(profile),

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
                            icon: Icons.child_care_rounded,
                            label: 'Add Child',
                            color: const Color(0xFF10B981),
                            onTap: () async {
                              final result = await Navigator.of(context,
                                      rootNavigator: true)
                                  .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const AddChildScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                // Controllers need refreshing with new child data
                                final p = context.read<ProfileProvider>();
                                _childNameCtrl.text = p.childName;
                                _childDobCtrl.text = p.childDob;
                                _childDiagnosisCtrl.text = p.childDiagnosis;
                                _selectedGender = p.childGender.isNotEmpty
                                    ? p.childGender
                                    : null;
                              }
                            },
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

  // ── Join code section ──────────────────────────────────────────────────────
  List<Widget> _buildJoinCodeSection(ProfileProvider profile) {
    return [
      _SectionHeader(
        icon: Icons.link_rounded,
        label: 'Connect with Doctor',
      ),
      const SizedBox(height: 12),
      JoinCodeCard(
        joinCode: profile.currentChild?['join_code'] as String?,
      ),
      const SizedBox(height: 24),
    ];
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

  // ── Manage Children section ────────────────────────────────────────────────
  List<Widget> _buildManageChildrenSection(ProfileProvider profile) {
    final currentChildId = profile.currentChild?['id'];

    return [
      _SectionHeader(
        icon: Icons.group_rounded,
        label: 'Manage Children',
      ),
      const SizedBox(height: 12),
      _ProfileCard(
        children: [
          ...profile.children.asMap().entries.expand((entry) {
            final index = entry.key;
            final child = entry.value;
            final childId = child['id'] as String;
            final childName = child['child_name'] as String? ?? 'Unnamed';
            final dob = child['date_of_birth'] as String? ?? '';
            final isActive = childId == currentChildId;

            return [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (!isActive) {
                    profile.switchChild(child);
                    // Refresh controllers with new child data
                    _childNameCtrl.text = profile.childName;
                    _childDobCtrl.text = profile.childDob;
                    _childDiagnosisCtrl.text = profile.childDiagnosis;
                    _selectedGender =
                        profile.childGender.isNotEmpty ? profile.childGender : null;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Switched to $childName',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: appColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Active indicator
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? appColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: isActive
                              ? Icon(Icons.check_circle,
                                  size: 20, color: appColors.primary)
                              : Text(
                                  childName.isNotEmpty
                                      ? childName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Name + DOB
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    childName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isActive
                                          ? appColors.primary
                                          : const Color(0xFF111827),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: appColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: appColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (dob.isNotEmpty)
                              Text(
                                'DOB: $dob',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Edit button
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () => _showEditChildSheet(child),
                        tooltip: 'Edit $childName',
                      ),
                    ],
                  ),
                ),
              ),
              // Divider between children (but not after last)
              if (index < profile.children.length - 1) _divider(),
            ];
          }),
        ],
      ),
      const SizedBox(height: 24),
    ];
  }

  void _showEditChildSheet(Map<String, dynamic> child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _EditChildSheet(
          child: child,
          onSaved: () {
            // Refresh controllers if the current child was edited
            final p = context.read<ProfileProvider>();
            _childNameCtrl.text = p.childName;
            _childDobCtrl.text = p.childDob;
            _childDiagnosisCtrl.text = p.childDiagnosis;
            _selectedGender =
                p.childGender.isNotEmpty ? p.childGender : null;
            setState(() {});
          },
        ),
      ),
    );
  }
}

// ── Edit Child Bottom Sheet ──────────────────────────────────────────────────

class _EditChildSheet extends StatefulWidget {
  final Map<String, dynamic> child;
  final VoidCallback onSaved;

  const _EditChildSheet({required this.child, required this.onSaved});

  @override
  State<_EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends State<_EditChildSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _diagnosisCtrl;
  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.child['child_name'] as String? ?? '');
    _dobCtrl = TextEditingController(
        text: widget.child['date_of_birth'] as String? ?? '');
    _diagnosisCtrl = TextEditingController(
        text: widget.child['diagnosis_status'] as String? ?? '');
    _gender = widget.child['gender'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    DateTime initialDate;
    try {
      initialDate = DateTime.parse(_dobCtrl.text);
    } catch (_) {
      initialDate = now.subtract(const Duration(days: 365 * 3));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: appColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final childId = widget.child['id'] as String;
      final dob = _dobCtrl.text.trim();

      await context.read<ProfileProvider>().updateChildInSupabase(
            childId: childId,
            name: _nameCtrl.text.trim(),
            dob: dob,
            gender: _gender ?? 'Not specified',
            diagnosisStatus: _diagnosisCtrl.text.trim().isNotEmpty
                ? _diagnosisCtrl.text.trim()
                : null,
          );

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Child updated!',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Child',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            // Name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Child\'s Name',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: Icon(Icons.face_rounded, color: appColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: appColors.primary, width: 2),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            // DOB
            TextFormField(
              controller: _dobCtrl,
              readOnly: true,
              onTap: _pickDob,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: Icon(Icons.cake_rounded, color: appColors.primary),
                suffixIcon: Icon(Icons.calendar_today_rounded,
                    size: 18, color: appColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: appColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'Gender',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: Icon(Icons.wc_rounded, color: appColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: appColors.primary, width: 2),
                ),
              ),
              items: ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g, style: GoogleFonts.poppins(fontSize: 15)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 14),
            // Diagnosis
            TextFormField(
              controller: _diagnosisCtrl,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Diagnosis / Notes',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: Icon(Icons.medical_information_rounded,
                    color: appColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: appColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: appColors.primary.withValues(alpha: 0.3),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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

// _AuthWrapperRedirect removed — logout now navigates directly to loginPage.
