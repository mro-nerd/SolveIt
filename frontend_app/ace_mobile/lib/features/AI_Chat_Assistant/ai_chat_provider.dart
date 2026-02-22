import 'dart:io';
import 'package:flutter/material.dart';
import 'models/chat_message.dart';
import 'services/ai_chat_service.dart';

/// Provider for managing the state of the AI Chat.
/// Handles user input and listens to the AI's streaming response.
class AIChatProvider with ChangeNotifier {
  final AIChatService _aiService = AIChatService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! I'm your **Parent Copilot**. How can I help you with Diego's progress today?",
      timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
      sender: MessageSender.AI,
    ),
  ];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// 🚀 UPDATED: Now handles STREAMING
  Future<void> sendMessage(String text, {File? image}) async {
    if (text.trim().isEmpty && image == null) return;

    // 1. Add User's message
    _messages.add(
      ChatMessage(
        text: text,
        timestamp: DateTime.now(),
        sender: MessageSender.User,
        imageFile: image,
      ),
    );
    notifyListeners();

    // 2. Add Typing Indicator
    _messages.add(ChatMessage.typing());
    notifyListeners();

    // 3. Start Streaming Response
    try {
      final stream = _aiService.getAIResponseStream(text, image);

      bool firstChunk = true;

      await for (final chunk in stream) {
        if (firstChunk) {
          // Remove the typing indicator when we get the first real piece of data
          _messages.removeLast();

          // Add a new AI message to hold the incoming stream
          _messages.add(
            ChatMessage(
              text: chunk,
              timestamp: DateTime.now(),
              sender: MessageSender.AI,
            ),
          );
          firstChunk = false;
        } else {
          // Append subsequent chunks to the last message
          _messages.last.text += chunk;
        }

        // Notify listeners so UI updates "stream by stream"
        notifyListeners();
      }
    } catch (e) {
      if (_messages.last.isTyping) _messages.removeLast();
      _messages.add(
        ChatMessage(
          text:
              "I encountered an error. Please check your connection or API key.",
          timestamp: DateTime.now(),
          sender: MessageSender.AI,
        ),
      );
      notifyListeners();
    }
  }
}
