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

class LineupPredictionScreen extends StatefulWidget {
  final ApiService apiService;
  const LineupPredictionScreen({super.key, required this.apiService});

  @override
  State<LineupPredictionScreen> createState() => _LineupPredictionScreenState();
}

class _LineupPredictionScreenState extends State<LineupPredictionScreen> {
  List<app_models.Match> _apiMatches = [];
  bool _isLoading = true;
  app_models.Match? _selectedMatch;
  bool _isHomeTeamSelected = true;
  bool _submitted = false;
  String _error = '';
  DateTime _selectedDate = DateTime.now();

  // Services
  late AdService _adService;
  late CustomAdService _customAdService;
  late PredictionService _predictionService;

  // Squad data from API
  List<Map<String, dynamic>> _squadPlayers = [];
  bool _isLoadingSquad = false;

  // Formations
  static const Map<String, List<List<int>>> _formations = {
    '4-4-2': [[1], [4], [4], [2]],
    '4-3-3': [[1], [4], [3], [3]],
    '4-2-3-1': [[1], [4], [2], [3], [1]],
    '3-5-2': [[1], [3], [5], [2]],
    '4-1-4-1': [[1], [4], [1], [4], [1]],
    '3-4-3': [[1], [3], [4], [3]],
  };
  String _selectedFormation = '4-4-2';

  // Player assignments: position index -> player name
  late Map<int, String> _playerAssignments;
  int _totalPositions = 11;

  // Position labels
  static const _posLabels = {
    '4-4-2': ['GK', 'LB', 'CB', 'CB', 'RB', 'LM', 'CM', 'CM', 'RM', 'ST', 'ST'],
    '4-3-3': ['GK', 'LB', 'CB', 'CB', 'RB', 'CM', 'CM', 'CM', 'LW', 'ST', 'RW'],
    '4-2-3-1': ['GK', 'LB', 'CB', 'CB', 'RB', 'CDM', 'CDM', 'LM', 'CAM', 'RM', 'ST'],
    '3-5-2': ['GK', 'CB', 'CB', 'CB', 'LWB', 'CM', 'CM', 'CM', 'RWB', 'ST', 'ST'],
    '4-1-4-1': ['GK', 'LB', 'CB', 'CB', 'RB', 'CDM', 'LM', 'CM', 'CM', 'RM', 'ST'],
    '3-4-3': ['GK', 'CB', 'CB', 'CB', 'LM', 'CM', 'CM', 'RM', 'LW', 'ST', 'RW'],
  };

  // Position category mapping
  String _posCategory(String posLabel) {
    if (posLabel == 'GK') return 'Goalkeeper';
    if (['LB', 'CB', 'RB', 'LWB', 'RWB'].contains(posLabel)) return 'Defender';
    if (['CM', 'CDM', 'CAM', 'LM', 'RM'].contains(posLabel)) return 'Midfielder';
    return 'Attacker';
  }

