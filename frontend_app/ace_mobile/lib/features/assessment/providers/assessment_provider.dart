import 'package:flutter/foundation.dart';
import '../data/datasources/mchat_questions_data.dart';
import '../data/models/mchat_question.dart';
import '../data/repositories/assessment_repository.dart';

enum AssessmentStatus { idle, inProgress, completed }

/// Provider managing all M-CHAT-R questionnaire state.
/// Exposes questions, current index, answers, and score.
class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider() {
    _loadSession();
  }

  final AssessmentRepository _repository = AssessmentRepository();

  final List<MchatQuestion> questions = kMchatQuestions;
  final Map<int, bool> _answers = {};

  int _currentIndex = 0;
  AssessmentStatus _status = AssessmentStatus.idle;
  bool _hasSavedSession = false;
  bool _isLoading = true;

  // ─── Public Getters ──────────────────────────────────────────────────────────

  int get currentIndex => _currentIndex;
  AssessmentStatus get status => _status;
  bool get hasSavedSession => _hasSavedSession;
  bool get isLoading => _isLoading;

  MchatQuestion get currentQuestion => questions[_currentIndex];

  Map<int, bool> get answers => Map.unmodifiable(_answers);

  bool? getAnswer(int questionId) => _answers[questionId];

  bool get isComplete => _answers.length == questions.length;

  bool get isLastQuestion => _currentIndex == questions.length - 1;

  double get progressFraction =>
      questions.isEmpty ? 0 : _answers.length / questions.length;

  /// Number of risk-positive answers (ASD indicator count).
  int get riskScore {
    int count = 0;
    for (final q in questions) {
      final ans = _answers[q.id];
      if (ans == null) continue;
      // Risk is triggered when:
      //   riskWhenAnswerYes == true  → answer is YES (true)
      //   riskWhenAnswerYes == false → answer is NO  (false)
      if (q.riskWhenAnswerYes && ans == true) count++;
      if (!q.riskWhenAnswerYes && ans == false) count++;
    }
    return count;
  }

  /// Whether the score indicates low, medium, or high risk.
  String get riskLevel {
    if (riskScore <= 2) return 'Low Risk';
    if (riskScore <= 7) return 'Medium Risk';
    return 'High Risk';
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  /// Starts a fresh session (optionally clearing any saved state).
  Future<void> startFresh() async {
    _answers.clear();
    _currentIndex = 0;
    _status = AssessmentStatus.inProgress;
    await _repository.clearAnswers();
    notifyListeners();
  }

  /// Resumes a previously saved session.
  void resumeSession() {
    _status = AssessmentStatus.inProgress;
    // Navigate to first unanswered question
    for (int i = 0; i < questions.length; i++) {
      if (!_answers.containsKey(questions[i].id)) {
        _currentIndex = i;
        break;
      }
    }
    notifyListeners();
  }

  /// Records the answer for the current question and advances to the next.
  Future<void> answerCurrentQuestion(bool answer) async {
    _answers[currentQuestion.id] = answer;
    await _repository.saveAnswers(_answers);

    if (isLastQuestion) {
      _status = AssessmentStatus.completed;
    } else {
      _currentIndex++;
    }
    notifyListeners();
  }

  /// Navigates back to the previous question.
  void goBack() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// Jumps directly to a specific question index (for editing answers).
  void goToQuestion(int index) {
    assert(index >= 0 && index < questions.length);
    _currentIndex = index;
    notifyListeners();
  }

  /// Resets the entire session.
  Future<void> reset() async {
    _answers.clear();
    _currentIndex = 0;
    _status = AssessmentStatus.idle;
    _hasSavedSession = false;
    await _repository.clearAnswers();
    notifyListeners();
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    _hasSavedSession = await _repository.hasActiveSession();
    if (_hasSavedSession) {
      final saved = await _repository.loadAnswers();
      _answers.addAll(saved);
    }

    _isLoading = false;
    notifyListeners();
  }
}
