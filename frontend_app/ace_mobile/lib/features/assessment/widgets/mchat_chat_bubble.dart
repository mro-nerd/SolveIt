import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum MchatBubbleSide { ai, parent }

/// Reusable streaming chat bubble for M-CHAT follow-up conversations.
class MchatChatBubble extends StatelessWidget {
  final String text;
  final MchatBubbleSide side;
  final bool isStreaming;

  const MchatChatBubble({
    super.key,
    required this.text,
    required this.side,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAI = side == MchatBubbleSide.ai;

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          left: isAI ? 0 : 40,
          right: isAI ? 40 : 0,
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAI
              ? appColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isAI ? 4 : 18),
            bottomRight: Radius.circular(isAI ? 18 : 4),
          ),
          border: isAI
              ? Border.all(color: appColors.primary.withValues(alpha: 0.15))
              : Border.all(color: const Color(0xFFE5EBEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender label for AI
            if (isAI) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: appColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Specialist',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: appColors.primary.withValues(alpha: 0.8),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Message content
            if (isStreaming && text.isEmpty)
              _TypingDots()
            else
              MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    color: isAI ? const Color(0xFF1A2B3C) : appColors.secondary,
                    height: 1.5,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isAI ? appColors.primary : appColors.secondary,
                  ),
                ),
              ),

            // Streaming cursor
            if (isStreaming && text.isNotEmpty) const _BlinkingCursor(),
          ],
        ),
      ),
    );
  }
}

/// Animated typing dots shown while AI is thinking.
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 20,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final offset = (i / 3);
              final value = ((_ctrl.value - offset) % 1.0);
              final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: appColors.primary.withValues(
                    alpha: opacity.clamp(0.2, 1),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Blinking text cursor shown while AI is streaming.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        width: 2,
        height: 14,
        color: appColors.primary,
      ),
    );
  }
}
