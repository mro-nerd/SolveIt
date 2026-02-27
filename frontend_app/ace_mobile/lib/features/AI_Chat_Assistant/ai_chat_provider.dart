import 'dart:io';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'models/chat_message.dart';
import 'services/ai_chat_service.dart';

/// Provider for AI Chat state management.
/// Maintains conversation history and passes it to the AI service
/// so the model can produce context-aware, conversational responses.
class AIChatProvider with ChangeNotifier {
  final AIChatService _aiService = AIChatService();
  final ProfileProvider _profileProvider;

  /// Conversation history sent to the API for multi-turn context.
  final List<Map<String, String>> _conversationHistory = [];

  AIChatProvider(this._profileProvider) {
    _updateGreeting();
  }

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void _updateGreeting() {
    final childName = _profileProvider.childName;
    final parentName = _profileProvider.parentName;
    final isDoctor = _profileProvider.isDoctor;

    String greeting;
    if (isDoctor) {
      greeting = parentName.isNotEmpty
          ? "Hello Dr. $parentName! I'm your **ACE Clinical Assistant**. How can I help with your patients today?"
          : "Hello Doctor! I'm your **ACE Clinical Assistant**. How can I help with your patients today?";
    } else {
      final nameRef = childName.isNotEmpty
          ? "**$childName**'s"
          : "your child's";
      greeting = parentName.isNotEmpty
          ? "Hi **$parentName**! 👋 I'm your **Parent Copilot**. How can I help with $nameRef development today?"
          : "Hello! 👋 I'm your **Parent Copilot**. How can I help with $nameRef development today?";
    }

    _messages.add(
      ChatMessage(
        text: greeting,
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
        sender: MessageSender.AI,
      ),
    );

    // Seed the conversation history so the model knows the greeting
    _conversationHistory.add({'role': 'assistant', 'content': greeting});
  }

  void _syncContext() {
    _aiService.updateContext(
      childName: _profileProvider.childName,
      parentName: _profileProvider.parentName,
      childDiagnosis: _profileProvider.childDiagnosis,
      childAge: _calculateAge(_profileProvider.childDob),
      userRole: _profileProvider.userRole,
    );
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty) return '';
    try {
      final birthDate = DateTime.tryParse(dob);
      if (birthDate == null) return '';
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0 && months > 0) return '$years years, $months months';
      if (years > 0) return '$years years';
      if (months > 0) return '$months months';
      return 'Newborn';
    } catch (_) {
      return '';
    }
  }

  Future<void> sendMessage(String text, {File? image}) async {
    if (text.trim().isEmpty && image == null) return;

    // 1. Add user message to UI
    _messages.add(
      ChatMessage(
        text: text,
        timestamp: DateTime.now(),
        sender: MessageSender.User,
        imageFile: image,
      ),
    );
    notifyListeners();

    // 2. Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': text});

    // 3. Show typing indicator
    _messages.add(ChatMessage.typing());
    notifyListeners();

    // 4. Sync profile context
    _syncContext();

    // 5. Stream the response with full conversation history
    try {
      final stream = _aiService.getAIResponseStream(
        text,
        image,
        conversationHistory: _conversationHistory,
      );

      bool firstChunk = true;
      final responseBuffer = StringBuffer();

      await for (final chunk in stream) {
        if (firstChunk) {
          _messages.removeLast(); // remove typing indicator
          _messages.add(
            ChatMessage(
              text: chunk,
              timestamp: DateTime.now(),
              sender: MessageSender.AI,
            ),
          );
          firstChunk = false;
        } else {
          _messages.last.text += chunk;
        }
        responseBuffer.write(chunk);
        notifyListeners();
      }

      // 6. Add the complete AI response to conversation history
      _conversationHistory.add({
        'role': 'assistant',
        'content': responseBuffer.toString(),
      });
    } catch (e) {
      if (_messages.last.isTyping) _messages.removeLast();
      _messages.add(
        ChatMessage(
          text: "I apologize, but I encountered an error. Please try again.",
          timestamp: DateTime.now(),
          sender: MessageSender.AI,
        ),
      );
      notifyListeners();
    }
  }
}
