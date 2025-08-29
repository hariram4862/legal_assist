import 'quiz_models.dart';

final List<QuizQuestionModel> sampleQuiz = [
  QuizQuestionModel(
    id: 'q1',
    type: 'mcq',
    question: 'Which data structure uses FIFO principle?',
    options: ['Stack', 'Queue', 'Graph', 'Tree'],
    answer: 'Queue',
    difficulty: 'Easy',
  ),
  QuizQuestionModel(
    id: 'q2',
    type: 'flashcard',
    question: 'Define Overfitting.',
    answer:
        'Overfitting is when a model performs well on training data but poorly on unseen data.',
    difficulty: 'Medium',
  ),
  QuizQuestionModel(
    id: 'q3',
    type: 'teach-back',
    question: 'Explain QuickSort to a peer.',
    answer:
        'QuickSort uses divide and conquer by partitioning the array around a pivot.',
    difficulty: 'Hard',
  ),
  QuizQuestionModel(
    id: 'q4',
    type: 'mcq',
    question: 'Time complexity of Binary Search?',
    options: ['O(n)', 'O(n log n)', 'O(log n)', 'O(1)'],
    answer: 'O(log n)',
    difficulty: 'Easy',
  ),
];
