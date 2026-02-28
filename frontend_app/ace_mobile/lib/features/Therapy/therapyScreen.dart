import 'dart:math' as math;

import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';

class TherapyScreen extends StatelessWidget {
  const TherapyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const therapyAccent = appColors.primary;

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, therapyAccent),
              const SizedBox(height: 30),
              _buildStateMonitor(context),
              const SizedBox(height: 30),
              _buildPredictionCard(context, therapyAccent, Colors.white),
              const SizedBox(height: 30),
              _buildHeartRateSection(context, therapyAccent),
              const SizedBox(height: 20),
              _buildMetricsGrid(context, therapyAccent),
              const SizedBox(height: 20),
              _buildDailyPatternCard(context),
              const SizedBox(height: 40),
              _buildGroundingHeader(context),
              const SizedBox(height: 20),
              const _BreathingPacerCard(),
              const SizedBox(height: 20),
              _buildSensoryTechnique(context),
              const SizedBox(height: 20),
              _buildActionGrid(context),
              const SizedBox(height: 80), // Padding for bottom navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return Row(
      children: [
        Icon(Icons.sensors, color: accent, size: 24),
        const SizedBox(width: 8),
        Text(
          "Live Monitor",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "CONNECTED",
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.settings, color: Colors.grey),
      ],
    );
  }

  Widget _buildStateMonitor(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appColors.primary.withValues(alpha: 0.1),
                    width: 20,
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "CURRENT STATE",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColors.secondary.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Calm",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: appColors.primary,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Last synced: Just now",
            style: TextStyle(
              color: textColors.secondary.withValues(alpha: 0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(BuildContext context, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MELTDOWN PREDICTION",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stability remains high. Elevated heart rate detected 5m ago has normalized. No immediate action required.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateSection(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Heart Rate",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      "74",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "BPM",
                      style: TextStyle(
                        fontSize: 14,
                        color: textColors.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "LIVE FEED",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 4,
                      height: (index % 2 == 0 ? 12.0 : 20.0),
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: index == 3 ? 1.0 : 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(painter: HeartRatePainter(color: accent)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SKIN\nCONDUCTANCE",
                  style: TextStyle(
                    color: textColors.secondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: 0.3,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accent),
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Low",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "0.4 µS",
                      style: TextStyle(
                        color: textColors.secondary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 12),
                const Text(
                  "SUGGESTED\nACTION",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Sensory Break: Dim Lights",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPatternCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Daily Pattern",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "Morning session vs Average",
                    style: TextStyle(
                      color: textColors.secondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPatternItem("STRESS", 0.65, "- 12%", const Color(0xFFD97706)),
          const SizedBox(height: 12),
          _buildPatternItem("CALM", 0.45, "+ 8%", appColors.primary),
        ],
      ),
    );
  }

  Widget _buildGroundingHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Grounding Exercises",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Take a moment to reconnect with your surroundings.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColors.secondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSensoryTechnique(BuildContext context) {
    final items = [
      {"num": "5", "text": "Things you can ", "bold": "see"},
      {"num": "4", "text": "Things you can ", "bold": "touch"},
      {"num": "3", "text": "Things you can ", "bold": "hear"},
      {"num": "2", "text": "Things you can ", "bold": "smell"},
      {"num": "1", "text": "Thing you can ", "bold": "taste"},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Light green tint
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "5-4-3-2-1 Sensory Technique",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item["num"]!,
                      style: TextStyle(
                        color: appColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                      children: [
                        TextSpan(text: item["text"]),
                        TextSpan(
                          text: item["bold"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              "Call a Friend",
              "Reach out to your inner circle",
              Icons.people_outline,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              context,
              "Schedule Therapist",
              "Book a follow-up session",
              Icons.calendar_month_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
  ) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: appColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: textColors.secondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(
    String label,
    double value,
    String percentage,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: textColors.secondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          percentage,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Breathing Pacer (animated) ──────────────────────────────────────────────

enum _BreathPhase { idle, inhale, hold, exhale }

class _BreathingPacerCard extends StatefulWidget {
  const _BreathingPacerCard();

  @override
  State<_BreathingPacerCard> createState() => _BreathingPacerCardState();
}

class _BreathingPacerCardState extends State<_BreathingPacerCard>
    with SingleTickerProviderStateMixin {
  // Cycle: 4s inhale + 2s hold + 6s exhale = 12s total
  static const _inhaleDur = 4;
  static const _holdDur = 2;
  static const _exhaleDur = 6;
  static const _totalDur = _inhaleDur + _holdDur + _exhaleDur; // 12

  late final AnimationController _ctrl;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalDur),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  // Returns (phase, phaseProgress 0→1, countdown seconds)
  ({_BreathPhase phase, double progress, int countdown}) _currentPhase(
    double t,
  ) {
    final secs = t * _totalDur;
    if (secs < _inhaleDur) {
      final p = secs / _inhaleDur;
      return (
        phase: _BreathPhase.inhale,
        progress: p,
        countdown: _inhaleDur - secs.floor(),
      );
    } else if (secs < _inhaleDur + _holdDur) {
      final p = (secs - _inhaleDur) / _holdDur;
      return (
        phase: _BreathPhase.hold,
        progress: p,
        countdown: _holdDur - (secs - _inhaleDur).floor(),
      );
    } else {
      final p = (secs - _inhaleDur - _holdDur) / _exhaleDur;
      return (
        phase: _BreathPhase.exhale,
        progress: p,
        countdown: _exhaleDur - (secs - _inhaleDur - _holdDur).floor(),
      );
    }
  }

  // Circle scale: inhale 0.5→1.0, hold 1.0, exhale 1.0→0.5
  double _circleScale(_BreathPhase phase, double progress) {
    switch (phase) {
      case _BreathPhase.inhale:
        return 0.5 + 0.5 * Curves.easeInOut.transform(progress);
      case _BreathPhase.hold:
        return 1.0;
      case _BreathPhase.exhale:
        return 1.0 - 0.5 * Curves.easeInOut.transform(progress);
      case _BreathPhase.idle:
        return 0.5;
    }
  }

  Color _phaseColor(_BreathPhase phase) {
    switch (phase) {
      case _BreathPhase.inhale:
        return appColors.green;
      case _BreathPhase.hold:
        return const Color(0xFFD97706); // amber
      case _BreathPhase.exhale:
        return const Color(0xFF0891B2); // teal
      case _BreathPhase.idle:
        return appColors.green;
    }
  }

  String _phaseLabel(_BreathPhase phase) {
    switch (phase) {
      case _BreathPhase.inhale:
        return 'Inhale';
      case _BreathPhase.hold:
        return 'Hold';
      case _BreathPhase.exhale:
        return 'Exhale';
      case _BreathPhase.idle:
        return 'Ready';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Breathing Pacer",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Inhale slowly for 4 seconds, hold, and exhale for 6 seconds.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: appColors.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),

          // Start / Stop button
          ElevatedButton.icon(
            onPressed: _toggle,
            icon: Icon(_running ? Icons.stop : Icons.play_arrow, size: 18),
            label: Text(_running ? "Stop" : "Start Pacer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _running ? appColors.primary : Colors.white,
              foregroundColor: _running ? Colors.white : Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _running ? appColors.primary : Colors.grey.shade200,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Animated breathing circle
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final state = _running
                    ? _currentPhase(_ctrl.value)
                    : (phase: _BreathPhase.idle, progress: 0.0, countdown: 0);
                final scale = _circleScale(state.phase, state.progress);
                final color = _phaseColor(state.phase);

                return Column(
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          _animatedCircle(160 * scale, color, 0.1),
                          // Middle ring
                          _animatedCircle(120 * scale, color, 0.2),
                          // Core
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 70 * scale,
                            height: 70 * scale,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _running
                                  ? Text(
                                      '${state.countdown}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.air,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Phase label
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                      child: Text(_phaseLabel(state.phase)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCircle(double size, Color color, double alpha) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: math.max(size, 0),
      height: math.max(size, 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class HeartRatePainter extends CustomPainter {
  final Color color;

  HeartRatePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height * 0.7);
    path.lineTo(width * 0.1, height * 0.7);
    path.lineTo(width * 0.15, height * 0.6);
    path.lineTo(width * 0.2, height * 0.8);
    path.lineTo(width * 0.25, height * 0.5);
    path.lineTo(width * 0.35, height * 0.85);
    path.lineTo(width * 0.45, height * 0.4);
    path.lineTo(width * 0.55, height * 0.7);
    path.lineTo(width * 0.65, height * 0.2);
    path.lineTo(width * 0.75, height * 0.9);
    path.lineTo(width * 0.85, height * 0.1);
    path.lineTo(width * 0.95, height * 0.7);
    path.lineTo(width, height * 0.7);

    // Fade area
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
