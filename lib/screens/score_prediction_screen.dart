import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/match.dart' as app_models;
import '../services/api_service.dart';
import '../services/game_state_service.dart';
import '../services/ad_service.dart';
import '../services/custom_ad_service.dart';
import '../services/prediction_service.dart';

class ScorePredictionScreen extends StatefulWidget {
  final ApiService apiService;
  const ScorePredictionScreen({super.key, required this.apiService});

  @override
  State<ScorePredictionScreen> createState() => _ScorePredictionScreenState();
}

class _ScorePredictionScreenState extends State<ScorePredictionScreen> {
  List<app_models.Match> _apiMatches = [];
  bool _isLoading = true;
  String _error = '';
  final Map<String, Map<String, int>> _predictions = {};
  bool _submitted = false;
  
  DateTime _selectedDate = DateTime.now();
  
  // Services
  late AdService _adService;
  late CustomAdService _customAdService;
  late PredictionService _predictionService;

  @override
  void initState() {
    super.initState();
    _initServices();
    initializeDateFormatting('tr_TR', null).then((_) {
      _loadMatches();
    });
  }

  void _initServices() {
    _adService = AdService();
    _customAdService = CustomAdService();
    _predictionService = PredictionService();
    
    _adService.loadBannerAd();
    _adService.loadInterstitialAd();
  }

  Future<void> _loadMatches() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final matches = await widget.apiService.getUpcomingMatches(date: _selectedDate);
      if (mounted) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        try {
          final gs = await GameStateService.getInstance();
          final loadedPredictions = <String, Map<String, int>>{};
          for (final m in matches) {
            final saved = gs.getPrediction(m.id, dateStr);
            if (saved != null) {
              loadedPredictions[m.id] = saved;
            }
          }
          setState(() {
            _apiMatches = matches;
            _predictions.addAll(loadedPredictions);
            _isLoading = false;
          });
        } catch (_) {
          setState(() { _apiMatches = matches; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Maçlar yüklenirken hata oluştu.'; _isLoading = false; });
    }
  }

  void _updateScore(String matchId, bool isHome, int delta) {
    if (_submitted) return;
    setState(() {
      if (!_predictions.containsKey(matchId)) _predictions[matchId] = {'home': 0, 'away': 0};
      final key = isHome ? 'home' : 'away';
      _predictions[matchId]![key] = (_predictions[matchId]![key]! + delta).clamp(0, 15);
    });
  }

  void _submitPredictions() async {
    try {
      final gs = await GameStateService.getInstance();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      for (final entry in _predictions.entries) {
        final matchId = entry.key;
        final homeScore = entry.value['home']!;
        final awayScore = entry.value['away']!;
        
        // Save locally and to Firebase via GameStateService
        await gs.savePrediction(matchId, dateStr, homeScore, awayScore);
        
        // Register prediction in PredictionService for later verification
        await _predictionService.recordPrediction(
          userId: gs.userId ?? 'anonymous',
          matchId: matchId,
          predictedHomeScore: homeScore,
          predictedAwayScore: awayScore,
          type: 'score'
        );
      }
      
      // Show Interstitial Ad after submission (50% chance or logic)
      _adService.showInterstitialAd();
      
    } catch (_) {}
    
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tahminlerin başarıyla kaydedildi! ⚽'),
        backgroundColor: AppColors.correct,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedMatches = _getGroupedMatches();
    final leagues = groupedMatches.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
                  const Expanded(child: Text('Skor Tahmini', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                    onPressed: () => _showRules(),
                  ),
                ],
              ),
            ),
            
            // Date Selector
            _buildDateSelector(),
            
            Divider(height: 1, color: Colors.grey.shade200),

            // Match list or Loading/Error
            _buildMainContent(leagues, groupedMatches),

            // Bottom Ad Area
            _buildAdArea(),

