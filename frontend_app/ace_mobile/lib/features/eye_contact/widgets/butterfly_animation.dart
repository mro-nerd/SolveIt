import 'dart:math';
import 'package:flutter/material.dart';

/// A butterfly that traces a figure-8 (lemniscate) path across the FULL arena.
///
/// [onPositionUpdate] is called on every animation frame with the butterfly's
/// **normalized X position** in the range `[-1.0, +1.0]`:
///   -1.0 = far left edge, 0.0 = horizontal centre, +1.0 = far right edge.
class ButterflyAnimation extends StatefulWidget {
  final void Function(double normalizedX)? onPositionUpdate;

  const ButterflyAnimation({super.key, this.onPositionUpdate});

  @override
  State<ButterflyAnimation> createState() => _ButterflyAnimationState();
}

class _ButterflyAnimationState extends State<ButterflyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // 8-second cycle — slow enough for children to follow comfortably.
      duration: const Duration(seconds: 8),
    )..repeat();
    _controller.addListener(_onTick);
  }

  void _onTick() {
    final t = _controller.value * 2 * pi;

    // Lemniscate x ∈ [-1, +1]
    final denom = 1 + pow(sin(t), 2);
    final fx = cos(t) / denom;

    widget.onPositionUpdate?.call(fx.toDouble());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 70; // butterfly widget size

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaW = constraints.maxWidth;
        final areaH = constraints.maxHeight;

        // The butterfly should be Positioned inside a full-size container
        // so that it can move freely across the entire arena.
        return SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value * 2 * pi;

              // Lemniscate of Bernoulli:
              //   x(t) = cos(t) / (1 + sin²(t))          ∈ [-1, +1]
              //   y(t) = sin(t)·cos(t) / (1 + sin²(t))   ∈ [-0.5, +0.5]
              final denom = 1 + pow(sin(t), 2);
              final fx = cos(t) / denom; // -1..1
              final fy = sin(t) * cos(t) / denom; // -0.5..0.5

              // Map to arena pixel coordinates:
              // fx [-1,1] → [margin, areaW - margin - size]
              // fy [-0.5,0.5] → [margin, areaH - margin - size]
              const margin = 10.0;
              final rangeW = areaW - size - 2 * margin;
              final rangeH = areaH - size - 2 * margin;

              final dx = margin + (rangeW / 2) * (1 + fx);
              final dy =
                  margin + (rangeH / 2) * (1 + fy * 2); // *2 to fill height

              // Rotation: butterfly faces its movement direction
              final dt = 0.01;
              final t2 = t + dt;
              final denom2 = 1 + pow(sin(t2), 2);
              final fx2 = cos(t2) / denom2;
              final fy2 = sin(t2) * cos(t2) / denom2;
              final angle = atan2(fy2 - fy, fx2 - fx);

              return Stack(
                children: [
                  Positioned(
                    left: dx.clamp(margin, areaW - size - margin),
                    top: dy.clamp(margin, areaH - size - margin),
                    child: Transform.rotate(angle: angle, child: child),
                  ),
                ],
              );
            },
            child: SizedBox(
              width: size,
              height: size,
              child: const _PaintedButterfly(),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Custom-painted butterfly with realistic wings
// ---------------------------------------------------------------------------

class _PaintedButterfly extends StatefulWidget {
  const _PaintedButterfly();

  @override
  State<_PaintedButterfly> createState() => _PaintedButterflyState();
}

class _PaintedButterflyState extends State<_PaintedButterfly>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flapCtrl;
  late final Animation<double> _flapAnim;

  @override
  void initState() {
    super.initState();
    _flapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..repeat(reverse: true);
    _flapAnim = Tween<double>(
      begin: 1.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _flapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flapAnim,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(70, 70),
          painter: _ButterflyPainter(flapScale: _flapAnim.value),
        );
      },
    );
  }
}

