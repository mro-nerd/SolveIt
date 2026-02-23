import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/mchat_question.dart';
import '../providers/mchat_ai_provider.dart';
import '../widgets/mchat_chat_bubble.dart';

/// Full-screen follow-up conversation screen shown after a risk-positive answer.
/// Parent can have a back-and-forth dialogue with the AI Specialist.
class FollowUpScreen extends StatefulWidget {
  final MchatQuestion question;
  final bool originalAnswer;

  const FollowUpScreen({
    super.key,
    required this.question,
    required this.originalAnswer,
  });

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFollowUp());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startFollowUp() async {
    if (_hasStarted) return;
    _hasStarted = true;
    final aiProvider = context.read<MchatAiProvider>();
    await aiProvider.startFollowUp(
      question: widget.question,
      answer: widget.originalAnswer,
    );
    _scrollToBottom();
  }

  Future<void> _sendReply(MchatAiProvider aiProvider) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || aiProvider.isFollowUpStreaming) return;

    _inputController.clear();
    await aiProvider.replyToFollowUp(
      question: widget.question,
      originalAnswer: widget.originalAnswer,
      parentReply: text,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MchatAiProvider>(
      builder: (context, aiProvider, _) {
        final conv = aiProvider.conversations[widget.question.id];
        final aiMessages = conv?.aiMessages ?? [];
        final parentReplies = conv?.parentReplies ?? [];
        final isStreaming = aiProvider.isFollowUpStreaming;
        final streamText = aiProvider.streamingFollowUpText;

        // Build interleaved message list
        final List<_ChatEntry> entries = [];
        for (int i = 0; i < aiMessages.length; i++) {
          entries.add(
            _ChatEntry(text: aiMessages[i], side: MchatBubbleSide.ai),
          );
          if (i < parentReplies.length) {
            entries.add(
              _ChatEntry(text: parentReplies[i], side: MchatBubbleSide.parent),
            );
          }
        }

        return Scaffold(
          backgroundColor: appColors.background,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Question context banner
              _QuestionBanner(
                question: widget.question,
                answer: widget.originalAnswer,
              ),

              // Chat messages
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: [
                    ...entries.map(
                      (e) => MchatChatBubble(text: e.text, side: e.side),
                    ),

                    // Currently streaming AI bubble
                    if (isStreaming)
                      MchatChatBubble(
                        text: streamText,
                        side: MchatBubbleSide.ai,
                        isStreaming: true,
                      ),
                  ],
                ),
              ),

              // Input bar
              _InputBar(
                controller: _inputController,
                isStreaming: isStreaming,
                onSend: () => _sendReply(aiProvider),
              ),

              // Done button
              _DoneBar(aiProvider: aiProvider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Color(0xFF1A2B3C)),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            'Follow-up Questions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A2B3C),
            ),
          ),
          Text(
            'Question ${widget.question.id} of 20',
            style: TextStyle(
              fontSize: 11,
              color: appColors.secondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final String text;
  final MchatBubbleSide side;
  const _ChatEntry({required this.text, required this.side});
}

class _QuestionBanner extends StatelessWidget {
  final MchatQuestion question;
  final bool answer;

  const _QuestionBanner({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isRisk =
        (question.riskWhenAnswerYes && answer) ||
        (!question.riskWhenAnswerYes && !answer);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRisk
              ? appColors.red.withValues(alpha: 0.25)
              : appColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (answer ? appColors.green : appColors.red).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              answer ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: answer ? appColors.green : appColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isStreaming,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: isStreaming
                    ? 'Specialist is typing...'
                    : 'Share what you observe...',
                hintStyle: TextStyle(
                  color: appColors.secondary.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B3C)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isStreaming ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isStreaming
                    ? appColors.primary.withValues(alpha: 0.3)
                    : appColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  final MchatAiProvider aiProvider;
  const _DoneBar({required this.aiProvider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: GestureDetector(
          onTap: aiProvider.isFollowUpStreaming
              ? null
              : () => Navigator.pop(context),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: aiProvider.isFollowUpStreaming
                  ? const Color(0xFFE5EBEF)
                  : appColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                aiProvider.isFollowUpStreaming
                    ? 'Please wait...'
                    : 'Done — Continue Assessment',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
