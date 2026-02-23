import 'package:flutter/foundation.dart';
import '../ai/mchat_ai_service.dart';
import '../data/datasources/mchat_questions_data.dart';
import '../data/models/follow_up_conversation.dart';
import '../data/models/mchat_question.dart';
import '../data/models/screening_session.dart';
import '../data/repositories/screening_history_repository.dart';
import 'assessment_provider.dart';

/// Manages all AI intelligence state for the M-CHAT-R module.
/// Completely separate from AssessmentProvider — scoring is never touched here.
class MchatAiProvider extends ChangeNotifier {
  MchatAiProvider() {
    loadHistory();
  }

  final MchatAiService _service = MchatAiService();
  final ScreeningHistoryRepository _historyRepo = ScreeningHistoryRepository();

  // ─── Follow-up State ─────────────────────────────────────────────────────────

  /// Map of questionId → its follow-up conversation.
  final Map<int, FollowUpConversation> _conversations = {};

  /// The AI text currently streaming into a follow-up bubble.
  String _streamingFollowUpText = '';
  bool _isFollowUpStreaming = false;
  int? _activeFollowUpQuestionId;

  Map<int, FollowUpConversation> get conversations =>
      Map.unmodifiable(_conversations);
  String get streamingFollowUpText => _streamingFollowUpText;
  bool get isFollowUpStreaming => _isFollowUpStreaming;
  int? get activeFollowUpQuestionId => _activeFollowUpQuestionId;

  // ─── Interpretation / Report State ───────────────────────────────────────────

  String _interpretationText = '';
  bool _isGeneratingInterpretation = false;
  String _reportText = '';
  bool _isGeneratingReport = false;
  String _comparisonText = '';
  bool _isGeneratingComparison = false;

  String get interpretationText => _interpretationText;
  bool get isGeneratingInterpretation => _isGeneratingInterpretation;
  String get reportText => _reportText;
  bool get isGeneratingReport => _isGeneratingReport;
  String get comparisonText => _comparisonText;
  bool get isGeneratingComparison => _isGeneratingComparison;

  // ─── History State ────────────────────────────────────────────────────────────

  List<ScreeningSession> _history = [];
  bool _isLoadingHistory = false;

  List<ScreeningSession> get history => List.unmodifiable(_history);
  bool get isLoadingHistory => _isLoadingHistory;

  // ─── Follow-up Actions ────────────────────────────────────────────────────────

  /// Starts the first AI probe for a risk-positive answer.
  /// Creates a new [FollowUpConversation] and streams the opening question.
  Future<void> startFollowUp({
    required MchatQuestion question,
    required bool answer,
  }) async {
    _activeFollowUpQuestionId = question.id;
    _streamingFollowUpText = '';
    _isFollowUpStreaming = true;

    // Ensure conversation object exists
    _conversations[question.id] ??= FollowUpConversation(
      questionId: question.id,
    );
    notifyListeners();

    final buffer = StringBuffer();
    await for (final chunk in _service.streamFirstFollowUp(
      question: question,
      answer: answer,
    )) {
      buffer.write(chunk);
      _streamingFollowUpText = buffer.toString();
      notifyListeners();
    }

    // Commit streamed text as an AI message
    final finalText = buffer.toString();
    if (finalText.isNotEmpty) {
      final conv = _conversations[question.id]!;
      _conversations[question.id] = conv.copyWith(
        aiMessages: [...conv.aiMessages, finalText],
      );
    }

    _streamingFollowUpText = '';
    _isFollowUpStreaming = false;
    notifyListeners();
  }

  /// Submits a parent reply and streams the AI's continuation response.
  Future<void> replyToFollowUp({
    required MchatQuestion question,
    required bool originalAnswer,
    required String parentReply,
  }) async {
    if (parentReply.trim().isEmpty) return;

    final existingConv =
        _conversations[question.id] ??
        FollowUpConversation(questionId: question.id);

    // Append parent reply immediately
    _conversations[question.id] = existingConv.copyWith(
      parentReplies: [...existingConv.parentReplies, parentReply.trim()],
    );

    _streamingFollowUpText = '';
    _isFollowUpStreaming = true;
    notifyListeners();

    final buffer = StringBuffer();
    await for (final chunk in _service.streamContinuationFollowUp(
      question: question,
      originalAnswer: originalAnswer,
      conversation: _conversations[question.id]!,
      latestParentReply: parentReply,
    )) {
      buffer.write(chunk);
      _streamingFollowUpText = buffer.toString();
      notifyListeners();
    }

    final finalText = buffer.toString();
    if (finalText.isNotEmpty) {
      final conv = _conversations[question.id]!;
      _conversations[question.id] = conv.copyWith(
        aiMessages: [...conv.aiMessages, finalText],
      );
    }

    _streamingFollowUpText = '';
    _isFollowUpStreaming = false;
    notifyListeners();
  }

