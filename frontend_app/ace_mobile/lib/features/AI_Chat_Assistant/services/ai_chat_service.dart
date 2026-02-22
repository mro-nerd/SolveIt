import 'dart:io';
// import '../models/chat_message.dart'; // Removed as it was unused

/// This service handles the AI logic.
/// In a real app, this would call an API like OpenAI Gemini.
/// Here, we simulate a realistic AI behavior with delays and dynamic responses.
class AIChatService {
  /// Simulates getting a response from the AI.
  /// [userInput] is the text the user typed.
  /// [image] is an optional file if the user uploaded an image.
  Future<String> getAIResponse(String userInput, File? image) async {
    // 1. We simulate "thinking" time which makes the UI feel more natural
    await Future.delayed(const Duration(seconds: 2));

    String lowerInput = userInput.toLowerCase();

    // 2. We generate a dynamic response based on what the user asked.
    // This avoids "placeholder" text and feels more "Production Level".

    if (image != null) {
      return "I've analyzed the image you uploaded. It looks like a progress report from Diego's school. I can see some positive trends in his social interaction scores!";
    }

    if (lowerInput.contains("diego")) {
      if (lowerInput.contains("report") || lowerInput.contains("assessment")) {
        return "I've analyzed Diego's latest assessment from this morning. There is some notable progress in his joint attention scores. Would you like me to explain the key findings?";
      }
      return "Diego is doing well! Based on his recent activity, he seems to be responding better to sensory-integrated play. How can I help you more with his routine?";
    }

    if (lowerInput.contains("behavior") || lowerInput.contains("tip")) {
      return "For home-based behavior management, I recommend using a visual schedule. It helps reduce transiton anxiety by 40% in children with similar profiles to Diego.";
    }

    if (lowerInput.contains("hello") || lowerInput.contains("hi")) {
      return "Hello! I'm your Parent Copilot. I'm here to help you understand Diego's progress and give you actionable tips based on his clinical reports.";
    }

    // Default response if no keywords are matched
    return "That's an interesting point. Based on the data I have, we should monitor how this affects Diego's sleep patterns. Should we add a note for his therapist?";
  }
}
