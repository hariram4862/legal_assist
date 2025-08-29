import 'package:flutter/material.dart';
import 'quiz_models.dart';
import 'quiz_api.dart';

class QuizController extends ChangeNotifier {
  QuizController({required this.email, this.sessionId, this.primaryColor});

  final String email;
  final String? sessionId;
  final Color? primaryColor;

  List<QuizQuestionModel> _questions = [];
  int _index = 0;
  int _score = 0;
  int _streak = 0;
  String _difficultyFilter = 'Mixed';
  bool _loading = true;

  // answers cache
  final Map<String, dynamic> _answers = {}; // id -> user answer

  List<QuizQuestionModel> get questions => _questions;
  int get index => _index;
  int get score => _score;
  int get streak => _streak;
  bool get loading => _loading;
  String get difficultyFilter => _difficultyFilter;
  double get progress =>
      _questions.isEmpty ? 0 : (_index + 1) / _questions.length;

  Future<void> init({String difficulty = 'Mixed'}) async {
    _loading = true;
    notifyListeners();
    _difficultyFilter = difficulty;
    _questions = await QuizApi.generateQuiz(
      email: email,
      sessionId: sessionId,
      difficulty: difficulty,
      useBackend: false,
    );
    _index = 0;
    _score = 0;
    _streak = 0;
    _answers.clear();
    _loading = false;
    notifyListeners();
  }

  void selectMCQ(
    String id,
    String chosen,
    String correct,
    VoidCallback onCorrect,
    VoidCallback onWrong,
  ) {
    _answers[id] = chosen;
    if (chosen == correct) {
      _score += 1;
      _streak += 1;
      onCorrect();
    } else {
      _streak = 0;
      onWrong();
    }
    notifyListeners();
  }

  void submitTeachBack(String id, String text) {
    _answers[id] = text;
    notifyListeners();
  }

  void next() {
    if (_index < _questions.length - 1) {
      _index++;
      notifyListeners();
    }
  }

  bool get isLast => _index == _questions.length - 1;

  Future<Map<String, dynamic>> finish() async {
    final answers =
        _answers.entries.map((e) => {'id': e.key, 'answer': e.value}).toList();
    final result = await QuizApi.submitQuiz(
      email: email,
      sessionId: sessionId ?? 'local',
      answers: answers,
      useBackend: false,
    );
    return {
      'score': result.score,
      'total': result.total,
      'results': result.results,
    };
  }
}
