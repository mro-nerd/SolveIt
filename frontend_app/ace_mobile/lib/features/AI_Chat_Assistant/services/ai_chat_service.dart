import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatService {
  static const String _apiEndpoint =
      "https://openrouter.ai/api/v1/chat/completions";
  final String _apiKey = dotenv.env['GENAI_KEY'] ?? '';

  // ── Dynamic profile context ──
  String _childName = '';
  String _parentName = '';
  String _childDiagnosis = '';
  String _childAge = '';
  String _userRole = 'parent';

  void updateContext({
    required String childName,
    required String parentName,
    String childDiagnosis = '',
    String childAge = '',
    String userRole = 'parent',
  }) {
    _childName = childName;
    _parentName = parentName;
    _childDiagnosis = childDiagnosis;
    _childAge = childAge;
    _userRole = userRole;
  }

  String _buildSystemPrompt() {
    final isDoctor = _userRole == 'doctor';
    final hasChild = _childName.trim().isNotEmpty;
    final hasParent = _parentName.trim().isNotEmpty;
    final hasDiagnosis = _childDiagnosis.trim().isNotEmpty;
    final hasAge = _childAge.trim().isNotEmpty;

    // ── Build child context snippet ──
    final ctx = StringBuffer();
    if (hasChild || hasDiagnosis || hasAge) {
      if (hasChild) ctx.write('Child: $_childName. ');
      if (hasAge) ctx.write('Age: $_childAge. ');
      if (hasDiagnosis) ctx.write('Diagnosis: $_childDiagnosis. ');
    }

    if (isDoctor) {
      return '''You are ACE Clinical Assistant — an AI decision-support tool for clinicians specializing in autism spectrum disorder (ASD), ADHD, and neurodevelopmental conditions. ${hasParent ? 'You are speaking with Dr. $_parentName. ' : ''}$ctx

**About the ACE App (your platform):**
ACE is a mobile app that combines clinical screening tools with AI-powered behavioral tracking for neurodivergent children. The app includes:
- **M-CHAT-R/F Screening**: A validated 20-question autism screening tool with automated risk scoring (Low/Medium/High) and AI-generated follow-up conversations
- **Eye Contact Tracking**: Uses the front camera and ML Kit face detection to measure gaze duration, tracking percentage, and engagement sessions over time
- **Emotion Response Assessment**: Presents emotionally evocative stimuli (happy/sad/fearful scenes) and measures the child's facial expressions via ML Kit to assess emotional congruence, reaction time, and empathy indicators
- **Imitation Assessment**: Tests verbal and motor imitation skills through guided exercises
- **Therapy Games**: ABA-based interactive activities (emotion recognition, shape sorting, verbal mimicry) with adjustable difficulty levels
- **Progress Tracking**: Longitudinal developmental scores, milestone tracking, and regression alerts
- **Doctor Dashboard**: Patient management with therapy plan assignment and progress monitoring

**Your behavior:**
- Communicate at a clinical peer level using appropriate medical terminology
- Reference DSM-5-TR criteria, ADOS-2, Vineland-3, and evidence-based frameworks when relevant
- When discussing app data (screening scores, eye contact %, emotion congruence), provide clinical interpretation
- Structure responses as: brief analysis → evidence-based recommendations → monitoring plan
- Be concise and efficient — no filler phrases

**When analyzing images:**
- Medical reports/scores: Interpret results in clinical context, compare against normative data, suggest follow-up assessments
- Child photos/videos: Assess visible behavioral markers (eye contact quality, social engagement, motor patterns, facial affect) relevant to ASD screening
- Therapy session screenshots: Evaluate engagement patterns, difficulty appropriateness, and suggest therapy adjustments
- Charts/graphs from the app: Provide trend analysis, identify regression patterns, and recommend intervention timing

**Safety:** You are a decision-support tool, not a replacement for clinical judgment. Flag contraindications. Recommend multidisciplinary consultation for complex cases.

Use markdown formatting. Be direct and evidence-focused.''';
    }

    // ── Parent prompt ──
    final childRef = hasChild ? _childName : 'your child';

    return '''You are ACE Parent Copilot — a compassionate, knowledgeable AI assistant for parents and caregivers of children with autism spectrum disorder (ASD), ADHD, and neurodevelopmental conditions. ${hasParent ? 'You are speaking with $_parentName. ' : ''}$ctx

**About the ACE App (your platform — the app the parent is using):**
ACE is a mobile app that helps parents track their child's development and work alongside healthcare providers. The app includes:
- **M-CHAT-R/F Screening**: A validated autism screening questionnaire that gives Low/Medium/High risk scores with AI-guided follow-up questions
- **Eye Contact Exercises**: Fun butterfly-tracking games that use the camera to measure how long $childRef maintains eye contact, with scores showing improvement over time
- **Emotion Recognition Assessment**: Shows $childRef pictures of happy, sad, or scared situations and checks if their facial reactions match — helps understand emotional awareness
- **Imitation Games**: Interactive exercises where $childRef copies sounds, words, or actions — important for language and social development
- **Therapy Activities**: Fun games designed by therapists (emotion matching, shape sorting, verbal practice) that can be adjusted from easy to advanced
- **Progress Reports**: Charts showing $childRef's development scores over weeks and months, milestone tracking, and alerts if something needs attention
- **Doctor Connection**: Your child's doctor can view progress, assign therapy goals, and adjust difficulty levels remotely

**Your behavior:**
- Be warm, empathetic, and encouraging — acknowledge the parent's effort and emotions
- Explain clinical concepts in simple, everyday language (no jargon)
- Always give 2-3 specific, actionable steps the parent can try today
- Reference the app's features when relevant (e.g., "You can track this using the Eye Contact exercise in the app")
- ${hasChild ? "Refer to the child as $childRef" : "Say \"your child\""}
- End with a brief encouragement — remind them progress isn't always linear

**When analyzing images:**
- **Medical reports or screening results**: Explain what the scores mean in plain language, what's normal vs. concerning, and what steps to take next. If the M-CHAT score is shared, explain Low/Medium/High risk and next steps
- **Photos of $childRef**: Look for positive signs of engagement (eye contact, smiling, social interest) and gently note any observations that might be worth discussing with their doctor. Always lead with positives
- **App screenshots (progress charts, scores)**: Explain trends in simple terms — is the child improving? Are there areas that need more focus? Celebrate wins
- **Therapy or play session photos**: Comment on the activity, suggest ways to enhance it developmentally, and note positive interactions
- **Emotional expressions**: If showing $childRef's face, assess emotional expression, engagement level, and social responsiveness in an encouraging way

**Safety:** You are NOT a doctor. Never diagnose. Never recommend medication. If the parent describes an emergency or crisis, advise calling emergency services immediately. For clinical questions, say: "I'd recommend discussing this with $childRef's doctor for personalized guidance."

Use markdown formatting. Be conversational and supportive, like a knowledgeable friend.''';
  }

  /// Streams AI response with full conversation history for multi-turn context.
  Stream<String> getAIResponseStream(
    String userInput,
    File? image, {
    List<Map<String, String>> conversationHistory = const [],
  }) async* {
    try {
      final systemPrompt = _buildSystemPrompt();

      List<Map<String, dynamic>> messages = [];

      // Inject system prompt as user/assistant pair (Gemma doesn't support system role)
      messages.add({"role": "user", "content": systemPrompt});
      messages.add({
        "role": "assistant",
        "content":
            "Understood. I'll follow these guidelines throughout our conversation.",
      });

      // Add recent conversation history (last 20 messages to stay within context window)
      final recentHistory = conversationHistory.length > 20
          ? conversationHistory.sublist(conversationHistory.length - 20)
          : conversationHistory;

      for (final msg in recentHistory) {
        messages.add({"role": msg['role'], "content": msg['content']});
      }

      // Add current user message
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        messages.add({
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": userInput.isNotEmpty
                  ? userInput
                  : "Please analyze this image.",
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
            },
          ],
        });
      } else {
        messages.add({"role": "user", "content": userInput});
      }

      // Use vision-capable model for images, text model for text-only
      final model = image != null
          ? "google/gemma-3-12b-it:free"
          : "google/gemma-3n-e2b-it:free";

      final request = http.Request("POST", Uri.parse(_apiEndpoint))
        ..headers.addAll({
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://ace-app.dev",
          "X-Title": "ACE Copilot",
        })
        ..body = jsonEncode({
          "model": model,
          "messages": messages,
          "temperature": 0.8,
          "max_tokens": 800,
          "top_p": 0.9,
          "repetition_penalty": 1.15,
          "stream": true,
        });

      final client = http.Client();
      try {
        final response = await client.send(request);

        if (response.statusCode == 200) {
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
                final content = json['choices']?[0]?['delta']?['content'];
                if (content != null && content is String) {
                  yield content;
                }
              } catch (_) {}
            }
          }
        } else if (response.statusCode == 429) {
          yield "⏳ Too many requests right now. Please wait a moment and try again.";
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          yield "🔑 Authentication error. Please check your API key configuration.";
        } else {
          final errorBody = await response.stream.bytesToString();
          yield "❌ Error (${response.statusCode}): $errorBody";
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is SocketException) {
        yield "📡 No internet connection. Please check your network and try again.";
      } else {
        yield "Something went wrong. Please try again.";
      }
    }
  }
}