class _ButterflyPainter extends CustomPainter {
  final double flapScale;
  const _ButterflyPainter({required this.flapScale});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Colours ───────────────────────────────────────────────────────────
    final wingMain = Paint()
      ..color = const Color(0xFF4CAF96)
      ..style = PaintingStyle.fill;
    final wingAccent = Paint()
      ..color = const Color(0xFF81D4B8)
      ..style = PaintingStyle.fill;
    final wingSpot = Paint()
      ..color = const Color(0xFFB2EBD6)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF2D7B60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final bodyPaint = Paint()
      ..color = const Color(0xFF2D5A48)
      ..style = PaintingStyle.fill;
    final antPaint = Paint()
      ..color = const Color(0xFF2D5A48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // ── Draw LEFT wing ────────────────────────────────────────────────────
    canvas.save();
    // Scale around the body center to simulate flap (wings fold toward body)
    canvas.translate(cx, cy);
    canvas.scale(flapScale, 1.0);
    canvas.translate(-cx, -cy);

    // Upper-left wing
    final upperL = Path()
      ..moveTo(cx, cy - 4)
      ..cubicTo(cx - 6, cy - 24, cx - 30, cy - 26, cx - 28, cy - 2)
      ..cubicTo(cx - 26, cy + 4, cx - 12, cy + 4, cx, cy + 2)
      ..close();
    canvas.drawPath(upperL, wingMain);
    canvas.drawPath(upperL, outline);

    // Upper-left accent
    final upperAccL = Path()
      ..moveTo(cx - 2, cy - 2)
      ..cubicTo(cx - 5, cy - 16, cx - 20, cy - 18, cx - 20, cy - 2)
      ..cubicTo(cx - 18, cy + 2, cx - 8, cy + 2, cx - 2, cy + 0)
      ..close();
    canvas.drawPath(upperAccL, wingAccent);
    canvas.drawCircle(Offset(cx - 14, cy - 7), 3.0, wingSpot);

    // Lower-left wing
    final lowerL = Path()
      ..moveTo(cx, cy + 2)
      ..cubicTo(cx - 10, cy + 6, cx - 24, cy + 12, cx - 18, cy + 22)
      ..cubicTo(cx - 12, cy + 26, cx - 4, cy + 16, cx, cy + 8)
      ..close();
    canvas.drawPath(lowerL, wingMain);
    canvas.drawPath(lowerL, outline);

    final lowerAccL = Path()
      ..moveTo(cx - 2, cy + 4)
      ..cubicTo(cx - 6, cy + 8, cx - 16, cy + 12, cx - 12, cy + 18)
      ..cubicTo(cx - 8, cy + 20, cx - 4, cy + 12, cx - 2, cy + 8)
      ..close();
    canvas.drawPath(lowerAccL, wingAccent);

    canvas.restore();

    // ── Draw RIGHT wing ───────────────────────────────────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(flapScale, 1.0);
    canvas.translate(-cx, -cy);

    // Upper-right wing
    final upperR = Path()
      ..moveTo(cx, cy - 4)
      ..cubicTo(cx + 6, cy - 24, cx + 30, cy - 26, cx + 28, cy - 2)
      ..cubicTo(cx + 26, cy + 4, cx + 12, cy + 4, cx, cy + 2)
      ..close();
    canvas.drawPath(upperR, wingMain);
    canvas.drawPath(upperR, outline);

    final upperAccR = Path()
      ..moveTo(cx + 2, cy - 2)
      ..cubicTo(cx + 5, cy - 16, cx + 20, cy - 18, cx + 20, cy - 2)
      ..cubicTo(cx + 18, cy + 2, cx + 8, cy + 2, cx + 2, cy + 0)
      ..close();
    canvas.drawPath(upperAccR, wingAccent);
    canvas.drawCircle(Offset(cx + 14, cy - 7), 3.0, wingSpot);

    // Lower-right wing
    final lowerR = Path()
      ..moveTo(cx, cy + 2)
      ..cubicTo(cx + 10, cy + 6, cx + 24, cy + 12, cx + 18, cy + 22)
      ..cubicTo(cx + 12, cy + 26, cx + 4, cy + 16, cx, cy + 8)
      ..close();
    canvas.drawPath(lowerR, wingMain);
    canvas.drawPath(lowerR, outline);

    final lowerAccR = Path()
      ..moveTo(cx + 2, cy + 4)
      ..cubicTo(cx + 6, cy + 8, cx + 16, cy + 12, cx + 12, cy + 18)
      ..cubicTo(cx + 8, cy + 20, cx + 4, cy + 12, cx + 2, cy + 8)
      ..close();
    canvas.drawPath(lowerAccR, wingAccent);

    canvas.restore();

    // ── Body (drawn ON TOP of wings) ─────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 5, height: 24),
        const Radius.circular(3),
      ),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(Offset(cx, cy - 11), 3.5, bodyPaint);

    // ── Antennae ─────────────────────────────────────────────────────────
    final leftAnt = Path()
      ..moveTo(cx - 1, cy - 13)
      ..quadraticBezierTo(cx - 12, cy - 26, cx - 16, cy - 30);
    canvas.drawPath(leftAnt, antPaint);
    canvas.drawCircle(Offset(cx - 16, cy - 30), 1.6, bodyPaint);

    final rightAnt = Path()
      ..moveTo(cx + 1, cy - 13)
      ..quadraticBezierTo(cx + 12, cy - 26, cx + 16, cy - 30);
    canvas.drawPath(rightAnt, antPaint);
    canvas.drawCircle(Offset(cx + 16, cy - 30), 1.6, bodyPaint);
  }

  @override
  bool shouldRepaint(_ButterflyPainter old) => old.flapScale != flapScale;
}
