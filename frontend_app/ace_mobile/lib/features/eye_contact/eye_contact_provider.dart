import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ace_mobile/backend/backend.dart';

class EyeContactProvider extends ChangeNotifier {
  // ── Configuration ───────────────────────────────────────────────────────
  /// Maximum yaw angle (degrees) that maps to the butterfly at the screen edge.
  static const double _maxYaw = 25.0;

  /// Grace period in seconds after session start where frames are not scored.
  static const int _graceSeconds = 2;

  // ── Services ────────────────────────────────────────────────────────────
  final SessionService _sessionService = SessionService();

  // ── State ────────────────────────────────────────────────────────────────
  bool _sessionActive = false;
  double _score = 0.0;
  int _sessionDurationSeconds = 30;
  int _totalFrameCount = 0;
  double _scoreSum = 0.0;

  /// Butterfly's current normalized X position [-1, +1].
  double _butterflyX = 0.0;

  /// Timestamp when the session started (for grace period).
  DateTime? _sessionStart;

  // ── Session saving state ────────────────────────────────────────────────
  bool _isSaving = false;
  String? _saveError;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get sessionActive => _sessionActive;
  double get score => _score;
  int get sessionDurationSeconds => _sessionDurationSeconds;
  int get totalFrameCount => _totalFrameCount;
  bool get isSaving => _isSaving;
  String? get saveError => _saveError;

  /// Number of frames that scored ≥ 0.5 (i.e. "mostly aligned").
  int get alignedFrameCount => _alignedFrameCount;
  int _alignedFrameCount = 0;

  /// Whether we are still in the grace period.
  bool get inGracePeriod {
    if (_sessionStart == null) return false;
    return DateTime.now().difference(_sessionStart!).inSeconds < _graceSeconds;
  }

  // ── Methods ──────────────────────────────────────────────────────────────

  /// Updates the butterfly's normalized X position.
  void updateButterflyPosition(double normalizedX) {
    _butterflyX = normalizedX;
  }

  /// Called by [EyeTrackingOverlay.onGazeYaw] with the smoothed yaw angle.
  /// Scores the frame and updates the running average.
  void recordGazeYaw(double yawAngle) {
    if (!_sessionActive) return;
    if (inGracePeriod) return;

    final expectedYaw = _butterflyX * _maxYaw;
    final deviation = (yawAngle - expectedYaw).abs();
    final frameScore = max(0.0, 1.0 - (deviation / _maxYaw));

    _totalFrameCount++;
    _scoreSum += frameScore;
    if (frameScore >= 0.5) _alignedFrameCount++;

    _score = (_scoreSum / _totalFrameCount).clamp(0.0, 1.0);

    notifyListeners();
  }

  /// Starts a new session, optionally overriding the duration.
  void startSession({int durationSeconds = 30}) {
    _sessionDurationSeconds = durationSeconds;
    _sessionActive = true;
    _totalFrameCount = 0;
    _alignedFrameCount = 0;
    _scoreSum = 0.0;
    _score = 0.0;
    _butterflyX = 0.0;
    _sessionStart = DateTime.now();
    _saveError = null;
    notifyListeners();
  }

  /// Ends the current session and freezes the final score.
  void endSession() {
    _sessionActive = false;
    notifyListeners();
    // Session save is now deferred — call saveSessionForChild() from the UI
  }

  // ── Supabase Session Save ──────────────────────────────────────────────────

  /// Saves the completed eye contact session to Supabase.
  /// [childId] — from ProfileProvider.currentChild['id'].
  Future<void> saveSessionForChild(String childId) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final sustainedMs = (_alignedFrameCount / max(1, _totalFrameCount) * _sessionDurationSeconds * 1000).round();
      final totalMs = _sessionDurationSeconds * 1000;

      // Score: sustained / total as percentage
      final scorePercent = (sustainedMs / totalMs) * 100;

      final rawMetrics = {
        'avg_gaze_score': _score,
        'sustained_ms': sustainedMs,
        'total_ms': totalMs,
        'duration_seconds': _sessionDurationSeconds,
        'total_frames': _totalFrameCount,
        'aligned_frames': _alignedFrameCount,
      };

      final sessionId = await _sessionService.saveSession(
        childId: childId,
        sessionType: 'eye_contact',
        score: scorePercent.clamp(0, 100).toDouble(),
        rawMetrics: rawMetrics,
      );

      debugPrint('[EyeContact] Session saved: $sessionId');
      _triggerAiSummary(sessionId);
    } catch (e) {
      _saveError = 'Failed to save session: $e';
      debugPrint('[EyeContact] Save error: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Placeholder for Day 4 AI summary generation.
  void _triggerAiSummary(String sessionId) {
    debugPrint('[EyeContact] AI summary trigger for $sessionId — not yet implemented');
  }

  /// Resets everything back to initial values without starting a session.
  void reset() {
    _sessionActive = false;
    _score = 0.0;
    _sessionDurationSeconds = 30;
    _totalFrameCount = 0;
    _alignedFrameCount = 0;
    _scoreSum = 0.0;
    _butterflyX = 0.0;
    _sessionStart = null;
    _isSaving = false;
    _saveError = null;
    notifyListeners();
  }
}
