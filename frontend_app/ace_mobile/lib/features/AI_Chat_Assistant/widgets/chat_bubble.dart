import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import 'typing_indicator.dart';

/// A widget that renders a single message bubble.
/// It automatically switches styles based on the sender.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.User;

    // Theme colors
    const purplePrimary = Color(0xFF311B92); // Deep purple for User

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // If it's the AI, we show the robot avatar icon on the left
          if (!isUser) ...[
            _buildAvatar(Icons.smart_toy_rounded, purplePrimary),
            const SizedBox(width: 8),
          ],

          // The message bubble itself
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? purplePrimary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // If there's an image, show it
                  if (message.imageFile != null) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          message.imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Show text or the typing indicator
                  if (message.isTyping)
                    const TypingIndicator()
                  else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // If it's the user, we show the read receipt (check marks) on the right
          if (isUser) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const Icon(Icons.done_all, size: 14, color: Colors.blue),
              ],
            ),
          ],

          // For AI, show timestamp below the bubble if not user
          if (!isUser && !message.isTyping) ...[
            const SizedBox(width: 8),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper to build a circular avatar
  Widget _buildAvatar(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
