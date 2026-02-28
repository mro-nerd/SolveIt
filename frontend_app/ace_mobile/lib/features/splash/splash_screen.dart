import 'dart:math' as math;

import 'package:ace_mobile/features/auth/auth_wrapper.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SplashScreen
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────

  /// Entry fade of the whole screen
  late final AnimationController _entryCtrl;

  /// Two large orbs that drift and pulse
  late final AnimationController _orb1Ctrl;
  late final AnimationController _orb2Ctrl;

  /// Floating particle field
  late final AnimationController _particleCtrl;

  /// Logo container breathe / glow pulse
  late final AnimationController _pulseCtrl;

  /// Logo scale + fade pop
  late final AnimationController _logoCtrl;

  /// "ACE" letter stagger (drives individual letter delays via .value)
  late final AnimationController _lettersCtrl;

  /// Tagline typewriter
  late final AnimationController _taglineCtrl;

  /// Progress fill
  late final AnimationController _barCtrl;

  /// Status text opacity cycling
  late final AnimationController _statusCtrl;

  /// Exit — white wash
  late final AnimationController _exitCtrl;

  // ── Derived ──────────────────────────────────────────────────────────────────
  late final Animation<double> _entryFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _pulseSz; // 1.0 → 1.08
  late final Animation<double> _pulseAlpha; // glow opacity
  late final Animation<double> _letterProgress; // 0→1 drives stagger
  late final Animation<double> _taglineProgress;
  late final Animation<double> _barProgress;
  late final Animation<double> _exitFade;

  // ── State ────────────────────────────────────────────────────────────────────
  final List<_Particle> _particles = [];
  int _statusIndex = 0;
  static const _statusMessages = [
    'Initialising workspace…',
    'Loading your profile…',
    'Preparing your tools…',
    'Almost there…',
  ];

  @override
  void initState() {
    super.initState();
    _buildParticles();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);

    _orb1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _orb2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseSz = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseAlpha = Tween<double>(
      begin: 0.25,
      end: 0.55,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);

    _lettersCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _letterProgress = CurvedAnimation(
      parent: _lettersCtrl,
      curve: Curves.easeOutCubic,
    );

    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _taglineProgress = CurvedAnimation(
      parent: _taglineCtrl,
      curve: Curves.easeOutCubic,
    );

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _barProgress = CurvedAnimation(
      parent: _barCtrl,
      curve: Curves.easeInOutCubic,
    );

    _statusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  void _buildParticles() {
    final rng = math.Random(42);
    for (int i = 0; i < 38; i++) {
      _particles.add(
        _Particle(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          r: 1.2 + rng.nextDouble() * 2.2,
          speed: 0.015 + rng.nextDouble() * 0.035,
          opacity: 0.08 + rng.nextDouble() * 0.22,
          phase: rng.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  Future<void> _runSequence() async {
    await _entryCtrl.forward();

    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));

    _lettersCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));

    _taglineCtrl.forward();

    // cycle status messages
    _barCtrl.addListener(_updateStatus);

    await Future.wait([_barCtrl.forward(), _preloadData()]);

    await Future.delayed(const Duration(milliseconds: 350));
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

  void _updateStatus() {
    final idx = (_barProgress.value * _statusMessages.length).floor().clamp(
      0,
      _statusMessages.length - 1,
    );
    if (idx != _statusIndex) {
      setState(() => _statusIndex = idx);
      _statusCtrl.forward(from: 0);
    }
  }

  Future<void> _preloadData() async {
    if (mounted) await context.read<ProfileProvider>().loadFromPrefs();
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orb1Ctrl.dispose();
    _orb2Ctrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _logoCtrl.dispose();
    _lettersCtrl.dispose();
    _taglineCtrl.dispose();
    _barCtrl.dispose();
    _statusCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_exitFade),
      child: FadeTransition(
        opacity: _entryFade,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1F17),
          body: Stack(
            children: [
              // ── Deep background ──────────────────────────────────────────
              Positioned.fill(child: _BackgroundGradient()),

              // ── Drifting orbs ────────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_orb1Ctrl, _orb2Ctrl]),
                builder: (_, __) {
                  return Stack(
                    children: [
                      Positioned(
                        left: size.width * (-0.15 + _orb1Ctrl.value * 0.3),
                        top: size.height * (0.05 + _orb1Ctrl.value * 0.15),
                        child: _GlowOrb(
                          size: size.width * 0.75,
                          color: const Color(0xFF1DB870),
                          opacity: 0.10 + _orb1Ctrl.value * 0.04,
                        ),
                      ),
                      Positioned(
                        right: size.width * (-0.2 + _orb2Ctrl.value * 0.25),
                        bottom: size.height * (0.1 + _orb2Ctrl.value * 0.2),
                        child: _GlowOrb(
                          size: size.width * 0.85,
                          color: const Color(0xFF0E7A52),
                          opacity: 0.12 + _orb2Ctrl.value * 0.05,
                        ),
                      ),
                    ],
                  );
                },
              ),

              // ── Particle field ───────────────────────────────────────────
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  size: size,
                  painter: _ParticlePainter(_particles, _particleCtrl.value),
                ),
              ),

              // ── Central content ──────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Pulsing glow ring + logo ───────────────────────────
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow aura
                          Transform.scale(
                            scale: _pulseSz.value * 1.35,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1DB870,
                                    ).withValues(alpha: _pulseAlpha.value),
                                    blurRadius: 55,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child!,
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: _LogoContainer(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Staggered ACE letters ─────────────────────────────
                    AnimatedBuilder(
                      animation: _letterProgress,
                      builder: (_, __) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          const letters = ['A', 'C', 'E'];
                          final delay = i * 0.28;
                          final localT =
                              ((_letterProgress.value - delay) / (1 - delay))
                                  .clamp(0.0, 1.0);
                          return Transform.translate(
                            offset: Offset(0, 24 * (1 - _easeOutCubic(localT))),
                            child: Opacity(
                              opacity: _easeOutCubic(localT),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: Text(
                                  letters[i],
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 6,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Tagline with reveal clip ──────────────────────────
                    AnimatedBuilder(
                      animation: _taglineProgress,
                      builder: (_, __) => ClipRect(
                        child: Align(
                          widthFactor: _taglineProgress.value,
                          child: Opacity(
                            opacity: _taglineProgress.value.clamp(0.0, 1.0),
                            child: Text(
                              'Autism Care Ecosystem',
                              style: GoogleFonts.dmMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF5ECBA1),
                                letterSpacing: 3.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom: status + progress ────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: Column(
                  children: [
                    // Status text with fade-swap
                    AnimatedBuilder(
                      animation: _statusCtrl,
                      builder: (_, __) => Opacity(
                        opacity: 0.5 + _statusCtrl.value * 0.2,
                        child: Text(
                          _statusMessages[_statusIndex],
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: const Color(0xFF5ECBA1),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Segmented progress track
                    AnimatedBuilder(
                      animation: _barProgress,
                      builder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 52),
                        child: _SegmentedBar(progress: _barProgress.value),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Subtle top vignette ───────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x660B1F17), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _easeOutCubic(double t) {
    return 1 - math.pow(1 - t, 3).toDouble();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.3),
        radius: 1.2,
        colors: [Color(0xFF0E2E1E), Color(0xFF0B1F17), Color(0xFF060F0C)],
      ),
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ),
    ),
  );
}

class _LogoContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    height: 112,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E5C3A), Color(0xFF0E2E1E)],
      ),
      border: Border.all(
        color: const Color(0xFF1DB870).withValues(alpha: 0.35),
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x331DB870), blurRadius: 30, spreadRadius: 4),
      ],
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon placeholder — replace with your actual asset
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1DB870).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF1DB870).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Color(0xFF5ECBA1),
              size: 20,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 38,
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF5ECBA1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A row of evenly-spaced pill segments that fill left-to-right
class _SegmentedBar extends StatelessWidget {
  final double progress;
  const _SegmentedBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    const segments = 20;
    final filled = (progress * segments).floor();
    final partial = (progress * segments) - filled;

    return Row(
      children: List.generate(segments, (i) {
        double alpha;
        if (i < filled) {
          alpha = 1.0;
        } else if (i == filled) {
          alpha = partial;
        } else {
          alpha = 0.0;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: alpha > 0
                    ? Color.lerp(
                        const Color(0xFF1A4D32),
                        const Color(0xFF1DB870),
                        alpha,
                      )
                    : const Color(0xFF1A3025),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Particle system
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  final double x, y, r, speed, opacity, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0→1 continuous

  const _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y + t * p.speed) % 1.0;
      final dx = p.x + math.sin(t * math.pi * 2 * p.speed + p.phase) * 0.04;
      final twinkle = 0.5 + 0.5 * math.sin(t * math.pi * 4 + p.phase);

      final paint = Paint()
        ..color = const Color(0xFF5ECBA1).withValues(alpha: p.opacity * twinkle)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(dx * size.width, dy * size.height), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
