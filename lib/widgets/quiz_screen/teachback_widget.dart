import 'package:flutter/material.dart';

class TeachBackWidget extends StatefulWidget {
  final String questionId;
  final String question;
  final void Function(String text) onSubmit;
  const TeachBackWidget({
    super.key,
    required this.questionId,
    required this.question,
    required this.onSubmit,
  });

  @override
  State<TeachBackWidget> createState() => _TeachBackWidgetState();
}

class _TeachBackWidgetState extends State<TeachBackWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Explain in your own words...',
            fillColor: const Color(0xFFF0F0F0),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              widget.onSubmit(text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved for feedback')),
              );
              _controller.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}