            if (!_submitted && _apiMatches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GradientButton(text: '📤  Tahminleri Gönder', onTap: _submitPredictions, gradient: AppColors.orangeGradient),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List<String> leagues, Map<String, List<app_models.Match>> groupedMatches) {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)));
    }
    
    if (_error.isNotEmpty) {
      return Expanded(child: Center(child: Text(_error, style: const TextStyle(color: AppColors.textPrimary))));
    }
    
    if (_apiMatches.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, color: Colors.grey.shade300, size: 56),
              const SizedBox(height: 14),
              const Text('Bu tarihte maç bulunamadı.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: leagues.length,
        itemBuilder: (context, i) {
          final leagueName = leagues[i];
          final matchesInLeague = groupedMatches[leagueName]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League Header
              _buildLeagueHeader(leagueName, matchesInLeague),
              
              // Matches
              ...matchesInLeague.map((m) => _buildMatchCard(m)),
              
              // Custom Brand Banner after first league
              if (i == 0) _customAdService.getRandomBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(app_models.Match m) {
    final pred = _predictions[m.id] ?? {'home': 0, 'away': 0};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.cardBox(),
      child: Column(
        children: [
          // Time and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('HH:mm').format(m.date),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: m.status == 'NS' ? AppColors.bgSurface : AppColors.correct.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.status == 'NS' ? 'BAŞLAMADI' : m.status,
                  style: TextStyle(color: m.status == 'NS' ? AppColors.textSecondary : AppColors.correct, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (m.homeLogo != null) Image.network(m.homeLogo!, width: 32, height: 32),
                    const SizedBox(height: 4),
                    Text(m.homeTeam, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: (m.status == 'FT' || m.status == 'PEN' || m.status == 'AET')
                  ? Column(
                      children: [
                        Text('${m.homeScore ?? 0} - ${m.awayScore ?? 0}', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 22, fontWeight: FontWeight.bold)),
                        const Text('MAÇ SONUCU', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _scoreWidget(m.id, true, pred['home']!),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: TextStyle(color: AppColors.textSecondary, fontSize: 20, fontWeight: FontWeight.bold))),
                        _scoreWidget(m.id, false, pred['away']!),
                      ],
                    ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (m.awayLogo != null) Image.network(m.awayLogo!, width: 32, height: 32),
                    const SizedBox(height: 4),
                    Text(m.awayTeam, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdArea() {
    return Container(
      width: double.infinity,
      height: 60,
      color: AppColors.bgCard,
      child: Center(
        child: _adService.getBannerAdWidget(),
      ),
    );
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Puanlama Kuralları', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ruleItem(Icons.star, 'Tam Skor (3-1 bildin): +10 Puan'),
            _ruleItem(Icons.check_circle, 'Doğru Sonuç (Galibiyet bildin): +5 Puan'),
            _ruleItem(Icons.add_chart, 'Doğru Fark (2 fark bildin): +2 Puan'),
            const SizedBox(height: 24),
            GradientButton(text: 'Anladım', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _ruleItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            final today = DateTime.now();
            final date = today.subtract(const Duration(days: 1)).add(Duration(days: index));
            final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
            
            return GestureDetector(
              onTap: () { setState(() => _selectedDate = date); _loadMatches(); },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primaryBlue : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDateTab(date), style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(height: 2),
                    Text('${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeagueHeader(String leagueName, List<app_models.Match> matchesInLeague) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppColors.primaryBlue, width: 3)),
      ),
      child: Row(
        children: [
          if (matchesInLeague.first.leagueLogo.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(matchesInLeague.first.leagueLogo, width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: AppColors.primaryOrange, size: 18)),
            )
          else
            const Icon(Icons.emoji_events, color: AppColors.primaryOrange, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(leagueName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          Text('${matchesInLeague.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _scoreWidget(String matchId, bool isHome, int score) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _updateScore(matchId, isHome, 1),
          child: Container(
            width: 32, height: 24,
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
            child: const Icon(Icons.keyboard_arrow_up, color: AppColors.textSecondary, size: 18),
          ),
        ),
        Container(
          width: 32, height: 34,
          color: AppColors.bgCard,
          child: Center(child: Text('$score', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
        ),
        GestureDetector(
          onTap: () => _updateScore(matchId, isHome, -1),
          child: Container(
            width: 32, height: 24,
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6))),
            child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ],
    );
  }

  String _formatDateTab(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Bugün';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) return 'Dün';
    final tomorrow = now.add(const Duration(days: 1));
    if (date.day == tomorrow.day && date.month == tomorrow.month && date.year == tomorrow.year) return 'Yarın';
    return DateFormat('E', 'tr_TR').format(date);
  }

  Map<String, List<app_models.Match>> _getGroupedMatches() {
    Map<String, List<app_models.Match>> grouped = {};
    for (var m in _apiMatches) {
      final key = m.leagueName.isNotEmpty ? m.leagueName : 'Diğer Ligler';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(m);
    }
    return grouped;
  }
}

