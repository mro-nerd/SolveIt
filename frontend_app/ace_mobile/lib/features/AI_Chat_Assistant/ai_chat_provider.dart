import 'dart:io';
import 'package:flutter/material.dart';
import 'models/chat_message.dart';
import 'services/ai_chat_service.dart';

/// This is the heart of our Chat UI logic.
/// It manages the list of messages and tells the UI when to rebuild.
class AIChatProvider with ChangeNotifier {
  final AIChatService _aiService = AIChatService();

  // The internal list of messages
  final List<ChatMessage> _messages = [
    // We start with a greeting from the AI
    ChatMessage(
      text:
          "Hello! I've analyzed Diego's latest assessment from this morning. There is some notable progress in his joint attention scores.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      sender: MessageSender.AI,
    ),
  ];

  /// Returns an unmodifiable list of messages to prevent accidental bugs.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Helper to check if the AI is currently "thinking"
  bool get isAiTyping => _messages.isNotEmpty && _messages.last.isTyping;

  /// Sends a message from the User and triggers the AI response.
  Future<void> sendMessage(String text, {File? image}) async {
    if (text.trim().isEmpty && image == null) return;

    // 1. Add the User's Message
    _messages.add(
      ChatMessage(
        text: text,
        timestamp: DateTime.now(),
        sender: MessageSender.User,
        imageFile: image,
      ),
    );
    notifyListeners(); // Tell the UI to show the user's message immediately

    // 2. Add the "Typing Indicator"
    _messages.add(ChatMessage.typing());
    notifyListeners();

    try {
      // 3. Get response from the AI Service
      final response = await _aiService.getAIResponse(text, image);

      // 4. Remove the typing indicator and add the real response
      _messages.removeLast(); // Remove the "typing..." message
      _messages.add(
        ChatMessage(
          text: response,
          timestamp: DateTime.now(),
          sender: MessageSender.AI,
        ),
      );
    } catch (e) {
      // Handle errors gracefully
      _messages.removeLast();
      _messages.add(
        ChatMessage(
          text:
              "Sorry, I'm having trouble connecting right now. Please try again.",
          timestamp: DateTime.now(),
          sender: MessageSender.AI,
        ),
      );
    }

    notifyListeners(); // Rebuild UI with the new AI message
  }
}