  /// Returns the list of failed-question ids that have no conversation yet.
  List<int> pendingFollowUps(AssessmentProvider assessment) {
    return _failedQuestions(assessment)
        .where((q) => !(_conversations[q.id]?.hasContent ?? false))
        .map((q) => q.id)
        .toList();
  }

  // ─── Interpretation / Report ─────────────────────────────────────────────────

  /// Streams full behaviour interpretation from all risk-positive questions.
  Future<void> generateInterpretation(AssessmentProvider assessment) async {
    if (_isGeneratingInterpretation) return;
    _interpretationText = '';
    _isGeneratingInterpretation = true;
    notifyListeners();

    final failed = _failedQuestions(assessment);
    final convList = conversations.values.toList();

    await for (final chunk in _service.streamInterpretation(
      failedQuestions: failed,
      conversations: convList,
      riskScore: assessment.riskScore,
      riskLevel: assessment.riskLevel,
    )) {
      _interpretationText += chunk;
      notifyListeners();
    }

    _isGeneratingInterpretation = false;
    notifyListeners();
  }

  /// Streams the full structured screening report.
  Future<void> generateReport(AssessmentProvider assessment) async {
    if (_isGeneratingReport) return;
    _reportText = '';
    _isGeneratingReport = true;
    notifyListeners();

    await for (final chunk in _service.streamReport(
      answers: assessment.answers,
      conversations: conversations.values.toList(),
      riskScore: assessment.riskScore,
      riskLevel: assessment.riskLevel,
      interpretationText: _interpretationText.isNotEmpty
          ? _interpretationText
          : null,
    )) {
      _reportText += chunk;
      notifyListeners();
    }

    _isGeneratingReport = false;
    notifyListeners();
  }

  /// Compares the most recent past session against a chosen session.
  Future<void> compareWithSession({
    required ScreeningSession current,
    required ScreeningSession previous,
  }) async {
    if (_isGeneratingComparison) return;
    _comparisonText = '';
    _isGeneratingComparison = true;
    notifyListeners();

    await for (final chunk in _service.streamComparison(
      current: current,
      previous: previous,
    )) {
      _comparisonText += chunk;
      notifyListeners();
    }

    _isGeneratingComparison = false;
    notifyListeners();
  }

  // ─── History ─────────────────────────────────────────────────────────────────

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    _history = await _historyRepo.loadAllSessions();
    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Assembles and saves a [ScreeningSession] from the current assessment state.
  Future<ScreeningSession> saveCompletedSession(
    AssessmentProvider assessment,
  ) async {
    final session = ScreeningSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      answers: assessment.answers,
      riskScore: assessment.riskScore,
      riskLevel: assessment.riskLevel,
      conversations: _conversations.values.toList(),
      interpretationReport: _interpretationText.isNotEmpty
          ? _interpretationText
          : null,
      fullReport: _reportText.isNotEmpty ? _reportText : null,
    );

    await _historyRepo.saveSession(session);
    _history = await _historyRepo.loadAllSessions();
    notifyListeners();
    return session;
  }

  /// Clears all AI state for a fresh session.
  void reset() {
    _conversations.clear();
    _streamingFollowUpText = '';
    _isFollowUpStreaming = false;
    _activeFollowUpQuestionId = null;
    _interpretationText = '';
    _reportText = '';
    _comparisonText = '';
    notifyListeners();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  List<MchatQuestion> _failedQuestions(AssessmentProvider assessment) {
    return kMchatQuestions.where((q) {
      final ans = assessment.getAnswer(q.id);
      if (ans == null) return false;
      return (q.riskWhenAnswerYes && ans) || (!q.riskWhenAnswerYes && !ans);
    }).toList();
  }
}
