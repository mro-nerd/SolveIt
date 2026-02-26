import 'dart:async';
import 'dart:math' show pi;

import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_provider.dart';
import 'package:ace_mobile/features/eye_contact/widgets/butterfly_animation.dart';
import 'package:ace_mobile/features/eye_contact/widgets/eye_tracking_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette — soft, child-friendly
// ─────────────────────────────────────────────────────────────────────────────
const _bgColor = Color(0xFFF0F7FF); // soft sky-blue
const _arenaGrad1 = Color(0xFFDFF3FF);
const _arenaGrad2 = Color(0xFFEEF6FF);
const _ringColor = Color(0xFF4CAF96);
const _ringLowColor = Color(0xFFFF6B6B);
const _btnColor = Color(0xFF4CAF96);
const _stopColor = Color(0xFFFF6B6B);

// ─────────────────────────────────────────────────────────────────────────────
// EyeContactScreen
// ─────────────────────────────────────────────────────────────────────────────

class EyeContactScreen extends StatefulWidget {
  const EyeContactScreen({super.key});

  @override
  State<EyeContactScreen> createState() => _EyeContactScreenState();
}

class _EyeContactScreenState extends State<EyeContactScreen> {
  // ── Local state ────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  int _secondsLeft = 30;
  bool _showResults = false;

  // ── Session helpers ────────────────────────────────────────────────────────

  void _startSession(EyeContactProvider p) {
    p.startSession();
    setState(() {
      _secondsLeft = p.sessionDurationSeconds;
      _showResults = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _countdownTimer = null;
        context.read<EyeContactProvider>().endSession();
        setState(() => _showResults = true);
      }
    });
  }

  void _endSession(EyeContactProvider p) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    p.endSession();
    setState(() => _showResults = true);
  }

  void _reset(EyeContactProvider p) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    p.reset();
    setState(() {
      _secondsLeft = p.sessionDurationSeconds;
      _showResults = false;
    });
  }

  // ── Position / gaze callbacks ─────────────────────────────────────────────

  void _onButterflyPos(double normalizedX, EyeContactProvider p) {
    p.updateButterflyPosition(normalizedX);
  }

  void _onGazeYaw(double yawAngle, EyeContactProvider p) {
    p.recordGazeYaw(yawAngle);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<EyeContactProvider>(
      builder: (context, provider, _) {
        final total = provider.sessionDurationSeconds;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _reset(provider);
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: _bgColor,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Top bar ───────────────────────────────────────────────
                  _TopBar(
                    onBack: () {
                      _reset(provider);
                      Navigator.of(context).pop();
                    },
                    secondsLeft: _secondsLeft,
                    totalSeconds: total,
                    sessionActive: provider.sessionActive,
                    inGracePeriod: provider.inGracePeriod,
                  ),

                  // ── Butterfly arena ───────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_arenaGrad1, _arenaGrad2],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // ① invisible camera processor (bottom of stack)
                              EyeTrackingOverlay(
                                onGazeYaw: (yaw) => _onGazeYaw(yaw, provider),
                              ),

                              // ② animated butterfly
                              ButterflyAnimation(
                                onPositionUpdate: (x) =>
                                    _onButterflyPos(x, provider),
                              ),

                              // ③ grace period overlay
                              if (provider.sessionActive &&
                                  provider.inGracePeriod)
                                const _GraceOverlay(),

                              // ④ idle prompt
                              if (!provider.sessionActive && !_showResults)
                                const _StartPrompt(),

                              // ⑤ results card (slides up from bottom)
                              if (_showResults)
                                _ResultsCard(
                                  score: provider.score,
                                  aligned: provider.alignedFrameCount,
                                  total: provider.totalFrameCount,
                                  onTryAgain: () => _reset(provider),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom action bar ─────────────────────────────────────
                  AnimatedSize(
                    duration: 300.ms,
                    curve: Curves.easeInOut,
                    child: _showResults
                        ? const SizedBox.shrink()
                        : _BottomBar(
                            sessionActive: provider.sessionActive,
                            onStart: () => _startSession(provider),
                            onEnd: () => _endSession(provider),
                          ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GraceOverlay — shown during the 2-second grace period
// ─────────────────────────────────────────────────────────────────────────────

class _GraceOverlay extends StatelessWidget {
  const _GraceOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Get ready… 🦋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: appColors.primary,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .then()
        .fadeOut(delay: 1500.ms, duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final int secondsLeft;
  final int totalSeconds;
  final bool sessionActive;
  final bool inGracePeriod;

  const _TopBar({
    required this.onBack,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.sessionActive,
    required this.inGracePeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: appColors.primary,
            iconSize: 22,
            onPressed: onBack,
          ),

          // Title
          Expanded(
            child: Text(
              'Follow the 🦋',
              style: TextStyle(
                fontSize: appSize.subHeading,
                fontWeight: FontWeight.w800,
                color: appColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Countdown ring (only visible during session)
          AnimatedOpacity(
            opacity: sessionActive ? 1.0 : 0.0,
            duration: 400.ms,
            child: _CountdownRing(
              secondsLeft: secondsLeft,
              totalSeconds: totalSeconds,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountdownRing
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownRing extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;

  const _CountdownRing({required this.secondsLeft, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final fraction = totalSeconds > 0
        ? (secondsLeft / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final isLow = secondsLeft <= 5;
    final color = isLow ? _ringLowColor : _ringColor;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(56, 56),
            painter: _RingPainter(fraction: fraction, color: color),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = cx - 4;

    // Background track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Filled arc (clockwise, starts at top)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,
      2 * pi * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// _StartPrompt
// ─────────────────────────────────────────────────────────────────────────────

class _StartPrompt extends StatelessWidget {
  const _StartPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🦋', style: TextStyle(fontSize: 64))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 16),
              Text(
                'Follow the butterfly!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: appColors.primary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap Start below 👇',
                style: TextStyle(
                  fontSize: 15,
                  color: appColors.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResultsCard
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final double score;
  final int aligned;
  final int total;
  final VoidCallback onTryAgain;

  const _ResultsCard({
    required this.score,
    required this.aligned,
    required this.total,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    final String emoji;
    final String message;
    if (score >= 0.8) {
      emoji = '🌟';
      message = 'Amazing focus!';
    } else if (score >= 0.5) {
      emoji = '👍';
      message = 'Great effort!';
    } else {
      emoji = '💪';
      message = 'Keep practising!';
    }

    return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: appColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 12),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: pct >= 80
                        ? appColors.green
                        : pct >= 50
                        ? appColors.primary
                        : appColors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555577),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$aligned of $total frames aligned',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.secondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTryAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btnColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Try Again 🦋',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.12, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomBar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool sessionActive;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const _BottomBar({
    required this.sessionActive,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: 300.ms,
        child: sessionActive
            ? SizedBox(
                key: const ValueKey('stop'),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEnd,
                  icon: const Icon(Icons.stop_rounded, size: 22),
                  label: const Text(
                    'Stop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stopColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              )
            : SizedBox(
                key: const ValueKey('start'),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text(
                    'Start  🦋',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _btnColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
      ),
    );
  }
}
