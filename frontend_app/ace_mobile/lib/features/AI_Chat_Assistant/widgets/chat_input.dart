import 'package:flutter/material.dart';

/// The input area at the bottom of the chat.
/// Contains the text field, attachment button, and send button.
class ChatInput extends StatefulWidget {
  final Function(String, dynamic) onSendMessage;

  const ChatInput({super.key, required this.onSendMessage});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isWriting = _controller.text.isNotEmpty;
      });
    });
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    // Call the callback provided by the parent
    widget.onSendMessage(_controller.text, null);

    // Clear the field
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    const purplePrimary = Color(0xFF311B92);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        // Ensures it doesn't get cut off on notched phones
        child: Row(
          children: [
            // 1. Attachment Button (Paperclip)
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () {
                // Here you would use `image_picker` package to pick an image.
                // For this demo, we'll show a Snackback.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Image picker would open here!"),
                  ),
                );
              },
            ),

            // 2. Text Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ask anything about Diego...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 3. Voice Button (Microphone) - Only shown when not typing
            if (!_isWriting)
              IconButton(
                icon: const Icon(Icons.mic_none_outlined, color: Colors.grey),
                onPressed: () {},
              ),

            // 4. Send Button
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isWriting ? purplePrimary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
