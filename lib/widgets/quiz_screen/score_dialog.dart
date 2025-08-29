import 'package:flutter/material.dart';

class ScoreDialog extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;
  const ScoreDialog({
    super.key,
    required this.score,
    required this.total,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (score / total);
    return AlertDialog(
      title: const Text('Quiz Completed 🎉'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score: $score / $total'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: pct, minHeight: 8),
          const SizedBox(height: 12),
          Text(
            pct >= 0.8
                ? 'Excellent!'
                : pct >= 0.5
                ? 'Good job!'
                : 'Keep practicing!',
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onRestart, child: const Text('Restart')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
