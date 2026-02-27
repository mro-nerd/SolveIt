import 'dart:math';
import 'package:flutter/material.dart';

import 'models/assessment_result.dart';
import 'models/stimulus.dart';
import 'data/stimuli_data.dart';

/// Possible states of the assessment game.
enum AssessmentState { idle, countdown, playing, betweenRounds, done }

class EmotionAssessmentProvider extends ChangeNotifier {
  // ── Configuration ──
  static const int _countdownSeconds = 3;

  // ── State ──
  AssessmentState _state = AssessmentState.idle;
  int _currentRoundIndex = 0;
  int _countdownValue = _countdownSeconds;
  int _roundSecondsLeft = 5;

  /// Per-round collected samples.
  List<EmotionSample> _currentSamples = [];

  /// Timestamp when the current stimulus was shown (for reaction time).
  int? _stimulusShownAtMs;

  /// First time the expected emotion was detected in this round (for reaction time).
  int? _firstMatchAtMs;

  /// Completed round results.
  final List<RoundResult> _roundResults = [];

  /// Overall assessment summary (computed when all rounds are done).
  AssessmentSummary? _summary;

  // ── Getters ──
  AssessmentState get state => _state;
  int get currentRoundIndex => _currentRoundIndex;
  int get countdownValue => _countdownValue;
  int get roundSecondsLeft => _roundSecondsLeft;
  int get totalRounds => kStimuliRounds.length;
  List<RoundResult> get roundResults => List.unmodifiable(_roundResults);
  AssessmentSummary? get summary => _summary;

  Stimulus get currentStimulus => kStimuliRounds[_currentRoundIndex];

  // ── Session control ──

  /// Start the full assessment from round 1.
  void startAssessment() {
    _currentRoundIndex = 0;
    _roundResults.clear();
    _summary = null;
    _beginCountdown();
  }

  void _beginCountdown() {
    _state = AssessmentState.countdown;
    _countdownValue = _countdownSeconds;
    notifyListeners();
  }

  /// Called by the screen's timer each second during countdown.
  void tickCountdown() {
    _countdownValue--;
    if (_countdownValue <= 0) {
      _startRound();
    }
    notifyListeners();
  }

  void _startRound() {
    _state = AssessmentState.playing;
    _currentSamples = [];
    _stimulusShownAtMs = DateTime.now().millisecondsSinceEpoch;
    _firstMatchAtMs = null;
    _roundSecondsLeft = currentStimulus.durationSeconds;
    notifyListeners();
  }

  /// Called by the screen's timer each second during a round.
  void tickRound() {
    _roundSecondsLeft--;
    if (_roundSecondsLeft <= 0) {
      _endRound();
    }
    notifyListeners();
  }

  /// Record a single emotion sample from the camera.
  void recordSample(EmotionSample sample) {
    if (_state != AssessmentState.playing) return;
    _currentSamples.add(sample);

    // Track reaction time: first time the expected emotion is "detected well"
    if (_firstMatchAtMs == null) {
      final score = sample.matchScore(currentStimulus.expectedEmotion);
      if (score >= 0.5) {
        _firstMatchAtMs = sample.timestampMs;
      }
    }
  }

  void _endRound() {
    if (_currentSamples.isEmpty) {
      // No face detected at all — score 0
      _roundResults.add(
        RoundResult(
          stimulus: currentStimulus,
          samples: [],
          reactionTimeMs: 0,
          emotionMatchScore: 0,
          peakIntensity: 0,
        ),
      );
    } else {
      // Compute match scores
      final scores = _currentSamples
          .map((s) => s.matchScore(currentStimulus.expectedEmotion))
          .toList();

      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final peakScore = scores.reduce(max);

      final reactionTime =
          (_firstMatchAtMs != null && _stimulusShownAtMs != null)
          ? _firstMatchAtMs! - _stimulusShownAtMs!
          : 0;

      _roundResults.add(
        RoundResult(
          stimulus: currentStimulus,
          samples: List.of(_currentSamples),
          reactionTimeMs: reactionTime,
          emotionMatchScore: (avgScore * 100).clamp(0, 100),
          peakIntensity: peakScore,
        ),
      );
    }

    // Move to next round or finish
    if (_currentRoundIndex < kStimuliRounds.length - 1) {
      _state = AssessmentState.betweenRounds;
      notifyListeners();
    } else {
      _computeSummary();
      _state = AssessmentState.done;
      notifyListeners();
    }
  }

  /// Move to next round (called by screen after brief "between rounds" pause).
  void nextRound() {
    _currentRoundIndex++;
    _beginCountdown();
  }

  void _computeSummary() {
    if (_roundResults.isEmpty) return;

    final overallScore =
        _roundResults.map((r) => r.emotionMatchScore).reduce((a, b) => a + b) /
        _roundResults.length;

    final reactionTimes = _roundResults
        .where((r) => r.reactionTimeMs > 0)
        .map((r) => r.reactionTimeMs.toDouble())
        .toList();
    final avgReaction = reactionTimes.isEmpty
        ? 0.0
        : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Emotional variability: stddev of match scores (lower = more consistent)
    final mean = overallScore;
    final variance =
        _roundResults
            .map((r) => pow(r.emotionMatchScore - mean, 2))
            .reduce((a, b) => a + b) /
        _roundResults.length;
    final stddev = sqrt(variance);
    final variability = (stddev / 100).clamp(0.0, 1.0);

    // Empathy score: average of sad-stimulus rounds only
    final sadRounds = _roundResults
        .where((r) => r.stimulus.expectedEmotion == ExpectedEmotion.sad)
        .toList();
    final empathyScore = sadRounds.isEmpty
        ? 0.0
        : sadRounds.map((r) => r.emotionMatchScore).reduce((a, b) => a + b) /
              sadRounds.length;

    _summary = AssessmentSummary(
      roundResults: List.of(_roundResults),
      overallScore: overallScore,
      avgReactionTimeMs: avgReaction,
      emotionalVariability: variability,
      empathyScore: empathyScore,
    );
  }

  /// Reset to idle state.
  void reset() {
    _state = AssessmentState.idle;
    _currentRoundIndex = 0;
    _countdownValue = _countdownSeconds;
    _roundSecondsLeft = 5;
    _currentSamples = [];
    _stimulusShownAtMs = null;
    _firstMatchAtMs = null;
    _roundResults.clear();
    _summary = null;
    notifyListeners();
  }
}
