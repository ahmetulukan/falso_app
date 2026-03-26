import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/question.dart';
import '../services/question_service.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  late List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _selectedAnswer = -1;
  bool _answered = false;
  int _timeLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _questions = QuestionService.getTriviaQuestions();
    _questions.shuffle();
    _questions = _questions.take(10).toList();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    setState(() {
      _answered = true;
      _selectedAnswer = -1;
    });
    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    final question = _questions[_currentIndex];
    final isCorrect = index == question.correctIndex;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) {
        _score += (_timeLeft * 10) + 50;
        _correctCount++;
      }
    });
    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = -1;
        _answered = false;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Icon(
              _correctCount >= 7 ? Icons.emoji_events : Icons.sports_score,
              color: AppColors.textAccent,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text('Oyun Bitti!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Toplam Puan: $_score', style: const TextStyle(color: AppColors.textAccent, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('$_correctCount / ${_questions.length} doğru cevap', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
        actions: [
          GradientButton(
            text: 'Ana Sayfaya Dön',
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final labels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Soru ${_currentIndex + 1}/${_questions.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    CountdownTimer(seconds: _timeLeft, totalSeconds: 10),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryPurple),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: AppDecorations.glassBox(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: AppColors.textAccent, size: 20),
                      const SizedBox(width: 6),
                      Text('$_score', style: const TextStyle(color: AppColors.textAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(question.category, style: const TextStyle(color: AppColors.primaryPink, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),

                // Question
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: AppDecorations.cardBox(),
                      child: Center(
                        child: Text(
                          question.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Answers
                Expanded(
                  flex: 3,
                  child: ListView.separated(
                    itemCount: question.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      bool? isCorrect;
                      if (_answered) {
                        if (i == question.correctIndex) {
                          isCorrect = true;
                        } else if (i == _selectedAnswer) {
                          isCorrect = false;
                        }
                      }
                      return AnswerButton(
                        text: question.options[i],
                        label: labels[i],
                        isSelected: _selectedAnswer == i,
                        isCorrect: isCorrect,
                        onTap: () => _selectAnswer(i),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