  @override
  void initState() {
    super.initState();
    _initServices();
    _playerAssignments = {};
    initializeDateFormatting('tr_TR', null).then((_) => _loadMatches());
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
        setState(() {
          _apiMatches = matches.where((m) => m.status == 'NS').toList();
          if (_apiMatches.isNotEmpty) {
            bool found = false;
            if (_selectedMatch != null) {
              for (var m in _apiMatches) {
                if (m.id == _selectedMatch!.id) { _selectedMatch = m; found = true; break; }
              }
            }
            if (!found) _selectedMatch = _apiMatches.first;
          } else { _selectedMatch = null; }
          _isLoading = false;
        });
        // Load squad for selected team
        if (_selectedMatch != null) _loadSquad();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Maçlar yüklenirken hata oluştu.'; _isLoading = false; });
    }
  }

  Future<void> _loadSquad() async {
    if (_selectedMatch == null) return;
    final teamId = _isHomeTeamSelected ? _selectedMatch!.homeTeamId : _selectedMatch!.awayTeamId;
    if (teamId <= 0) {
      setState(() => _squadPlayers = []);
      return;
    }

    setState(() => _isLoadingSquad = true);
    try {
      final players = await widget.apiService.getTeamSquad(teamId);
      if (mounted) setState(() { _squadPlayers = players; _isLoadingSquad = false; });
    } catch (e) {
      if (mounted) setState(() { _squadPlayers = []; _isLoadingSquad = false; });
    }
  }

  Future<void> _submitLineup() async {
    if (_playerAssignments.length < _totalPositions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm $_totalPositions pozisyonu doldurun!'),
          backgroundColor: AppColors.wrong,
          behavior: SnackBarBehavior.floating
        )
      );
      return;
    }

    try {
      final gs = await GameStateService.getInstance();
      final userId = gs.userId ?? 'anonymous';
      final matchId = _selectedMatch!.id;
      final team = _isHomeTeamSelected ? 'home' : 'away';
      
      // Save lineup prediction to PredictionService
      await _predictionService.recordLineupPrediction(
        userId: userId,
        matchId: matchId,
        team: team,
        formation: _selectedFormation,
        lineup: _playerAssignments,
        type: 'first11'
      );

      // Save locally via GameStateService
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await gs.saveLineupPrediction(matchId, dateStr, team, _selectedFormation, _playerAssignments);

      // Show interstitial ad (50% chance)
      if (DateTime.now().millisecond % 2 == 0) {
        _adService.showInterstitialAd();
      }

      setState(() => _submitted = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kadro tahminin başarıyla kaydedildi! ⚽'),
          backgroundColor: AppColors.correct,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kayıt sırasında hata oluştu.'),
          backgroundColor: AppColors.wrong,
          behavior: SnackBarBehavior.floating
        )
      );
    }
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
            const Text('Kadro Tahmini Kuralları', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ruleItem(Icons.star, 'Tam Kadro (11/11): +15 Puan'),
            _ruleItem(Icons.check_circle, 'Doğru Formasyon: +5 Puan'),
            _ruleItem(Icons.person, 'Her Doğru Oyuncu: +2 Puan'),
            _ruleItem(Icons.emoji_events, 'Kaptan Doğru: +3 Puan'),
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

  String _formatDateTab(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Bugün';
    final y = now.subtract(const Duration(days: 1));
    if (date.day == y.day && date.month == y.month && date.year == y.year) return 'Dün';
    final t = now.add(const Duration(days: 1));
    if (date.day == t.day && date.month == t.month && date.year == t.year) return 'Yarın';
    return DateFormat('E', 'tr_TR').format(date);
  }

  void _editPlayerAt(int index) {
    final labels = _posLabels[_selectedFormation] ?? List.generate(11, (i) => '${i + 1}');
    final posLabel = labels[index];
    final category = _posCategory(posLabel);

    // Filter squad by position category
    final filteredPlayers = _squadPlayers.where((p) {
      final pos = p['position'] as String? ?? '';
      return pos == category;
    }).toList();

    // If no squad data, fall back to all players or text input
    final displayPlayers = filteredPlayers.isNotEmpty ? filteredPlayers : _squadPlayers;

    if (displayPlayers.isEmpty) {
      // Fallback to text input if no squad data
      _editPlayerByText(index, posLabel);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlayerPickerSheet(
        posLabel: posLabel,
        allPlayers: displayPlayers,
        allSquadPlayers: _squadPlayers,
        onSelect: (playerName) {
          setState(() => _playerAssignments[index] = playerName);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editPlayerByText(int index, String posLabel) {
    final ctrl = TextEditingController(text: _playerAssignments[index] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$posLabel Pozisyonu', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Oyuncu adı girin',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true, fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _playerAssignments[index] = ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Kadro Tahmini', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                  onPressed: _showRules,
                ),
              ]),
            ),

            // Date Selector
            _buildDateSelector(),
            
            Divider(height: 1, color: Colors.grey.shade200),

            // Content
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))
            else if (_error.isNotEmpty)
              Expanded(child: Center(child: Text(_error, style: const TextStyle(color: AppColors.textPrimary))))
            else if (_apiMatches.isEmpty)
              Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.event_busy, color: Colors.grey.shade300, size: 48),
                const SizedBox(height: 12),
                const Text('Bu tarihte henüz fikstür yok.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('API verileri yayınlandığında burada görünecek.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ])))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Match dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: AppDecorations.cardBox(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<app_models.Match>(
                          value: _selectedMatch, isExpanded: true,
                          dropdownColor: AppColors.bgCard,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                          items: _apiMatches.map((m) => DropdownMenuItem(value: m, child: Text('${m.homeTeam} vs ${m.awayTeam}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: _submitted ? null : (val) {
                            setState(() { _selectedMatch = val; _playerAssignments = {}; _submitted = false; });
                            _loadSquad();
                          },
                        ),
                      ),
                    ),
                    if (_selectedMatch != null) ...[
                      const SizedBox(height: 12),

                      // Team selector
                      Row(children: [
                        Expanded(child: _teamTab(_selectedMatch!.homeTeam, true)),
                        const SizedBox(width: 8),
                        Expanded(child: _teamTab(_selectedMatch!.awayTeam, false)),
                      ]),
                      const SizedBox(height: 12),

                      // Squad info
                      if (_isLoadingSquad)
                        const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue))))
                      else if (_squadPlayers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.correct.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.check_circle, color: AppColors.correct, size: 14),
                            const SizedBox(width: 6),
                            Text('${_squadPlayers.length} oyuncu kadrodan yüklendi', style: const TextStyle(color: AppColors.correct, fontSize: 11)),
                          ]),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.s