import 'package:flutter/foundation.dart';
import 'package:ace_mobile/backend/backend.dart';

/// Session types used across the app.
const kSessionTypes = ['mchat', 'emotion_assessment', 'eye_contact', 'imitation'];

/// Human-readable labels for session types.
const kSessionTypeLabels = {
  'mchat': 'M-CHAT',
  'emotion_assessment': 'Emotion',
  'eye_contact': 'Eye Contact',
  'imitation': 'Imitation',
};

class ProgressProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;
  String? _errorMessage;

  /// All sessions grouped by session_type.
  Map<String, List<Map<String, dynamic>>> _sessionsByType = {};

  /// Latest score per session type.
  Map<String, double?> _latestScores = {};

  /// Score delta (latest - previous) per session type.
  Map<String, double?> _scoreDeltas = {};

  /// Risk status from child profile.
  String _overallRisk = 'pending';

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, List<Map<String, dynamic>>> get sessionsByType => _sessionsByType;
  Map<String, double?> get latestScores => _latestScores;
  Map<String, double?> get scoreDeltas => _scoreDeltas;
  String get overallRisk => _overallRisk;

  bool get hasSessions =>
      _sessionsByType.values.any((list) => list.isNotEmpty);

  // ── Load ─────────────────────────────────────────────────────────────────

  /// Loads the last 10 sessions per type for a given child.
  Future<void> loadSessions(String childId, {String? diagnosisStatus}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _overallRisk = diagnosisStatus ?? 'pending';
      _sessionsByType = {};
      _latestScores = {};
      _scoreDeltas = {};

      for (final type in kSessionTypes) {
        final sessions = await _sessionService.getSessionsForChild(
          childId,
          sessionType: type,
          limit: 10,
        );

        _sessionsByType[type] = sessions;

        if (sessions.isNotEmpty) {
          final latestScore =
              (sessions.first['score'] as num?)?.toDouble();
          _latestScores[type] = latestScore;

          if (sessions.length >= 2) {
            final prevScore =
                (sessions[1]['score'] as num?)?.toDouble() ?? 0;
            _scoreDeltas[type] =
                latestScore != null ? latestScore - prevScore : null;
          } else {
            _scoreDeltas[type] = null; // First session, no delta
          }
        } else {
          _latestScores[type] = null;
          _scoreDeltas[type] = null;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load progress: $e';
      debugPrint('[ProgressProvider] loadSessions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns all sessions flattened and sorted by date (newest first).
  List<Map<String, dynamic>> get allSessionsSorted {
    final all = <Map<String, dynamic>>[];
    for (final list in _sessionsByType.values) {
      all.addAll(list);
    }
    all.sort((a, b) {
      final aDate = a['completed_at'] as String? ?? '';
      final bDate = b['completed_at'] as String? ?? '';
      return bDate.compareTo(aDate);
    });
    return all;
  }

  /// Average of all latest scores.
  double? get averageLatestScore {
    final scores = _latestScores.values.whereType<double>().toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}
