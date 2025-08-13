import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, String> message;
  final bool isEditable;
  final bool enableTypingAnimation;
  const MessageBubble(
    this.message, {
    super.key,
    this.isEditable = true,
    this.enableTypingAnimation = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _editingController;

  String _visibleText = '';
  Timer? _typingTimer;

  bool get isUser => widget.message['role'] == 'user';
  bool get isTypingBubble =>
      widget.enableTypingAnimation &&
      widget.message['text'] == '...typing...' &&
      !isUser;
  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isUser && widget.message['text'] != oldWidget.message['text']) {
      _typingTimer?.cancel();
      _startTypingAnimation();
    }
  }

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(
      text: widget.message['text'] ?? '',
    );

    if (!isUser &&
        widget.enableTypingAnimation &&
        widget.message['text'] == '...typing...') {
      _startTypingAnimation();
    } else {
      _visibleText = widget.message['text'] ?? '';
    }
  }

  void _startTypingAnimation() {
    if (!widget.enableTypingAnimation) return;

    final fullText = widget.message['text'] ?? '';
    int index = 0;
    _visibleText = '';

    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (index < fullText.length) {
        setState(() {
          _visibleText += fullText[index];
          index++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _editingController.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (isUser && widget.isEditable) {
      setState(() => _isEditing = true);
    }
  }

  void _saveEdit() {
    setState(() {
      widget.message['text'] = _editingController.text;
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingController.text = widget.message['text'] ?? '';
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isUser ? const Color(0xFFF5F8FF) : const Color(0xFFF0F0F0);
    final textColor = const Color(0xFF111111);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          _startEditing();
        }
      },
      onDoubleTap: () {
        Clipboard.setData(ClipboardData(text: widget.message['text'] ?? ''));
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              _isEditing
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _editingController,
                        maxLines: null,
                        style: GoogleFonts.poppins(color: textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, size: 20),
                            onPressed: _saveEdit,
                            color: Colors.green,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _cancelEdit,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  )
                  : isTypingBubble
                  ? const LoadingDots()
                  : Text(
                    _visibleText,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
        ),
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _dotCount = StepTween(
      begin: 1,
      end: 3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        final dots = '.' * _dotCount.value;
        return Text(
          'Bot is typing$dots',
          style: GoogleFonts.poppins(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 14,
          ),
        );
      },
    );
  }
}
