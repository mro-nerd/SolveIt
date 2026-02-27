import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ace_mobile/features/auth/role_selection_screen.dart';

// ─── Data model ────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final Color iconBg;
  final IconData icon;
  final String? badge; // e.g. "STEP 1"
  final Color badgeColor;
  final Widget? bodyExtra; // extra widget rendered below description
  final Color bgTop;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconBg,
    required this.icon,
    this.badge,
    this.badgeColor = const Color(0xFFEDE9FE),
    this.bodyExtra,
    this.bgTop = const Color(0xFFDFF2EC),
  });
}

// ─── Pages definition ──────────────────────────────────────────────────────────

final List<_OnboardingPage> _pages = [
  _OnboardingPage(
    title: 'Welcome to ACE',
    subtitle: 'Bonding',
    badge: 'STEP 1',
    badgeColor: const Color(0xFFEDE9FE),
    description:
        'Our AI guides you through easy steps to understand your child\'s unique development journey with care and precision.',
    iconBg: const Color(0xFF4F6BFF),
    icon: Icons.people_alt_rounded,
    bgTop: const Color(0xFFDFF2EC),
  ),
  _OnboardingPage(
    title: 'Every Month\nMatters',
    subtitle: 'Timeline',
    badge: 'COMPARISON',
    badgeColor: const Color(0xFF34D399),
    description: '',
    iconBg: const Color(0xFF34D399),
    icon: Icons.show_chart_rounded,
    bgTop: const Color(0xFFDFF2EC),
    bodyExtra: _TimelineBodyExtra(),
  ),
  _OnboardingPage(
    title: 'Simple. Fast.\nAt Home.',
    subtitle: 'Record Videos',
    badge: 'STEP 2',
    badgeColor: const Color(0xFFEDE9FE),
    description:
        'Capture short videos of your child playing. Our AI analyzes subtle behaviors securely.',
    iconBg: const Color(0xFF7C3AED),
    icon: Icons.videocam_rounded,
    bgTop: const Color(0xFFDFF2EC),
    bodyExtra: _NoHospitalTag(),
  ),
  _OnboardingPage(
    title: 'Support That\nGrows With\nYour Child',
    subtitle: 'Development',
    badge: 'STEP 4',
    badgeColor: const Color(0xFFEDE9FE),
    description:
        'Our AI adapts its recommendations as your child progresses, offering gamified therapy and development tracking tailored to their unique journey.',
    iconBg: const Color(0xFF2563EB),
    icon: Icons.trending_up_rounded,
    bgTop: const Color(0xFFDFF2EC),
  ),
  _OnboardingPage(
    title: 'Private. Secure.\nClinically\nSupported.',
    subtitle: 'Safe & Private',
    badge: 'HIPAA COMPLIANT',
    badgeColor: const Color(0xFF34D399),
    description:
        'Your child\'s data is protected by bank-level encryption. We partner with pediatric specialists to ensure trusted care.',
    iconBg: const Color(0xFF059669),
    icon: Icons.shield_rounded,
    bgTop: const Color(0xFFDFF2EC),
    bodyExtra: _HipaaBodyExtra(),
  ),
];

// ─── Extra widgets ──────────────────────────────────────────────────────────────

class _TimelineBodyExtra extends StatelessWidget {
  const _TimelineBodyExtra();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Typical\nMiles.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F6BFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ACE',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['YEARS', 'WEEKS'].map((t) {
                  final bool isWeeks = t == 'WEEKS';
                  return Text(
                    t,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isWeeks
                          ? const Color(0xFF4F6BFF)
                          : Colors.grey.shade500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._bullets([
          'AI-powered risk screening',
          'Home-based assessment',
          'No long wait times',
        ]),
      ],
    );
  }
}

List<Widget> _bullets(List<String> items) {
  final icons = [
    Icons.check_circle_rounded,
    Icons.home_rounded,
    Icons.timer_off_rounded,
  ];
  final colors = [
    const Color(0xFF34D399),
    const Color(0xFF4F6BFF),
    const Color(0xFFEF4444),
  ];
  return List.generate(items.length, (i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icons[i], color: colors[i], size: 20),
          const SizedBox(width: 10),
          Text(
            items[i],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  });
}

class _NoHospitalTag extends StatelessWidget {
  const _NoHospitalTag();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'No hospital visits required.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4F6BFF),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF4F6BFF),
        ),
      ),
    );
  }
}

class _HipaaBodyExtra extends StatelessWidget {
  const _HipaaBodyExtra();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SecurityChip(icon: Icons.lock_rounded, label: 'Encryption'),
          const SizedBox(width: 16),
          _SecurityChip(icon: Icons.local_hospital_rounded, label: 'Clinical'),
        ],
      ),
    );
  }
}

class _SecurityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SecurityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF059669)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main Onboarding Screen ────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goNext() async {
    if (_currentPage < _pages.length - 1) {
      _fadeController.reset();
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
      _fadeController.forward();
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (idx) {
          setState(() => _currentPage = idx);
          _fadeController.reset();
          _fadeController.forward();
        },
        itemCount: _pages.length,
        itemBuilder: (_, i) =>
            _OnboardingPageView(page: _pages[i], fadeAnim: _fadeAnim),
      ),
      bottomNavigationBar: _BottomBar(
        currentPage: _currentPage,
        total: _pages.length,
        onNext: _goNext,
        onSkip: _finishOnboarding,
      ),
    );
  }
}

// ─── Single onboarding page ────────────────────────────────────────────────────

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final Animation<double> fadeAnim;

  const _OnboardingPageView({required this.page, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [page.bgTop, Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Card area (top half) ───────────────────────────────────────
            Expanded(
              flex: 5,
              child: Center(
                child: FadeTransition(
                  opacity: fadeAnim,
                  child: _IconCard(page: page),
                ),
              ),
            ),

            // ── Text area (bottom half) ────────────────────────────────────
            Expanded(
              flex: 6,
              child: FadeTransition(
                opacity: fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        page.title,
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                          height: 1.15,
                        ),
                      ),
                      if (page.description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          page.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                      ],
                      if (page.bodyExtra != null) page.bodyExtra!,
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
}

// ─── Floating icon card ────────────────────────────────────────────────────────

class _IconCard extends StatelessWidget {
  final _OnboardingPage page;
  const _IconCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: page.iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(page.icon, color: Colors.white, size: 36),
              ),
              // Orange notification dot
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            page.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          if (page.badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: page.badgeColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                page.badge!,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      page.badge == 'COMPARISON' ||
                          page.badge == 'HIPAA COMPLIANT'
                      ? const Color(0xFF059669)
                      : const Color(0xFF7C3AED),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Decorative bars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final heights = [12.0, 20.0, 16.0, 24.0];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 6,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: page.iconBg.withValues(alpha: 0.3 + i * 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentPage;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _BottomBar({
    required this.currentPage,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == total - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button
          GestureDetector(
            onTap: onSkip,
            child: AnimatedOpacity(
              opacity: isLast ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Page indicators
          Row(
            children: List.generate(total, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2D7B60)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),

          // Next / Done button
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2D7B60),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7B60).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
