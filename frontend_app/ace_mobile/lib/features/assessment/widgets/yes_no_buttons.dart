import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';

/// Animated Yes/No answer button pair.
/// Shows selection state via scale animation and filled color.
class YesNoButtons extends StatelessWidget {
  final bool? selectedAnswer; // null = unanswered
  final ValueChanged<bool> onAnswer;

  const YesNoButtons({
    super.key,
    required this.selectedAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnswerButton(
            label: 'Yes',
            icon: Icons.check_circle_outline_rounded,
            isSelected: selectedAnswer == true,
            isDeselected: selectedAnswer == false,
            selectedColor: appColors.green,
            onTap: () => onAnswer(true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _AnswerButton(
            label: 'No',
            icon: Icons.cancel_outlined,
            isSelected: selectedAnswer == false,
            isDeselected: selectedAnswer == true,
            selectedColor: appColors.red,
            onTap: () => onAnswer(false),
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDeselected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDeselected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.reverse();
    await _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.selectedColor
        : const Color(0xFFE5EBEF);
    final textColor = widget.isSelected ? Colors.white : appColors.secondary;
    final opacity = widget.isDeselected ? 0.45 : 1.0;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            height: 62,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.selectedColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isSelected
                        ? widget.icon
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(widget.isSelected),
                    color: textColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
