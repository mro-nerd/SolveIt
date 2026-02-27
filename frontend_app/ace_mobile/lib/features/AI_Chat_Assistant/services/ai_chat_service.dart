import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// This service connects to OpenRouter to provide REAL-TIME streaming AI responses.
class AIChatService {
  static const String _apiEndpoint =
      "https://openrouter.ai/api/v1/chat/completions";
  final String _apiKey = dotenv.env['GENAI_KEY'] ?? '';

  final String _systemPrompt = """
### ROLE
You are the **Parent Copilot**, a clinical-grade but warm AI assistant for parents of neurodivergent children (Autism/ADHD).

### KNOWLEDGE BASE
- Child's Name: Diego
- Current Focus: Joint attention, sensory regulation, and routine consistency.
- Methodology: Evidence-based strategies (ABA, OT, SLP) explained in simple, non-medical terms.

### RESPONSE GUIDELINES
1. **Be Empathetic**: Use phrases like "I understand that's challenging".
2. **Be Actionable**: Always give 2-3 small, practical steps.
3. **Be Structured**: Use bullet points and bold text for clarity.
4. **Visual Analysis**: If an image is provided, analyze its clinical or environmental context.

### OUTPUT
Respond in Markdown.
""";

  /// This returns a Stream of strings, so the UI can update word-by-word.
  Stream<String> getAIResponseStream(String userInput, File? image) async* {
    try {
      List<Map<String, dynamic>> messages = [
        {"role": "system", "content": _systemPrompt},
      ];

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        messages.add({
          "role": "user",
          "content": [
            {"type": "text", "text": userInput},
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
            },
          ],
        });
      } else {
        messages.add({"role": "user", "content": userInput});
      }

      // Step 2: Create a Request
      final request = http.Request("POST", Uri.parse(_apiEndpoint))
        ..headers.addAll({
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://ACE/solveit.com",
          "X-Title": "ACE Parent Copilot",
        })
        ..body = jsonEncode({
          "model": "qwen/qwen3-4b:free",
          "messages": messages,
          "temperature": 0.7,
          "stream": true,
        });

      // Step 3: Send and Listen
      final client = http.Client();
      try {
        final response = await client.send(request);

        if (response.statusCode == 200) {
          // Listen to the response stream byte by byte
          await for (var chunk
              in response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            if (chunk.trim().isEmpty) continue;
            if (chunk.startsWith("data: ")) {
              final dataString = chunk.substring(6).trim();
              if (dataString == "[DONE]") break;

              try {
                final json = jsonDecode(dataString);
                final content = json['choices'][0]['delta']['content'];
                if (content != null) {
                  yield content as String; //PUSH EACH WORD TO THE UI
                }
              } catch (e) {
                // ignored chunks
              }
            }
          }
        } else {
          yield "Error: Failed to connect (Status ${response.statusCode})";
        }
      } finally {
        client.close();
      }
    } catch (e) {
      yield "I'm sorry, I'm having trouble with my connection: $e";
    }
  }
}
