import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/question_service.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _answered = false;
  bool _isCorrect = false;
  int _selectedOption = -1;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _players = QuestionService.getGuessPlayerData();
    _players.shuffle();
    _buildOptions();
  }

  void _buildOptions() {
    final correct = _players[_currentIndex]['name'] as String;
    final allNames = _players.map((p) => p['name'] as String).where((n) => n != correct).toList();
    allNames.shuffle();
    _options = [correct, ...allNames.take(3)];
    _options.shuffle();
  }

  void _revealHint() {
    final hints = (_players[_currentIndex]['hints'] as List).length;
    if (_hintsRevealed < hints) setState(() => _hintsRevealed++);
  }

  void _selectOption(int index) {
    if (_answered) return;
    final correct = _players[_currentIndex]['name'] as String;
    final isCorrect = _options[index] == correct;
    setState(() {
      _selectedOption = index;
      _answered = true;
      _isCorrect = isCorrect;
      if (isCorrect) { final bonus = (4 - _hintsRevealed).clamp(1, 4); _score += bonus * 50; _correctCount++; }
    });
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (_currentIndex < _players.length - 1) {
      setState(() { _currentIndex++; _hintsRevealed = 0; _answered = false; _isCorrect = false; _selectedOption = -1; });
      _buildOptions();
    } else { _showResults(); }
  }

  void _showResults() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(children: [
        const Icon(Icons.person_search, color: AppColors.primaryOrange, size: 48),
        const SizedBox(height: 8),
        const Text('Oyun Bitti!', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$_score puan', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('$_correctCount / ${_players.length} doğru', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(onPressed: () async {
          await SharePlus.instance.share(ShareParams(text: 'Falso ile Kim Bu? oyununda $_score puan kazandım!'));
        }, icon: const Icon(Icons.share, color: AppColors.primaryOrange, size: 18), label: const Text('Paylaş', style: TextStyle(color: AppColors.primaryOrange, fontSize: 13))),
        ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)), child: const Text('Bitir', style: TextStyle(fontSize: 13))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final player = _players[_currentIndex];
    final hints = player['hints'] as List;
    final teamLogo = player['teamLogo'] as String? ?? '';
    final correctName = player['name'] as String;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              // Top bar — compact
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                Text('${_currentIndex + 1}/${_players.length}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: AppDecorations.glassBox(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, color: AppColors.primaryOrange, size: 14),
                    const SizedBox(width: 3),
                    Text('$_score', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ]),
              const SizedBox(height: 6),

              // Player card — compact
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: AppDecorations.cardBox(),
                child: Row(children: [
                  if (teamLogo.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(teamLogo, width: 50, height: 50, errorBuilder: (_, __, ___) => _avatar(50)))
                  else _avatar(50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _answered ? correctName : '???',
                        style: TextStyle(color: _answered ? (_isCorrect ? AppColors.correct : AppColors.wrong) : AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(player['team'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              // Hints — horizontal chips
              Row(
                children: [
                  const Text('İpuçları ', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  if (!_answered && _hintsRevealed < hints.length)
                    GestureDetector(
                      onTap: _revealHint,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryOrange.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+ İpucu Aç', style: TextStyle(color: AppColors.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: List.generate(hints.length, (i) {
                  final revealed = i < _hintsRevealed;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: revealed ? AppColors.correct.withAlpha(20) : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: revealed ? AppColors.correct.withAlpha(60) : const Color(0xFFE5E7EB), width: 0.5),
                    ),
                    child: Text(
                      revealed ? hints[i] : '🔒 ${i + 1}',
                      style: TextStyle(color: revealed ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 11),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),

              // MCQ — 2×2 grid
              const Align(alignment: Alignment.centerLeft, child: Text('Kim bu futbolcu?', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (i) {
                    bool? isCorrect;
                    if (_answered) {
                      if (_options[i] == correctName) isCorrect = true;
                      else if (i == _selectedOption) isCorrect = false;
                    }
                    return _gridOption(_options[i], _selectedOption == i, isCorrect, () => _selectOption(i));
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridOption(String text, bool selected, bool? isCorrect, VoidCallback onTap) {
    Color bg = AppColors.bgSurface;
    Color tc = AppColors.textPrimary;
    if (isCorrect == true) { bg = AppColors.correct; tc = Colors.white; }
    else if (isCorrect == false && selected) { bg = AppColors.wrong; tc = Colors.white; }
    else if (selected) { bg = AppColors.primaryBlue; tc = Colors.white; }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text, style: TextStyle(color: tc, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2),
      ),
    );
  }

  Widget _avatar(double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(s / 2), border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5)),
    child: Icon(Icons.person_outline, color: AppColors.textSecondary, size: s * 0.5),
  );
}
