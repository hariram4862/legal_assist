import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'quiz_models.dart';
import 'sample_quiz.dart';

class QuizApi {
  // TODO: set your FastAPI base URL here
  static const String baseUrl = 'https://YOUR-API.azurewebsites.net';

  static Future<List<QuizQuestionModel>> generateQuiz({
    required String email,
    String? sessionId,
    String difficulty = 'Mixed',
    bool useBackend = false, // flip to true once backend is ready
  }) async {
    if (!useBackend) {
      // Local mock
      await Future.delayed(const Duration(milliseconds: 300));
      if (difficulty.toLowerCase() == 'easy') {
        return sampleQuiz
            .where((q) => q.difficulty.toLowerCase() == 'easy')
            .toList();
      } else if (difficulty.toLowerCase() == 'medium') {
        return sampleQuiz
            .where((q) => q.difficulty.toLowerCase() == 'medium')
            .toList();
      } else if (difficulty.toLowerCase() == 'hard') {
        return sampleQuiz
            .where((q) => q.difficulty.toLowerCase() == 'hard')
            .toList();
      }
      return sampleQuiz;
    }

    final uri = Uri.parse('$baseUrl/generate_quiz');
    final resp = await http.post(
      uri,
      body: {
        'email': email,
        if (sessionId != null) 'session_id': sessionId,
        'difficulty': difficulty,
      },
    );

    if (resp.statusCode == 200) {
      final payload = QuizPayload.fromJson(jsonDecode(resp.body));
      return payload.questions;
    } else {
      debugPrint('generateQuiz failed: ${resp.statusCode} ${resp.body}');
      return sampleQuiz; // fallback
    }
  }

  static Future<QuizSubmissionResult> submitQuiz({
    required String email,
    required String sessionId,
    required List<Map<String, dynamic>>
    answers, // [{id: 'q1', answer: 'Queue'}]
    bool useBackend = false,
  }) async {
    if (!useBackend) {
      // Local evaluation
      int score = 0;
      final total = answers.length;
      final results = <Map<String, dynamic>>[];
      for (final a in answers) {
        final q = sampleQuiz.firstWhere((e) => e.id == a['id']);
        final ok = (a['answer']?.toString() ?? '') == q.answer;
        if (ok) score++;
        results.add({'q': q.id, 'status': ok ? 'Correct' : 'Needs Review'});
      }
      return QuizSubmissionResult(score: score, total: total, results: results);
    }

    final uri = Uri.parse('$baseUrl/submit_quiz');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'session_id': sessionId,
        'answers': answers,
      }),
    );

    if (resp.statusCode == 200) {
      return QuizSubmissionResult.fromJson(jsonDecode(resp.body));
    } else {
      debugPrint('submitQuiz failed: ${resp.statusCode} ${resp.body}');
      return QuizSubmissionResult(score: 0, total: answers.length, results: []);
    }
  }
}
