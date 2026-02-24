import 'package:flutter/material.dart';

class EyeContactProvider extends ChangeNotifier {
  // ── State ────────────────────────────────────────────────────────────────
  bool _sessionActive = false;
  double _score = 0.0;
  bool _gazeAligned = false;
  int _sessionDurationSeconds = 30;
  int _alignedFrameCount = 0;
  int _totalFrameCount = 0;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get sessionActive => _sessionActive;
  double get score => _score;
  bool get gazeAligned => _gazeAligned;
  int get sessionDurationSeconds => _sessionDurationSeconds;
  int get alignedFrameCount => _alignedFrameCount;
  int get totalFrameCount => _totalFrameCount;

  // ── Methods ──────────────────────────────────────────────────────────────

  /// Starts a new session, optionally overriding the duration.
  void startSession({int durationSeconds = 30}) {
    _sessionDurationSeconds = durationSeconds;
    _sessionActive = true;
    _gazeAligned = false;
    _alignedFrameCount = 0;
    _totalFrameCount = 0;
    _score = 0.0;
    notifyListeners();
  }

  /// Ends the current session and freezes the final score.
  void endSession() {
    _sessionActive = false;
    _gazeAligned = false;
    notifyListeners();
  }

  /// Called once per camera frame.
  /// [wasAligned] — true if the child's gaze matched the butterfly direction.
  void recordFrame(bool wasAligned) {
    if (!_sessionActive) return;

    _totalFrameCount++;
    if (wasAligned) {
      _alignedFrameCount++;
      _gazeAligned = true;
    } else {
      _gazeAligned = false;
    }

    // Score = proportion of aligned frames, clamped to [0.0, 1.0].
    _score = _totalFrameCount > 0
        ? (_alignedFrameCount / _totalFrameCount).clamp(0.0, 1.0)
        : 0.0;

    notifyListeners();
  }

  /// Resets everything back to initial values without starting a session.
  void reset() {
    _sessionActive = false;
    _score = 0.0;
    _gazeAligned = false;
    _sessionDurationSeconds = 30;
    _alignedFrameCount = 0;
    _totalFrameCount = 0;
    notifyListeners();
  }
}
