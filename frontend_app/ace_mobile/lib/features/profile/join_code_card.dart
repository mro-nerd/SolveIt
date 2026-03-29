import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A card that displays the child's 6-character join code for sharing with
/// the doctor. Copy-to-clipboard support included.
class JoinCodeCard extends StatefulWidget {
  final String? joinCode;

  const JoinCodeCard({super.key, required this.joinCode});

  @override
  State<JoinCodeCard> createState() => _JoinCodeCardState();
}

class _JoinCodeCardState extends State<JoinCodeCard>
    with SingleTickerProviderStateMixin {
  bool _copied = false;

  void _copyCode() {
    if (widget.joinCode == null) return;
    Clipboard.setData(ClipboardData(text: widget.joinCode!));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Join code copied!',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: appColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Reset the icon after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.joinCode == null || widget.joinCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appColors.primary,
            appColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor Join Code',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Share with your doctor to connect',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Code display
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatCode(widget.joinCode!),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      key: ValueKey(_copied),
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Center(
            child: Text(
              'Tap to copy',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format "ABCDEF" → "ABC DEF" for readability.
  String _formatCode(String code) {
    if (code.length <= 3) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}
