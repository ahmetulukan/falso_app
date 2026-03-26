import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/team.dart';
import '../services/question_service.dart';

class CityFinderScreen extends StatefulWidget {
  const CityFinderScreen({super.key});

  @override
  State<CityFinderScreen> createState() => _CityFinderScreenState();
}

class _CityFinderScreenState extends State<CityFinderScreen> {
  late List<Team> _teams;
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  String? _selectedCity;
  bool _answered = false;
  late List<String> _cityOptions;

  @override
  void initState() {
    super.initState();
    _teams = QuestionService.getCityFinderTeams();
    _teams.shuffle();
    _loadCityOptions();
  }

  void _loadCityOptions() {
    _cityOptions = QuestionService.getCityOptions(_teams[_currentIndex].city);
  }

  void _selectCity(String city) {
    if (_answered) return;
    final isCorrect = city == _teams[_currentIndex].city;
    setState(() {
      _selectedCity = city;
      _answered = true;
      if (isCorrect) {
        _score += 100;
        _correctCount++;
      }
    });
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (_currentIndex < _teams.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedCity = null;
        _answered = false;
      });
      _loadCityOptions();
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
            const Icon(Icons.location_city, color: AppColors.textAccent, size: 64),
            const SizedBox(height: 12),
            const Text('Şehir Bul Bitti!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score puan', style: const TextStyle(color: AppColors.textAccent, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_correctCount / ${_teams.length} doğru', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
        actions: [
          GradientButton(
            text: 'Ana Sayfaya Dön',
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            gradient: AppColors.blueGradient,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = _teams[_currentIndex];

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
                    Text('${_currentIndex + 1}/${_teams.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _teams.length,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.categoryBlue),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 30),

                // Team logo + name card
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: AppDecorations.cardBox(),
                  child: Column(
                    children: [
                      const Text('Bu takım hangi şehirde?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(Icons.sports_soccer, size: 50, color: AppColors.primaryPurple),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        team.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(team.league, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // City options
                Expanded(
                  child: ListView.separated(
                    itemCount: _cityOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final city = _cityOptions[i];
                      bool? isCorrect;
                      if (_answered) {
                        if (city == team.city) {
                          isCorrect = true;
                        } else if (city == _selectedCity) {
                          isCorrect = false;
                        }
                      }
                      return AnswerButton(
                        text: city,
                        label: '${i + 1}',
                        isSelected: _selectedCity == city,
                        isCorrect: isCorrect,
                        onTap: () => _selectCity(city),
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
