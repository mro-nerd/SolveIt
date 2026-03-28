import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ace_mobile/features/progress/progress_dashboard_screen.dart';
import 'package:ace_mobile/features/progress/progress_provider.dart';

class ProgressGraphCard extends StatelessWidget {
  const ProgressGraphCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = appColors.primary;
    final provider = context.watch<ProgressProvider>();

    final avgScore = provider.averageLatestScore;
    final scoreStr = avgScore != null ? '${avgScore.toStringAsFixed(0)}%' : '—';

    // Calculate overall delta from individual deltas
    final deltas = provider.scoreDeltas.values.whereType<double>();
    final avgDelta = deltas.isNotEmpty
        ? deltas.reduce((a, b) => a + b) / deltas.length
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Overall Development Score",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.bar_chart, size: 18, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  scoreStr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(width: 8),
                if (avgDelta != null) ...[
                  Icon(
                    avgDelta >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: avgDelta >= 0 ? appColors.green : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${avgDelta >= 0 ? '+' : ''}${avgDelta.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color:
                          avgDelta >= 0 ? appColors.green : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Mini indicator bars for each type
            _buildMiniBars(provider),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: kSessionTypes.map((type) {
                  return Text(
                    _shortLabel(type),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColors.secondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBars(ProgressProvider provider) {
    return Row(
      children: kSessionTypes.map((type) {
        final score = provider.latestScores[type] ?? 0;
        final color = _colorForType(type);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        heightFactor: (score / 100).clamp(0.0, 1.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _shortLabel(String type) {
    switch (type) {
      case 'mchat':
        return 'M-C';
      case 'emotion_assessment':
        return 'EMO';
      case 'eye_contact':
        return 'EYE';
      case 'imitation':
        return 'IMI';
      default:
        return type.substring(0, 3).toUpperCase();
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'mchat':
        return const Color(0xFF7C3AED);
      case 'emotion_assessment':
        return const Color(0xFFF59E0B);
      case 'eye_contact':
        return const Color(0xFF0284C7);
      case 'imitation':
        return const Color(0xFF10B981);
      default:
        return appColors.primary;
    }
  }
}
