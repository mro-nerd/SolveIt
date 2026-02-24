import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A playful animated butterfly that floats and flutters around the screen.
/// The butterfly moves to a new random position every [moveInterval] seconds.
/// Wings flutter continuously using a scale animation.
class ButterflyAnimation extends StatefulWidget {
  /// Called whenever the butterfly settles in a new position.
  /// [direction] is the normalised offset (0.0–1.0) within the container.
  final void Function(Offset direction)? onDirectionChanged;

  /// How long the butterfly stays in one spot before moving.
  final Duration moveInterval;

  const ButterflyAnimation({
    super.key,
    this.onDirectionChanged,
    this.moveInterval = const Duration(seconds: 3),
  });

  @override
  State<ButterflyAnimation> createState() => _ButterflyAnimationState();
}

class _ButterflyAnimationState extends State<ButterflyAnimation> {
  final _random = Random();
  Offset _position = const Offset(0.5, 0.5); // normalised (0–1)
  late final _movePeriod = widget.moveInterval;

  @override
  void initState() {
    super.initState();
    _scheduleNextMove();
  }

  void _scheduleNextMove() {
    Future.delayed(_movePeriod, () {
      if (!mounted) return;
      final next = Offset(
        0.1 + _random.nextDouble() * 0.8, // keep away from edges
        0.1 + _random.nextDouble() * 0.8,
      );
      setState(() => _position = next);
      widget.onDirectionChanged?.call(next);
      _scheduleNextMove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dx = _position.dx * constraints.maxWidth - 24;
        final dy = _position.dy * constraints.maxHeight - 24;

        return AnimatedPositioned(
          duration: _movePeriod * 0.8,
          curve: Curves.easeInOut,
          left: dx.clamp(0, constraints.maxWidth - 48),
          top: dy.clamp(0, constraints.maxHeight - 48),
          child: _ButterflyBody(),
        );
      },
    );
  }
}

class _ButterflyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left wing
          Positioned(
            left: 0,
            child: _Wing(flipX: false),
          ),
          // Right wing (mirrored)
          Positioned(
            right: 0,
            child: _Wing(flipX: true),
          ),
          // Body dot
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF2D7B60),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wing extends StatelessWidget {
  final bool flipX;
  const _Wing({required this.flipX});

  @override
  Widget build(BuildContext context) {
    final wing = Container(
      width: 20,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF96).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(8),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
    );

    final animatedWing = wing
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleX(
          begin: 1.0,
          end: 0.15,
          duration: 300.ms,
          curve: Curves.easeInOut,
        );

    return flipX
        ? Transform.scale(
            scaleX: -1,
            alignment: Alignment.centerRight,
            child: animatedWing,
          )
        : animatedWing;
  }
}
