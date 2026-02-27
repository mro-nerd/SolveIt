import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ace_mobile/core/constants.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import 'ai_chat_provider.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    return ChangeNotifierProvider(
      create: (_) => AIChatProvider(profileProvider),
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

  @override
  void initState() {
    super.initState();
    // Ensure we start at the bottom if there's history
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(immediate: true),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 🚀 PERSISTENT AUTO-SCROLL
  /// [immediate] uses jumpTo for instant placement, otherwise animateTo for smooth flow.
  void _scrollToBottom({bool immediate = false}) {
    if (_scrollController.hasClients) {
      final bottom = _scrollController.position.maxScrollExtent;
      if (immediate) {
        _scrollController.jumpTo(bottom);
      } else {
        _scrollController.animateTo(
          bottom,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<AIChatProvider>(context);
    final primary = appColors.primary;
    final bg = appColors.background;

    // ⚡ STREAMING SYNC: This build is triggered for every word chunk
    // Use a short delay to ensure the framework has laid out the new text/bubles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, primary),
      body: Column(
        children: [
          // Subheader Badge
          _buildTopBanner(primary),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: chatProvider.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "PROTECTED BY ACE ENCRYPTION",
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.3),
                              fontSize: 9,
                              letterSpacing: 1.5,
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
            ),
          ),

          // Suggestion Row
          _buildQuickSuggestions(chatProvider, primary),

          // Interactive Input
          ChatInput(
            onSendMessage: (text, image) {
              chatProvider.sendMessage(text, image: image);
              // Wait for keyboard to start appearing then scroll
              Future.delayed(
                const Duration(milliseconds: 100),
                () => _scrollToBottom(),
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color primary) {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final isDoctor = profile.isDoctor;
    final childName = profile.childName;

    final title = isDoctor
        ? 'ACE Clinical Assistant'
        : childName.isNotEmpty
        ? "$childName's Assistant"
        : 'ACE Parent Copilot';
    final subtitle = isDoctor
        ? 'CLINICAL ASSISTANT • ONLINE'
        : 'PARENT COPILOT • ONLINE';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.chevron_left, color: primary, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_vert, color: primary),
        ),
      ],
    );
  }

  Widget _buildTopBanner(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_moon_outlined,
            size: 14,
            color: primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            "HIPAA Compliant AI Module",
            style: TextStyle(
              color: primary.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(AIChatProvider provider, Color primary) {
    final suggestions = ["Summarize today", "Next activity?", "Stress tips"];
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              suggestions[index],
              style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            side: BorderSide(color: primary.withValues(alpha: 0.1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onPressed: () => provider.sendMessage(suggestions[index]),
          );
        },
      ),
    );
  }
}
