import 'package:flutter/material.dart';
import 'package:legal_assist/widgets/quiz_screen/difficulty_filter.dart';
import 'package:legal_assist/widgets/quiz_screen/flashcard_card.dart';
import 'package:legal_assist/widgets/quiz_screen/mcq_card.dart';
import 'package:legal_assist/widgets/quiz_screen/teachback_widget.dart';
import 'package:provider/provider.dart';
import '../api_services/quiz_controller.dart';

import '../widgets/quiz_screen/progress_bar.dart';

import '../widgets/quiz_screen/streak_badge.dart';
import '../widgets/quiz_screen/confetti_overlay.dart';

class QuizPage extends StatelessWidget {
  final String email;
  final String? sessionId;
  const QuizPage({super.key, required this.email, this.sessionId});

  @override
  Widget build(BuildContext context) {
    // Ensure Theme matches your HomePage
    return ChangeNotifierProvider(
      create:
          (_) =>
              QuizController(email: email, sessionId: sessionId)
                ..init(difficulty: 'Mixed'),
      child: const _QuizScaffold(),
    );
  }
}

class _QuizScaffold extends StatefulWidget {
  const _QuizScaffold();
  @override
  State<_QuizScaffold> createState() => _QuizScaffoldState();
}

class _QuizScaffoldState extends State<_QuizScaffold> {
  bool _fireConfetti = false;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<QuizController>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: true,
            title: const Text(
              'Practice Quiz',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
          body:
              c.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: ProgressBar(value: c.progress)),
                            const SizedBox(width: 12),
                            StreakBadge(streak: c.streak),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DifficultyFilter(
                                value: c.difficultyFilter,
                                onChanged: (v) async {
                                  await context.read<QuizController>().init(
                                    difficulty: v,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ScorePill(score: c.score),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _QuestionView(
                              onCorrect: () {
                                setState(() => _fireConfetti = true);
                                Future.delayed(
                                  const Duration(milliseconds: 900),
                                  () {
                                    if (mounted)
                                      setState(() => _fireConfetti = false);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!c.isLast)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => c.next(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                  child: const Text('Next →'),
                                ),
                              ),
                            if (c.isLast)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await c.finish();
                                    if (!mounted) return;
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => AlertDialog(
                                            title: const Text(
                                              'Quiz Completed 🎉',
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Score: ${result['score']} / ${result['total']}',
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  await context
                                                      .read<QuizController>()
                                                      .init(
                                                        difficulty: 'Mixed',
                                                      );
                                                },
                                                child: const Text('Restart'),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                  child: const Text('Finish ✓'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
        ),
        ConfettiOverlay(trigger: _fireConfetti),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            'Score: $score',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final VoidCallback onCorrect;
  const _QuestionView({required this.onCorrect});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<QuizController>();
    final q = c.questions[c.index];

    Widget content;
    if (q.type == 'mcq') {
      content = McqCard(
        question: q,
        onPicked: (chosen, isCorrect) {
          c.selectMCQ(
            q.id,
            chosen,
            q.answer,
            () {
              onCorrect();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('✅ Correct!')));
            },
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ Incorrect. Correct: ${q.answer}')),
              );
            },
          );
        },
      );
    } else if (q.type == 'flashcard') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlashcardCard(question: q.question, answer: q.answer),
          const SizedBox(height: 12),
          Text(
            '*Tap card to flip*',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      );
    } else {
      content = TeachBackWidget(
        questionId: q.id,
        question: q.question,
        onSubmit: (text) => c.submitTeachBack(q.id, text),
      );
    }

    return Container(key: ValueKey(q.id), child: content);
  }
}
