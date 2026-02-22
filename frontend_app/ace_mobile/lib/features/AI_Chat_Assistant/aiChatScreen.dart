import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import 'ai_chat_provider.dart';

/// The main Chat Screen for the AI Assistant.
/// It uses the AIChatProvider to manage state and AIChatService for responses.
class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the screen in a ChangeNotifierProvider to manage the chat state.
    // If you already have a global provider setup, you can move this higher in the tree.
    return ChangeNotifierProvider(
      create: (_) => AIChatProvider(),
      child: const _AIChatScreenContent(),
    );
  }
}

class _AIChatScreenContent extends StatefulWidget {
  const _AIChatScreenContent();

  @override
  State<_AIChatScreenContent> createState() => _AIChatScreenContentState();
}

class _AIChatScreenContentState extends State<_AIChatScreenContent> {
  final ScrollController _scrollController = ScrollController();

  /// Automatically scrolls to the bottom when a new message arrives.
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
    final chatProvider = Provider.of<AIChatProvider>(context);
    const purpleBg = Color(0xFFF8F7FF);

    return Scaffold(
      backgroundColor: purpleBg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // 1. Subheader: "Talking about Diego"
          _buildSubHeader(),

          // 2. Chat History Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount:
                  chatProvider.messages.length +
                  1, // +1 for the date separator or chips
              itemBuilder: (context, index) {
                // Show a date separator at the very top
                if (index == 0) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "TODAY",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                final message = chatProvider.messages[index - 1];
                return ChatBubble(message: message);
              },
            ),
          ),

          // 3. Quick Action Chips (e.g., Explain report, Behavior tip)
          _buildQuickActions(chatProvider),

          // 4. Input Area
          ChatInput(
            onSendMessage: (text, image) {
              chatProvider.sendMessage(text, image: image);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  /// Builds the custom AppBar seen in the design
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF311B92),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            "Parent Copilot",
            style: TextStyle(
              color: Color(0xFF311B92),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                "ONLINE",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.info_outline, color: Color(0xFF311B92)),
        ),
      ],
    );
  }

  /// Builds the "Talking about Diego" indicator
  Widget _buildSubHeader() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.face, size: 16, color: Color(0xFF311B92)),
            SizedBox(width: 8),
            Text(
              "Talking about Diego",
              style: TextStyle(
                color: Color(0xFF311B92),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ).withValue(alpha: 0.8), // Custom styling to match image
      ),
    );
  }

  /// Builds the horizontal list of suggested questions/actions
  Widget _buildQuickActions(AIChatProvider provider) {
    final actions = ["Explain report", "Behavior tip", "Next steps"];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              actions[index],
              style: const TextStyle(
                color: Color(0xFF311B92),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE8EAF6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () {
              provider.sendMessage(actions[index]);
              _scrollToBottom();
            },
          );
        },
      ),
    );
  }
}

// Extension to help with transparency since withValues might not be in all Flutter versions yet
extension WidgetExt on Widget {
  Widget withValue({required double alpha}) {
    return Opacity(opacity: alpha, child: this);
  }
}
