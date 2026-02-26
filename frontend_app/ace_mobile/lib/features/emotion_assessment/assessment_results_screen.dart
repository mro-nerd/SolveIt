import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'emotion_assessment_provider.dart';
import 'models/assessment_result.dart';
import 'models/stimulus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _primaryColor = Color(0xFF6C5CE7);
const _bgColor = Color(0xFFF5F0FF);

class AssessmentResultsScreen extends StatelessWidget {
  const AssessmentResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmotionAssessmentProvider>();
    final summary = provider.summary;

    if (summary == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: const Center(child: Text('No results available.')),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: _primaryColor,
                    iconSize: 22,
                    onPressed: () {
                      provider.reset();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Assessment Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Hero score ──
              _HeroScoreCard(summary: summary),
              const SizedBox(height: 20),

              // ── Key metrics ──
              _MetricsRow(summary: summary),
              const SizedBox(height: 24),

              // ── Per-round breakdown ──
              const Text(
                'Round Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333355),
                ),
              ),
              const SizedBox(height: 12),
              ...summary.roundResults.asMap().entries.map(
                (e) => _RoundCard(index: e.key, result: e.value),
              ),

              const SizedBox(height: 20),

              // ── Disclaimer ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'This is a behavioural screening tool and should not '
                        'be considered a medical diagnosis. Please consult a '
                        'healthcare professional for clinical evaluations.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Try again button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.reset();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 22),
                  label: const Text(
                    'Done',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeroScoreCard
// ─────────────────────────────────────────────────────────────────────────────

class _HeroScoreCard extends StatelessWidget {
  final AssessmentSummary summary;
  const _HeroScoreCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.overallScore.round();
    final String emoji;
    final String label;
    if (pct >= 75) {
      emoji = '🌟';
      label = 'Great emotional responses!';
    } else if (pct >= 50) {
      emoji = '👍';
      label = 'Good responses overall';
    } else {
      emoji = '📊';
      label = 'Needs further observation';
    }

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Emotion Match Score',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetricsRow
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  final AssessmentSummary summary;
  const _MetricsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.speed,
            label: 'Reaction',
            value: summary.avgReactionTimeMs > 0
                ? '${(summary.avgReactionTimeMs / 1000).toStringAsFixed(1)}s'
                : 'N/A',
            color: const Color(0xFFFFB74D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.favorite,
            label: 'Empathy',
            value: '${summary.empathyScore.round()}%',
            color: const Color(0xFFEF5350),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.equalizer,
            label: 'Stability',
            value: '${((1 - summary.emotionalVariability) * 100).round()}%',
            color: const Color(0xFF42A5F5),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF555577).withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoundCard
// ─────────────────────────────────────────────────────────────────────────────

class _RoundCard extends StatelessWidget {
  final int index;
  final RoundResult result;

  const _RoundCard({required this.index, required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.emotionMatchScore.round();
    final reactionLabel = result.reactionTimeMs > 0
        ? '${(result.reactionTimeMs / 1000).toStringAsFixed(1)}s'
        : '—';

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Emoji icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _emotionBgColor(result.stimulus.expectedEmotion),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  result.stimulus.emoji.characters.first,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),

              // Title + expected
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.stimulus.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333355),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expected: ${result.stimulus.expectedEmotion.name}  •  ⏱ $reactionLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF555577).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor(pct).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor(pct),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }

  Color _emotionBgColor(ExpectedEmotion e) {
    switch (e) {
      case ExpectedEmotion.happy:
        return const Color(0xFFFFF3E0);
      case ExpectedEmotion.surprise:
        return const Color(0xFFF3E5F5);
      case ExpectedEmotion.sad:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _scoreColor(int pct) {
    if (pct >= 70) return const Color(0xFF4CAF50);
    if (pct >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }
}
