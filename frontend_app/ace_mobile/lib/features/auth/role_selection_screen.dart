import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/doctor_bottom_navbar.dart';
import 'package:ace_mobile/features/onboarding/onboarding_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ── Form controllers for sign-up ──
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectRole(String role) async {
    setState(() => _selectedRole = role);

    // Show sign-up / sign-in bottom sheet
    final result = await _showAuthSheet(role);
    if (result != true) {
      // User cancelled
      if (mounted) setState(() => _selectedRole = null);
      return;
    }
  }

  /// Bottom-sheet that collects email, password, name & signs up / signs in.
  Future<bool?> _showAuthSheet(String role) {
    // Reset controllers
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _nameCtrl.clear();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool isLogin = false;
        bool isWorking = false;
        String? error;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isLogin ? 'Welcome Back' : 'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin
                          ? 'Sign in to continue as ${role == 'doctor' ? 'a Doctor' : 'a Parent'}'
                          : 'Sign up as ${role == 'doctor' ? 'a Doctor' : 'a Parent'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field (sign-up only)
                    if (!isLogin) ...[
                      _AuthTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],

                    _AuthTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _AuthTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      icon: Icons.lock_rounded,
                      obscure: true,
                    ),
                    const SizedBox(height: 8),

                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          error!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isWorking
                            ? null
                            : () async {
                                setSheetState(() {
                                  isWorking = true;
                                  error = null;
                                });
                                try {
                                  final authService = AuthService();
                                  if (isLogin) {
                                    await authService.signIn(
                                      email: _emailCtrl.text.trim(),
                                      password: _passwordCtrl.text,
                                    );
                                  } else {
                                    await authService.signUp(
                                      email: _emailCtrl.text.trim(),
                                      password: _passwordCtrl.text,
                                      displayName: _nameCtrl.text.trim(),
                                      role: role,
                                    );
                                  }

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx, true);
                                    _onAuthSuccess(role);
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    isWorking = false;
                                    error = e.toString().replaceAll('Exception: ', '');
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isWorking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLogin ? 'Sign In' : 'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Toggle sign-up / sign-in
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          isLogin = !isLogin;
                          error = null;
                        });
                      },
                      child: Text(
                        isLogin
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: appColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onAuthSuccess(String role) async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    final profile = context.read<ProfileProvider>();
    await profile.updateUserRole(role);

    // Load profile from Supabase
    await profile.initializeFromSupabase();

    // Mark onboarding as done for doctors, not for parents
    if (role == 'doctor') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // Navigate based on role
    final Widget destination;
    if (role == 'doctor') {
      destination = const DoctorBottomNavBar();
    } else {
      destination = const OnboardingScreen();
    }

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Setting up your profile…',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6B7280),
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

// ── Auth Text Field Widget ────────────────────────────────────────────────────

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: appColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
