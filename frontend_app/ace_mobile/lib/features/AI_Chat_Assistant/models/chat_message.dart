import 'dart:io';

/// This enum defines the type of sender for each message.
/// [User] represents the person using the app.
/// [AI] represents the Parent Copilot assistant.
enum MessageSender { User, AI }

/// This class represents a single message in the chat.
/// It holds the text, timestamp, sender info, and optional images.
class ChatMessage {
  final String text; // The message content
  final DateTime timestamp; // When the message was sent
  final MessageSender sender; // Who sent it? (User or AI)
  final File? imageFile; // Optional image attachment for user messages
  final bool isTyping; // Special flag for the animated typing indicator

  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.sender,
    this.imageFile,
    this.isTyping = false,
  });

  /// Factory constructor for the special Typing Indicator message
  factory ChatMessage.typing() {
    return ChatMessage(
      text: "",
      timestamp: DateTime.now(),
      sender: MessageSender.AI,
      isTyping: true,
    );
  }
}
