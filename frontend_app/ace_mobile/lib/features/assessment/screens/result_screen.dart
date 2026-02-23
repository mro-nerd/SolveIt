import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import 'ai_report_screen.dart';

/// Result screen shown after all 20 M-CHAT-R questions are answered.
/// Displays risk score, level, per-category breakdown, and retake option.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, _) {
        final score = provider.riskScore;
        final level = provider.riskLevel;
        final config = _riskConfig(level);

        return Scaffold(
          backgroundColor: appColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF1A2B3C),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'M-CHAT-R Results',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Score card
                  _ScoreCard(
                    score: score,
                    level: level,
                    color: config['color']! as Color,
                    icon: config['icon']! as IconData,
                    description: config['description']! as String,
                  ),
                  const SizedBox(height: 24),

                  // Score scale visualization
                  _ScoreScale(score: score),
                  const SizedBox(height: 28),

                  // Per-question answer review
                  const Text(
                    'Answer Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AnswerReviewList(provider: provider),
                  const SizedBox(height: 28),

                  // Disclaimer
                  _DisclaimerBox(),
                  const SizedBox(height: 28),

                  // Retake button
                  _RetakeButton(provider: provider),
                  const SizedBox(height: 12),

                  // AI Report button
                  _AiReportButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, Object> _riskConfig(String level) {
    switch (level) {
      case 'Low Risk':
        return {
          'color': const Color(0xFF22C55E),
          'icon': Icons.check_circle_rounded,
          'description':
              'Score suggests low likelihood of ASD. Typical developmental milestones observed.',
        };
      case 'Medium Risk':
        return {
          'color': const Color(0xFFF59E0B),
          'icon': Icons.warning_rounded,
          'description':
              'Score indicates some areas of concern. A follow-up assessment may be recommended.',
        };
      default:
        return {
          'color': const Color(0xFFEF4444),
          'icon': Icons.error_rounded,
          'description':
              'Score indicates a higher likelihood of ASD risk. Please consult a healthcare professional promptly.',
        };
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String level;
  final Color color;
  final IconData icon;
  final String description;

  const _ScoreCard({
    required this.score,
    required this.level,
    required this.color,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon + level badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            level,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A2B3C),
                ),
              ),
              const Text(
                ' / 20',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'risk indicators',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreScale extends StatelessWidget {
  final int score;
  const _ScoreScale({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Scale',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 20),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation(
                    score <= 2
                        ? const Color(0xFF22C55E)
                        : score <= 7
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScaleLabel('0–2\nLow', const Color(0xFF22C55E)),
              _ScaleLabel('3–7\nMedium', const Color(0xFFF59E0B)),
              _ScaleLabel('8–20\nHigh', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _ScaleLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      ),
    );
  }
}

class _AnswerReviewList extends StatelessWidget {
  final AssessmentProvider provider;
  const _AnswerReviewList({required this.provider});

  bool _isRiskPositive(bool answer, bool riskWhenYes) {
    return riskWhenYes ? answer == true : answer == false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: provider.questions.map((q) {
        final answer = provider.getAnswer(q.id);
        final isRisk =
            answer != null && _isRiskPositive(answer, q.riskWhenAnswerYes);
        final answerLabel = answer == null
            ? 'Not answered'
            : answer
            ? 'Yes'
            : 'No';
        final answerColor = answer == null
            ? const Color(0xFF9CA3AF)
            : isRisk
            ? appColors.red
            : appColors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: answerColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${q.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: answerColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                answerLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: answerColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DisclaimerBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF97316),
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This result is for screening purposes only and is NOT a clinical diagnosis. Consult a licensed healthcare professional for a comprehensive evaluation.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetakeButton extends StatelessWidget {
  final AssessmentProvider provider;
  const _RetakeButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await provider.reset();
        if (context.mounted) {
          // Pop back to the intro screen (clears the question + result screens)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [appColors.primary, Color(0xFF1A5C47)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Retake Assessment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiReportButton extends StatelessWidget {
  const _AiReportButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiReportScreen()),
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Generate AI Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
