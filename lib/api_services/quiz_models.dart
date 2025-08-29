import 'package:flutter/foundation.dart';

class QuizQuestionModel {
  final String id; // Unique id per question
  final String type;
  final String question;
  final List<String>? options; // MCQ only
  final String answer; // correct answer / back of flashcard
  final String difficulty; // "Easy", "Medium", "Hard"

  QuizQuestionModel({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    required this.answer,
    required this.difficulty,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      type: json['type'],
      question: json['question'],
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
      answer: json['answer'],
      difficulty: json['difficulty'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'question': question,
    'options': options,
    'answer': answer,
    'difficulty': difficulty,
  };
}

class QuizPayload {
  final List<QuizQuestionModel> questions;
  QuizPayload({required this.questions});

  factory QuizPayload.fromJson(Map<String, dynamic> json) {
    final list = (json['quiz'] as List?) ?? [];
    return QuizPayload(
      questions: list.map((e) => QuizQuestionModel.fromJson(e)).toList(),
    );
  }
}

class QuizSubmissionResult {
  final int score;
  final int total;
  final List<Map<String, dynamic>>
  results; // [{q:"id", status: "Correct"|"Needs Review"}]

  QuizSubmissionResult({
    required this.score,
    required this.total,
    required this.results,
  });

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    return QuizSubmissionResult(
      score: json['score'] ?? 0,
      total: json['total'] ?? 0,
      results:
          (json['results'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }
}
