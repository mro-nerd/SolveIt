import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:ace_mobile/core/constants.dart';
import '../models/chat_message.dart';
import 'typing_indicator.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.User;

    // 🎨 SYNCING WITH ACE DESIGN SYSTEM
    final Color primary = appColors.primary;
    final Color bubbleColor = isUser ? primary : Colors.white;
    final Color textColor = isUser
        ? Colors.white
        : const Color(0xFF1F2937); // Dark gray for legibility

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Robot Head
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_outlined, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Display
                  if (message.imageFile != null) ...[
                    GestureDetector(
                      onTap: () {
                        // Expansion/Full-screen could go here
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          message.imageFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Content: Typing Indicator or Markdown
                  if (message.isTyping)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: TypingIndicator(),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        strong: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        listBullet: TextStyle(color: textColor),
                        code: GoogleFonts.sourceCodePro(
                          backgroundColor: Colors.grey.shade100,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Icon(Icons.check_circle_outline, size: 12, color: primary),
              ],
            ),
          ],

          if (!isUser && !message.isTyping) ...[
            const SizedBox(width: 8),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
