import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/question_service.dart';

class GuessPlayerScreen extends StatefulWidget {
  const GuessPlayerScreen({super.key});

  @override
  State<GuessPlayerScreen> createState() => _GuessPlayerScreenState();
}

class _GuessPlayerScreenState extends State<GuessPlayerScreen> {
  late List<Map<String, dynamic>> _players;
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _hintsRevealed = 0;
  final TextEditingController _guessController = TextEditingController();
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _players = QuestionService.getGuessPlayerData();
    _players.shuffle();
  }

  void _revealHint() {
    final hints = (_players[_currentIndex]['hints'] as List).length;
    if (_hintsRevealed < hints) {
      setState(() => _hintsRevealed++);
    }
  }

  void _submitGuess() {
    if (_answered) return;
    final correctName = (_players[_currentIndex]['name'] as String).toLowerCase();
    final guess = _guessController.text.trim().toLowerCase();
    final isCorrect = correctName.contains(guess) || guess.contains(correctName.split(' ').last.toLowerCase());

    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        final bonus = (4 - _hintsRevealed).clamp(1, 4);
        _score += bonus * 50;
        _correctCount++;
      }
    });
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (_currentIndex < _players.length - 1) {
      setState(() {
        _currentIndex++;
        _hintsRevealed = 0;
        _answered = false;
        _isCorrect = false;
        _guessController.clear();
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.person_search, color: AppColors.textAccent, size: 64),
            const SizedBox(height: 12),
            const Text('Oyun Bitti!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score puan', style: const TextStyle(color: AppColors.textAccent, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_correctCount / ${_players.length} doğru', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
        actions: [
          GradientButton(
            text: 'Ana Sayfaya Dön',
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            gradient: AppColors.greenGradient,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _players[_currentIndex];
    final hints = player['hints'] as List;

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
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    Text('${_currentIndex + 1}/${_players.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: AppDecorations.glassBox(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppColors.textAccent, size: 18),
                          const SizedBox(width: 4),
                          Text('$_score', style: const TextStyle(color: AppColors.textAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Mystery player card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: AppDecorations.cardBox(),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.greenGradient,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _answered ? player['name'] : '???',
                        style: TextStyle(
                          color: _answered
                              ? (_isCorrect ? AppColors.correct : AppColors.wrong)
                              : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(player['team'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Hints
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('İpuçları', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                ...List.generate(hints.length, (i) {
                  final revealed = i < _hintsRevealed;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: revealed ? AppColors.bgSurface : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: revealed ? AppColors.categoryGreen.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          revealed ? Icons.lightbulb : Icons.lock,
                          color: revealed ? AppColors.textAccent : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            revealed ? hints[i] : 'İpucu ${i + 1}',
                            style: TextStyle(
                              color: revealed ? Colors.white : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),

                if (!_answered) ...[
                  // Reveal hint button
                  if (_hintsRevealed < hints.length)
                    TextButton.icon(
                      onPressed: _revealHint,
                      icon: const Icon(Icons.lightbulb_outline, color: AppColors.textAccent),
                      label: const Text('İpucu Aç', style: TextStyle(color: AppColors.textAccent)),
                    ),
                  const Spacer(),

                  // Guess input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _guessController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Futbolcunun adını yaz...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: AppColors.bgSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onSubmitted: (_) => _submitGuess(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _submitGuess,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.greenGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
