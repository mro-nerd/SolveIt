import 'dart:async';

import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'emotion_assessment_provider.dart';
import 'assessment_results_screen.dart';
import 'widgets/emotion_camera.dart';
import 'widgets/stimulus_display.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _bgColor = Color(0xFFF5F0FF);
const _primaryColor = Color(0xFF6C5CE7);
const _accentColor = Color(0xFFA29BFE);

class EmotionAssessmentScreen extends StatefulWidget {
  const EmotionAssessmentScreen({super.key});

  @override
  State<EmotionAssessmentScreen> createState() =>
      _EmotionAssessmentScreenState();
}

class _EmotionAssessmentScreenState extends State<EmotionAssessmentScreen> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Timer management ──

  void _startCountdownTimer(EmotionAssessmentProvider p) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      p.tickCountdown();
      // If state transitioned to playing, switch timer
      if (p.state == AssessmentState.playing) {
        _startRoundTimer(p);
      }
    });
  }

  void _startRoundTimer(EmotionAssessmentProvider p) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      p.tickRound();
      // If round ended, stop timer
      if (p.state != AssessmentState.playing) {
        _timer?.cancel();
        _timer = null;

        if (p.state == AssessmentState.betweenRounds) {
          // Auto-advance after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            p.nextRound();
            _startCountdownTimer(p);
          });
        }
      }
    });
  }

  void _begin(EmotionAssessmentProvider p) {
    p.startAssessment();
    _startCountdownTimer(p);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionAssessmentProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              provider.reset();
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: _bgColor,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──
                  _TopBar(
                    onBack: () {
                      _timer?.cancel();
                      provider.reset();
                      Navigator.of(context).pop();
                    },
                    state: provider.state,
                    roundIndex: provider.currentRoundIndex,
                    totalRounds: provider.totalRounds,
                  ),

                  // ── Main content area ──
                  Expanded(
                    child: Stack(
                      children: [
                        // Invisible camera (always under everything)
                        EmotionCamera(
                          active: provider.state == AssessmentState.playing,
                          onEmotionSample: (sample) =>
                              provider.recordSample(sample),
                        ),

                        // State-based content
                        _buildContent(context, provider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, EmotionAssessmentProvider p) {
    switch (p.state) {
      case AssessmentState.idle:
        return _WelcomeCard(onStart: () => _begin(p));

      case AssessmentState.countdown:
        return _CountdownOverlay(value: p.countdownValue);

      case AssessmentState.playing:
        return StimulusDisplay(
          stimulus: p.currentStimulus,
          secondsLeft: p.roundSecondsLeft,
          totalSeconds: p.currentStimulus.durationSeconds,
        );

      case AssessmentState.betweenRounds:
        return _BetweenRoundsCard(roundIndex: p.currentRoundIndex);

      case AssessmentState.done:
        // Navigate to results screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: p,
                child: const AssessmentResultsScreen(),
              ),
            ),
          );
        });
        return const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final AssessmentState state;
  final int roundIndex;
  final int totalRounds;

  const _TopBar({
    required this.onBack,
    required this.state,
    required this.roundIndex,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _primaryColor,
            iconSize: 22,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Emotion Check',
              style: TextStyle(
                fontSize: appSize.subHeading,
                fontWeight: FontWeight.w800,
                color: _primaryColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (state == AssessmentState.playing ||
              state == AssessmentState.betweenRounds)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${roundIndex + 1} / $totalRounds',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WelcomeCard
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomeCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎭', style: TextStyle(fontSize: 72))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1200.ms,
                    ),
                const SizedBox(height: 24),
                const Text(
                  'Emotion Check',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF333355),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Watch the screen and react naturally!\n'
                  'We\'ll show you some fun things and see how you feel.',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF555577).withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFF4CAF50),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Behavioural screening tool — not a medical diagnosis',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      'Start Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountdownOverlay
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownOverlay extends StatelessWidget {
  final int value;
  const _CountdownOverlay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Get Ready!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
                '$value',
                key: ValueKey(value),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                ),
              )
              .animate()
              .scale(
                begin: const Offset(1.5, 1.5),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BetweenRoundsCard
// ─────────────────────────────────────────────────────────────────────────────

class _BetweenRoundsCard extends StatelessWidget {
  final int roundIndex;
  const _BetweenRoundsCard({required this.roundIndex});

  @override
  Widget build(BuildContext context) {
    final messages = [
      'Great job! 👏',
      'Awesome! 🌟',
      'Nice one! ✨',
      'Keep going! 💪',
      'Well done! 🎉',
    ];
    final msg = messages[roundIndex % messages.length];

    return Center(
          child: Text(
            msg,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333355),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
