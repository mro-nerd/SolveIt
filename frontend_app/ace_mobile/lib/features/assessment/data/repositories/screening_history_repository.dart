import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/screening_session.dart';

/// Repository for persisting and loading M-CHAT-R screening history.
class ScreeningHistoryRepository {
  static const _historyKey = 'mchat_r_screening_history';

  /// Saves a new session to the front of the history list.
  Future<void> saveSession(ScreeningSession session) async {
    final sessions = await loadAllSessions();
    // Remove existing session with same id if re-saving with reports
    sessions.removeWhere((s) => s.id == session.id);
    sessions.insert(0, session);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  /// Loads all past screening sessions, newest first.
  Future<List<ScreeningSession>> loadAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ScreeningSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Removes all history.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
