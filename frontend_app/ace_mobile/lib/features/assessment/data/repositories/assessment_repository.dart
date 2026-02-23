import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for persisting and loading M-CHAT-R answers locally.
class AssessmentRepository {
  static const _answersKey = 'mchat_r_answers';
  static const _sessionKey = 'mchat_r_session_active';

  /// Saves the given answers map (questionId → bool) to SharedPreferences.
  Future<void> saveAnswers(Map<int, bool> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      answers.map((k, v) => MapEntry(k.toString(), v)),
    );
    await prefs.setString(_answersKey, encoded);
    await prefs.setBool(_sessionKey, true);
  }

  /// Loads saved answers. Returns empty map if none found.
  Future<Map<int, bool>> loadAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_answersKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), v as bool));
  }

  /// Returns true if a partial or completed session is saved.
  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  /// Removes all saved answers and resets the session flag.
  Future<void> clearAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_answersKey);
    await prefs.remove(_sessionKey);
  }
}
