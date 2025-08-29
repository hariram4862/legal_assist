import 'package:flutter/material.dart';
// Update the import path below if the file exists elsewhere, e.g.:
import '/api_services/quiz_models.dart';
// Or create the file at lib/api_services/quiz_models.dart if it does not exist.

class McqCard extends StatefulWidget {
  final QuizQuestionModel question;
  final void Function(String chosen, bool correct) onPicked;
  const McqCard({super.key, required this.question, required this.onPicked});

  @override
  State<McqCard> createState() => _McqCardState();
}

class _McqCardState extends State<McqCard> with SingleTickerProviderStateMixin {
  String? _selected;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return ScaleTransition(
      scale: _scale,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _difficultyColor(q.difficulty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      q.difficulty,
                      style: TextStyle(
                        color: _difficultyColor(q.difficulty),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...?q.options?.map((opt) {
                final isPicked = _selected == opt;
                final isCorrect = opt == q.answer;
                final pickedColor =
                    isPicked
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.transparent;
                return InkWell(
                  onTap: () {
                    setState(() => _selected = opt);
                    widget.onPicked(opt, isCorrect);
                    _controller.forward().then((_) => _controller.reverse());
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isPicked
                              ? pickedColor.withOpacity(0.12)
                              : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPicked ? pickedColor : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPicked
                              ? (isCorrect ? Icons.check_circle : Icons.cancel)
                              : Icons.circle_outlined,
                          color: isPicked ? pickedColor : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String lvl) {
    switch (lvl.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}
