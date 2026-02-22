import 'dart:io';

enum MessageSender { User, AI }

/// Class representing a chat message.
/// [text] is now mutable to support "streaming" updates from the AI.
class ChatMessage {
  String text; //Modifiable for streaming
  final DateTime timestamp;
  final MessageSender sender;
  final File? imageFile;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.sender,
    this.imageFile,
    this.isTyping = false,
  });

  factory ChatMessage.typing() {
    return ChatMessage(
      text: "",
      timestamp: DateTime.now(),
      sender: MessageSender.AI,
      isTyping: true,
    );
  }
}
