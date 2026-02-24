import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/eye_contact/eye_contact_provider.dart';
import 'package:ace_mobile/features/eye_contact/widgets/butterfly_animation.dart';
import 'package:ace_mobile/features/eye_contact/widgets/eye_tracking_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class EyeContactScreen extends StatefulWidget {
  const EyeContactScreen({super.key});

  @override
  State<EyeContactScreen> createState() => _EyeContactScreenState();
}

class _EyeContactScreenState extends State<EyeContactScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EyeContactProvider>();

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Eye Contact',
          style: TextStyle(
            color: appColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: appSize.subHeading,
          ),
        ),
        iconTheme: const IconThemeData(color: appColors.primary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header card ──────────────────────────────────────────────
            _HeaderCard(provider: provider),

            // ── Interactive area ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          appColors.primary.withValues(alpha: 0.08),
                          appColors.primary.withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: appColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Butterfly floats freely inside this container
                        ButterflyAnimation(
                          onDirectionUpdate: (direction) {
                            provider.updateButterflyDirection(direction);
                          },
                        ),

                        // Invisible background widget: camera + ML Kit
                        EyeTrackingOverlay(
                          onGazeDirection: (dir) {
                            provider.recordGazeDirection(dir);
                          },
                        ),

                        // Placeholder camera preview label
                        if (!provider.sessionActive)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  size: 64,
                                  color: appColors.primary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Camera preview will appear here',
                                  style: TextStyle(
                                    color: appColors.secondary.withValues(alpha: 0.6),
                                    fontSize: appSize.small,
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
            ),

            const SizedBox(height: 16),

            // ── Score row ─────────────────────────────────────────────────
            _ScoreRow(provider: provider),

            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────────────
            _ActionButtons(provider: provider),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════════════════

class _HeaderCard extends StatelessWidget {
  final EyeContactProvider provider;
  const _HeaderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: appColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.visibility, color: appColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eye Contact Exercise',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: appColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Follow the butterfly with your eyes for ${provider.sessionDurationSeconds}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: appColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _ScoreRow extends StatelessWidget {
  final EyeContactProvider provider;
  const _ScoreRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scorePercent = (provider.score * 100).toStringAsFixed(1);
    final color = provider.score >= 0.6 ? appColors.green : appColors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(
            label: 'Score',
            value: '$scorePercent%',
            color: color,
            icon: Icons.star_rounded,
          ),
          _StatChip(
            label: 'Aligned',
            value: '${provider.alignedFrameCount}',
            color: appColors.primary,
            icon: Icons.check_circle_outline,
          ),
          _StatChip(
            label: 'Total',
            value: '${provider.totalFrameCount}',
            color: appColors.secondary,
            icon: Icons.bar_chart,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final EyeContactProvider provider;
  const _ActionButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Reset button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: provider.sessionActive ? null : provider.reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: appColors.primary,
                side: const BorderSide(color: appColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Start / Stop button
          Expanded(
            flex: 2,
            child: AnimatedSwitcher(
              duration: 250.ms,
              child: provider.sessionActive
                  ? ElevatedButton.icon(
                      key: const ValueKey('stop'),
                      onPressed: provider.endSession,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('start'),
                      onPressed: provider.startSession,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Start Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
