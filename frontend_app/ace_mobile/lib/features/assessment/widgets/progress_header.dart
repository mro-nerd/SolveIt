import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';

/// Animated progress header showing question number and progress bar.
class ProgressHeader extends StatelessWidget {
  final int current; // 1-based display index
  final int total;
  final VoidCallback? onBack;

  const ProgressHeader({
    super.key,
    required this.current,
    required this.total,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (current - 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: appColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: appColors.primary,
                    size: 24,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question $current of $total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: appColors.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: appColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            appColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PercentBadge(fraction: fraction),
          ],
        ),
      ],
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final double fraction;
  const _PercentBadge({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(fraction * 100).round()}%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: appColors.primary,
        ),
      ),
    );
  }
}
