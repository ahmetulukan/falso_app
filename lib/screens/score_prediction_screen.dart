import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ScorePredictionScreen extends StatefulWidget {
  const ScorePredictionScreen({super.key});

  @override
  State<ScorePredictionScreen> createState() => _ScorePredictionScreenState();
}

class _ScorePredictionScreenState extends State<ScorePredictionScreen> {
  // Demo maç verileri
  final List<Map<String, dynamic>> _matches = [
    {'home': 'Galatasaray', 'away': 'Fenerbahçe', 'league': 'Süper Lig', 'time': '20:00', 'homeScore': 0, 'awayScore': 0},
    {'home': 'Real Madrid', 'away': 'Barcelona', 'league': 'La Liga', 'time': '22:00', 'homeScore': 0, 'awayScore': 0},
    {'home': 'Manchester City', 'away': 'Liverpool', 'league': 'Premier League', 'time': '18:30', 'homeScore': 0, 'awayScore': 0},
    {'home': 'Bayern Münih', 'away': 'Dortmund', 'league': 'Bundesliga', 'time': '19:30', 'homeScore': 0, 'awayScore': 0},
    {'home': 'Beşiktaş', 'away': 'Trabzonspor', 'league': 'Süper Lig', 'time': '21:00', 'homeScore': 0, 'awayScore': 0},
  ];
  bool _submitted = false;

  void _updateScore(int index, bool isHome, int delta) {
    if (_submitted) return;
    setState(() {
      final key = isHome ? 'homeScore' : 'awayScore';
      final current = _matches[index][key] as int;
      _matches[index][key] = (current + delta).clamp(0, 15);
    });
  }

  void _submitPredictions() {
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tahminlerin kaydedildi! ⚽'),
        backgroundColor: AppColors.correct,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    const Expanded(
                      child: Text('Günün Maçları', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Match list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final m = _matches[i];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppDecorations.cardBox(),
                      child: Column(
                        children: [
                          // League
                          Text(m['league'], style: TextStyle(color: AppColors.primaryOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(m['time'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Home team
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                      child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(m['home'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              // Score input
                              Row(
                                children: [
                                  _scoreWidget(i, true, m['homeScore']),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('-', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 24, fontWeight: FontWeight.bold)),
                                  ),
                                  _scoreWidget(i, false, m['awayScore']),
                                ],
                              ),
                              // Away team
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                      child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(m['away'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Submit button
              if (!_submitted)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GradientButton(
                    text: '📤  Tahminleri Gönder',
                    onTap: _submitPredictions,
                    gradient: AppColors.orangeGradient,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreWidget(int matchIndex, bool isHome, int score) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _updateScore(matchIndex, isHome, 1),
          child: Container(
            width: 36, height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
          ),
        ),
        Container(
          width: 36, height: 40,
          color: AppColors.bgSurface,
          child: Center(
            child: Text('$score', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ),
        GestureDetector(
          onTap: () => _updateScore(matchIndex, isHome, -1),
          child: Container(
            width: 36, height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}
