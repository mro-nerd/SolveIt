import 'dart:math' as math;

import 'package:ace_mobile/features/auth/auth_wrapper.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────

  /// Overall fade-in of the whole screen background
  late final AnimationController _bgCtrl;

  /// Logo scale + fade
  late final AnimationController _logoCtrl;

  /// Rotating shimmer ring
  late final AnimationController _ringCtrl;

  /// Text slide-up + fade
  late final AnimationController _textCtrl;

  /// Bottom progress bar fill
  late final AnimationController _barCtrl;

  /// Exit: entire screen fades to white before navigating
  late final AnimationController _exitCtrl;

  // ── Derived animations ─────────────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _barProgress;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Background fade — fast
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // Logo — pops in with spring
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);

    // Shimmer ring — continuous rotation
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Text — slides up from below
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textSlide = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);

    // Progress bar — fills over 2 seconds
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _barProgress = CurvedAnimation(
      parent: _barCtrl,
      curve: Curves.easeInOutCubic,
    );

    // Exit fade
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 0, end: 1).animate(_exitCtrl);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1 — Background fades in
    await _bgCtrl.forward();

    // 2 — Logo pops in + ring starts already spinning
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // 3 — Text slides up
    _textCtrl.forward();

    // 4 — Pre-load data & fill progress bar simultaneously
    await Future.wait([_barCtrl.forward(), _preloadData()]);

    // 5 — Hold for a beat then exit
    await Future.delayed(const Duration(milliseconds: 300));
    await _exitCtrl.forward();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  Future<void> _preloadData() async {
    // Load profile prefs during the splash so they're ready on home screen
    if (mounted) {
      await context.read<ProfileProvider>().loadFromPrefs();
    }
    // Ensure at least a small minimum display time
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      // Exit fade (white overlay)
      opacity: Tween<double>(begin: 1, end: 0).animate(_exitFade),
      child: FadeTransition(
        // Entry fade
        opacity: _bgFade,
        child: Scaffold(
          body: Container(
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
            child: Stack(
              children: [
                // ── Subtle background circles ──────────────────────────────
                Positioned(
                  top: -80,
                  right: -80,
                  child: _GlowCircle(size: 280, opacity: 0.08),
                ),
                Positioned(
                  bottom: -120,
                  left: -60,
                  child: _GlowCircle(size: 320, opacity: 0.06),
                ),

                // ── Main content ───────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Shimmer ring + logo ────────────────────────────
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Rotating shimmer ring
                            AnimatedBuilder(
                              animation: _ringCtrl,
                              builder: (_, __) => Transform.rotate(
                                angle: _ringCtrl.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(160, 160),
                                  painter: _ShimmerRingPainter(),
                                ),
                              ),
                            ),

                            // Logo icon
                            ScaleTransition(
                              scale: _logoScale,
                              child: FadeTransition(
                                opacity: _logoFade,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ACE',
                                          style: GoogleFonts.poppins(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                            height: 1,
                                          ),
                                        ),
                                        Container(
                                          width: 42,
                                          height: 2,
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── App name + tagline ──────────────────────────────
                      AnimatedBuilder(
                        animation: _textCtrl,
                        builder: (_, child) => Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: child,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'ACE Mobile',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Autism Care & Engagement',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom section: progress bar ────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 60,
                  child: Column(
                    children: [
                      Text(
                        'Loading your workspace…',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: AnimatedBuilder(
                          animation: _barProgress,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: _barProgress.value,
                              minHeight: 3,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer ring painter ────────────────────────────────────────────────────────

class _ShimmerRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Dashed arc segments that create the shimmer effect
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const segments = 8;
    const gapFraction = 0.3;
    const segmentAngle = (2 * math.pi) / segments;
    const drawAngle = segmentAngle * (1 - gapFraction);

    for (int i = 0; i < segments; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final opacity = (i / segments);
      paint.color = Colors.white.withValues(alpha: 0.15 + opacity * 0.55);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        drawAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Glow circle ───────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}
