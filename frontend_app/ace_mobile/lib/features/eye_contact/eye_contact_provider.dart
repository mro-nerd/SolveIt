import 'dart:math';
import 'package:flutter/material.dart';

class EyeContactProvider extends ChangeNotifier {
  // ── Configuration ───────────────────────────────────────────────────────
  /// Maximum yaw angle (degrees) that maps to the butterfly at the screen edge.
  /// ML Kit typically returns ±30° for head turns on a phone-sized screen.
  static const double _maxYaw = 25.0;

  /// Grace period in seconds after session start where frames are not scored.
  static const int _graceSeconds = 2;

  // ── State ────────────────────────────────────────────────────────────────
  bool _sessionActive = false;
  double _score = 0.0;
  int _sessionDurationSeconds = 30;
  int _totalFrameCount = 0;
  double _scoreSum = 0.0;

  /// Butterfly's current normalized X position [-1, +1].
  double _butterflyX = 0.0;

  /// Child's latest smoothed yaw angle (degrees).
  double _gazeYaw = 0.0;

  /// Timestamp when the session started (for grace period).
  DateTime? _sessionStart;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get sessionActive => _sessionActive;
  double get score => _score;
  int get sessionDurationSeconds => _sessionDurationSeconds;
  int get totalFrameCount => _totalFrameCount;

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
  /// Called by [ButterflyAnimation.onPositionUpdate] on every animation frame.
  void updateButterflyPosition(double normalizedX) {
    _butterflyX = normalizedX;
    // No notifyListeners — this fires at 60 Hz; scoring happens in recordGazeYaw.
  }

  /// Called by [EyeTrackingOverlay.onGazeYaw] with the smoothed yaw angle.
  /// Scores the frame and updates the running average.
  void recordGazeYaw(double yawAngle) {
    _gazeYaw = yawAngle;
    if (!_sessionActive) return;
    if (inGracePeriod) return; // Don't score during grace period.

    // ── Map butterfly X to an expected yaw angle ──
    // butterflyX ∈ [-1, +1]  →  expectedYaw ∈ [-_maxYaw, +_maxYaw]
    final expectedYaw = _butterflyX * _maxYaw;

    // ── Per-frame score: how close is the gaze to the expected yaw? ──
    // Score = 1.0 when perfectly aligned, drops linearly to 0.0 at ±_maxYaw deviation.
    final deviation = (yawAngle - expectedYaw).abs();
    final frameScore = max(0.0, 1.0 - (deviation / _maxYaw));

    _totalFrameCount++;
    _scoreSum += frameScore;
    if (frameScore >= 0.5) _alignedFrameCount++;

    // Running average score.
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
    _gazeYaw = 0.0;
    _butterflyX = 0.0;
    _sessionStart = DateTime.now();
    notifyListeners();
  }

  /// Ends the current session and freezes the final score.
  void endSession() {
    _sessionActive = false;
    notifyListeners();
  }

  /// Resets everything back to initial values without starting a session.
  void reset() {
    _sessionActive = false;
    _score = 0.0;
    _sessionDurationSeconds = 30;
    _totalFrameCount = 0;
    _alignedFrameCount = 0;
    _scoreSum = 0.0;
    _gazeYaw = 0.0;
    _butterflyX = 0.0;
    _sessionStart = null;
    notifyListeners();
  }
}
