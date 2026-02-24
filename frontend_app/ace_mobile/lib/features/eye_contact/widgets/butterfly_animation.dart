import 'dart:math';
import 'package:flutter/material.dart';

/// A butterfly that traces a figure-8 (lemniscate of Bernoulli) path across
/// the screen using an [AnimationController] that repeats every 4 seconds.
///
/// [onDirectionUpdate] is called whenever the butterfly crosses the horizontal
/// midpoint, reporting `'left'` or `'right'`.
class ButterflyAnimation extends StatefulWidget {
  /// Called with `'left'` or `'right'` when the butterfly switches halves.
  final void Function(String direction)? onDirectionUpdate;

  const ButterflyAnimation({
    super.key,
    this.onDirectionUpdate,
  });

  @override
  State<ButterflyAnimation> createState() => _ButterflyAnimationState();
}

class _ButterflyAnimationState extends State<ButterflyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _lastDirection = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _controller.addListener(_onTick);
  }

  void _onTick() {
    // x-component of the lemniscate is cos(t)/(1+sin²(t)).
    // It is positive (right half) when cos(t) > 0, negative (left) otherwise.
    final t = _controller.value * 2 * pi;
    final direction = cos(t) >= 0 ? 'right' : 'left';
    if (direction != _lastDirection) {
      _lastDirection = direction;
      widget.onDirectionUpdate?.call(direction);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * pi;

          // Lemniscate of Bernoulli parametric equations:
          //   x(t) = a · cos(t)        / (1 + sin²(t))
          //   y(t) = a · sin(t)·cos(t) / (1 + sin²(t))
          // Scaled so the figure-8 fills ~75 % of the container width.
          final a = (constraints.maxWidth / 2) * 0.75;
          final denom = 1 + pow(sin(t), 2);
          final fx = cos(t) / denom;           // –1 … +1
          final fy = sin(t) * cos(t) / denom;  // –0.5 … +0.5

          // Offset so the centre of the 80×80 widget sits on the path.
          final dx = constraints.maxWidth / 2 + a * fx - 40;
          final dy = constraints.maxHeight / 2 + a * fy - 40;

          return Positioned(
            left: dx.clamp(0, constraints.maxWidth - 80),
            top: dy.clamp(0, constraints.maxHeight - 80),
            child: child!,
          );
        },
        child: const _ButterflyBody(),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _ButterflyBody extends StatelessWidget {
  const _ButterflyBody();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
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
          // Body
          Container(
            width: 8,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF2D7B60),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wing extends StatefulWidget {
  final bool flipX;
  const _Wing({required this.flipX});

  @override
  State<_Wing> createState() => _WingState();
}

class _WingState extends State<_Wing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wing = Container(
      width: 32,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF96).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(10),
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.scale(
        scaleX: widget.flipX ? -_anim.value : _anim.value,
        alignment:
            widget.flipX ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
      child: wing,
    );
  }
}
