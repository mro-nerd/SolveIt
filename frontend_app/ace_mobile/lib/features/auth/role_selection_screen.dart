import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/doctor_bottom_navbar.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:ace_mobile/shared/BottomNavbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  String? _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectRole(String role) async {
    setState(() {
      _selectedRole = role;
      _isSaving = true;
    });

    final profile = context.read<ProfileProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // 1. Save role locally (SharedPreferences)
    await profile.updateUserRole(role);

    // 2. Persist to Supabase via ProfileService
    if (firebaseUser != null) {
      try {
        final profileService = ProfileService();
        await profileService.upsertProfile(
          firebaseUid: firebaseUser.uid,
          role: role,
          displayName: firebaseUser.displayName ?? profile.parentName,
          email: firebaseUser.email ?? profile.parentEmail,
        );

        // Reload profile from Supabase so provider has fresh data
        await profile.loadProfile(firebaseUser.uid);
      } catch (e) {
        debugPrint('[RoleSelection] Error saving role to Supabase: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile saved locally. Sync will retry later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final destination = role == 'doctor'
        ? const DoctorBottomNavBar()
        : const CustomBottomNavBar();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF2EC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // ── Icon ──
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: appColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 40,
                        color: appColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Title ──
                    Text(
                      'Who are you?',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose your role to personalize\nyour experience',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Role Cards ──
                    _RoleCard(
                      title: 'I\'m a Parent',
                      subtitle:
                          'Track your child\'s development\nand get personalized guidance',
                      icon: Icons.family_restroom_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFEDE9FE),
                      isSelected: _selectedRole == 'parent',
                      isDisabled: _isSaving,
                      onTap: () => _selectRole('parent'),
                    ),

                    const SizedBox(height: 20),

                    _RoleCard(
                      title: 'I\'m a Doctor',
                      subtitle:
                          'Manage patients, therapy plans\nand track developmental progress',
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                      isSelected: _selectedRole == 'doctor',
                      isDisabled: _isSaving,
                      onTap: () => _selectRole('doctor'),
                    ),

                    const SizedBox(height: 24),

                    // ── Loading indicator while saving ──
                    if (_isSaving)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Setting up your profile…',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // ── Footer ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Text(
                        'You can change this later in Settings',
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
        ),
      ),
    );
  }
}

// ── Role Card Widget ──────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? appColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? appColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (_isSavingThis)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isSelected ? appColors.primary : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  bool get _isSavingThis => isSelected && isDisabled;
}
