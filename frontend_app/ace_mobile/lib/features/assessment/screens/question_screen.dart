import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/mchat_question.dart';
import '../providers/assessment_provider.dart';
import '../providers/mchat_ai_provider.dart';
import '../widgets/progress_header.dart';
import '../widgets/question_card.dart';
import '../widgets/yes_no_buttons.dart';
import 'follow_up_screen.dart';
import 'result_screen.dart';

/// Core screen displaying one question at a time.
/// Uses a [PageView] for smooth animated horizontal swipe transitions.
/// After a risk-positive answer, opens [FollowUpScreen] for AI probing.
class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AssessmentProvider>();
    _pageController = PageController(initialPage: provider.currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  bool _isRiskPositive(MchatQuestion question, bool answer) {
    return (question.riskWhenAnswerYes && answer) ||
        (!question.riskWhenAnswerYes && !answer);
  }

  Future<void> _handleAnswer(
    BuildContext context,
    AssessmentProvider provider,
    bool answer,
  ) async {
    final question = provider.currentQuestion;
    final wasLast = provider.isLastQuestion;

    // Record the answer first
    await provider.answerCurrentQuestion(answer);

    if (!context.mounted) return;

    // If risk-positive, open follow-up before advancing
    if (_isRiskPositive(question, answer)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FollowUpScreen(question: question, originalAnswer: answer),
          fullscreenDialog: true,
        ),
      );
      if (!context.mounted) return;
    }

    if (wasLast) {
      // Save session to history when done
      final ai = context.read<MchatAiProvider>();
      await ai.saveCompletedSession(provider);
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ResultScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      _navigateToPage(provider.currentIndex);
    }
  }

  void _handleBack(AssessmentProvider provider) {
    if (provider.currentIndex > 0) {
      provider.goBack();
      _navigateToPage(provider.currentIndex);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack(provider);
          },
          child: Scaffold(
            backgroundColor: appColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  // Fixed header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: ProgressHeader(
                      current: provider.currentIndex + 1,
                      total: provider.questions.length,
                      onBack: () => _handleBack(provider),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scrollable question area
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.questions.length,
                      itemBuilder: (context, index) {
                        final question = provider.questions[index];
                        final currentAnswer = provider.getAnswer(question.id);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Question card
                              QuestionCard(question: question),
                              const SizedBox(height: 28),

                              // Answer prompt
                              Text(
                                'How would you answer?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.secondary.withValues(
                                    alpha: 0.55,
                                  ),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Yes/No buttons
                              YesNoButtons(
                                selectedAnswer: currentAnswer,
                                onAnswer: (answer) =>
                                    _handleAnswer(context, provider, answer),
                              ),
                              const SizedBox(height: 24),

                              // AI follow-up hint (shown after risk answer)
                              if (currentAnswer != null &&
                                  _isRiskPositive(question, currentAnswer))
                                _AiFollowUpHint(
                                  question: question,
                                  answer: currentAnswer,
                                ),

                              const SizedBox(height: 20),

                              // Skip hint
                              AnimatedOpacity(
                                opacity: currentAnswer != null ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  'Select an answer to continue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: appColors.secondary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small hint shown when a risk-positive answer was given — indicates AI probing occurred.
class _AiFollowUpHint extends StatelessWidget {
  final MchatQuestion question;
  final bool answer;

  const _AiFollowUpHint({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Consumer<MchatAiProvider>(
      builder: (context, ai, _) {
        final conv = ai.conversations[question.id];
        final hasNotes = conv?.hasContent ?? false;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FollowUpScreen(question: question, originalAnswer: answer),
              fullscreenDialog: true,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: appColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  hasNotes
                      ? 'AI notes recorded · tap to review'
                      : 'Add AI follow-up notes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: appColors.primary.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
