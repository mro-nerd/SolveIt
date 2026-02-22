import 'package:flutter/material.dart';

/// A custom animated widget that shows three bouncing dots.
/// This mimics the Slack/iMessage/WhatsApp typing indicator.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // We create a controller that repeats the animation indefinitely
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Each dot has a slight delay in its bounce for a "wave" effect
            final double delay = index * 0.2;
            final double value = ((_controller.value - delay) % 1.0);
            final double verticalOffset = (value < 0.5)
                ? -4 * value
                : -4 * (1.0 - value);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, verticalOffset * 2, 0),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF5B3FA2), // Using our purple theme color
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
