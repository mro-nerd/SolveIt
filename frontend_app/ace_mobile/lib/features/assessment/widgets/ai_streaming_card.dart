import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Reusable card showing streaming AI-generated markdown content.
/// Shows a shimmer while streaming, full text once complete.
class AiStreamingCard extends StatelessWidget {
  final String text;
  final bool isStreaming;
  final String title;
  final IconData icon;
  final Color? accentColor;

  const AiStreamingCard({
    super.key,
    required this.text,
    required this.isStreaming,
    required this.title,
    this.icon = Icons.psychology_rounded,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? appColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: accent,
                    ),
                  ),
                ),
                if (isStreaming)
                  _StreamingBadge(color: accent)
                else if (text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: accent.withValues(alpha: 0.6),
                    tooltip: 'Copy to clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                    },
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: isStreaming && text.isEmpty
                ? _ShimmerPlaceholder()
                : MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        height: 1.7,
                      ),
                      h2: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        height: 2,
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2B3C),
                      ),
                      listBullet: TextStyle(color: accent),
                      blockquoteDecoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: accent, width: 3),
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

class _StreamingBadge extends StatefulWidget {
  final Color color;
  const _StreamingBadge({required this.color});

  @override
  State<_StreamingBadge> createState() => _StreamingBadgeState();
}

class _StreamingBadgeState extends State<_StreamingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Generating',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Column(
          children: List.generate(5, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 13,
              width: i == 4
                  ? MediaQuery.of(context).size.width * 0.45
                  : double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [
                    (_anim.value - 0.3).clamp(0.0, 1.0),
                    _anim.value.clamp(0.0, 1.0),
                    (_anim.value + 0.3).clamp(0.0, 1.0),
                  ],
                  colors: const [
                    Color(0xFFEEF2F5),
                    Color(0xFFDDE6EC),
                    Color(0xFFEEF2F5),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
