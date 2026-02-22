import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ace_mobile/core/constants.dart';

class ChatInput extends StatefulWidget {
  final Function(String, File?) onSendMessage;

  const ChatInput({super.key, required this.onSendMessage});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isWriting = _controller.text.trim().isNotEmpty;
        });
      }
    });
  }

  /// 📸 PICK IMAGE LOGIC
  Future<void> _pickImage() async {
    debugPrint("DEBUG: _pickImage() called");
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        debugPrint("DEBUG: Image picked -> ${pickedFile.path}");
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        debugPrint("DEBUG: No image selected by user");
      }
    } catch (e) {
      debugPrint("DEBUG: CRITICAL ERROR picking image -> $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: No gallery access. Check permissions! ($e)"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    debugPrint(
      "DEBUG: Sending message. Text length: ${text.length}, Image attached: ${_selectedImage != null}",
    );

    // Call the parent callback
    widget.onSendMessage(text, _selectedImage);

    // Clear local state
    _controller.clear();
    setState(() {
      _selectedImage = null;
      _isWriting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = appColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image Preview (visible when user attaches a file)
        if (_selectedImage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    "Image attached. AI will analyze this for clinical context.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Input Bar
        Container(
          padding: const EdgeInsets.fromLTRB(
            10,
            10,
            10,
            25,
          ), // Extra bottom padding for safe area
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Paperclip Icon
              IconButton(
                icon: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: primaryColor,
                  size: 26,
                ),
                onPressed: _pickImage,
              ),

              // TextField
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "Review Diego's progress...",
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // SEND BUTTON
              GestureDetector(
                onTap: _handleSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isWriting || _selectedImage != null)
                        ? primaryColor
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
