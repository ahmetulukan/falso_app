import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/match.dart' as app_models;
import '../services/api_service.dart';

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
    _playerAssignments = {};
    initializeDateFormatting('tr_TR', null).then((_) => _loadMatches());
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

  void _submitLineup() {
    if (_playerAssignments.length < _totalPositions) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lütfen tüm $_totalPositions pozisyonu doldurun!'), backgroundColor: AppColors.wrong, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Kadro tahminin kaydedildi! ⚽'), backgroundColor: AppColors.correct, behavior: SnackBarBehavior.floating));
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
                const SizedBox(width: 48),
              ]),
            ),

            // Date Selector
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 12, // 1 day ago → 10 days ahead
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final today = DateTime.now();
                    final date = today.subtract(const Duration(days: 1)).add(Duration(days: index));
                    final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
                    return GestureDetector(
                      onTap: () { setState(() => _selectedDate = date); _loadMatches(); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.primaryBlue : const Color(0xFFE5E7EB)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_formatDateTab(date), style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          const SizedBox(height: 1),
                          Text('${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primaryOrange.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [
                            Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 14),
                            SizedBox(width: 6),
                            Text('Kadro verisi yüklenemedi, elle giriş yapın', style: TextStyle(color: AppColors.primaryOrange, fontSize: 11)),
                          ]),
                        ),
                      const SizedBox(height: 12),

                      // Formation selector
                      const Text('Diziliş Seç', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _formations.keys.map((f) {
                            final selected = f == _selectedFormation;
                            return GestureDetector(
                              onTap: _submitted ? null : () => setState(() { _selectedFormation = f; _playerAssignments = {}; }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primaryBlue : AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: selected ? AppColors.primaryBlue : const Color(0xFFE5E7EB)),
                                ),
                                child: Text(f, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tactical pitch
                      Container(
                        width: double.infinity,
                        height: 360,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _TacticalPitchPainter(
                              formation: _selectedFormation,
                              formations: _formations,
                              assignments: _playerAssignments,
                              posLabels: _posLabels[_selectedFormation] ?? [],
                              isHome: _isHomeTeamSelected,
                            ),
                            child: GestureDetector(
                              onTapUp: (details) {
                                if (_submitted) return;
                                final positions = _getPositionCoords(360, MediaQuery.of(context).size.width - 32);
                                int closest = 0;
                                double minDist = double.infinity;
                                for (int i = 0; i < positions.length; i++) {
                                  final dx = positions[i].dx - details.localPosition.dx;
                                  final dy = positions[i].dy - details.localPosition.dy;
                                  final dist = dx * dx + dy * dy;
                                  if (dist < minDist) { minDist = dist; closest = i; }
                                }
                                if (minDist < 1600) _editPlayerAt(closest);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${_playerAssignments.length} / $_totalPositions oyuncu seçildi • Pozisyona dokunarak oyuncu ekleyin', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 12),

                      if (!_submitted)
                        GradientButton(text: '📋 Kadroyu Gönder', onTap: _submitLineup, gradient: AppColors.orangeGradient)
                      else
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.correct.withAlpha(20), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.correct.withAlpha(80))),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_circle, color: AppColors.correct, size: 18),
                            SizedBox(width: 6),
                            Text('Kadro tahminin kaydedildi!', style: TextStyle(color: AppColors.correct, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _teamTab(String team, bool isHome) {
    final selected = _isHomeTeamSelected == isHome;
    return GestureDetector(
      onTap: _submitted ? null : () {
        setState(() { _isHomeTeamSelected = isHome; _playerAssignments = {}; });
        _loadSquad();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primaryBlue : const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: Text(team, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
      ),
    );
  }

  List<Offset> _getPositionCoords(double h, double w) {
    final rows = _formations[_selectedFormation]!;
    final positions = <Offset>[];
    final totalRows = rows.length;
    for (int r = 0; r < totalRows; r++) {
      final count = rows[r][0];
      final yRatio = (totalRows - 1 - r) / (totalRows);
      final y = 20 + yRatio * (h - 40);
      for (int c = 0; c < count; c++) {
        final x = (c + 1) * w / (count + 1);
        positions.add(Offset(x, y));
      }
    }
    return positions;
  }
}

/// Bottom sheet for picking a player from the squad
class _PlayerPickerSheet extends StatefulWidget {
  final String posLabel;
  final List<Map<String, dynamic>> allPlayers;
  final List<Map<String, dynamic>> allSquadPlayers;
  final ValueChanged<String> onSelect;

  const _PlayerPickerSheet({required this.posLabel, required this.allPlayers, required this.allSquadPlayers, required this.onSelect});

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  String _search = '';
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayPlayers = _showAll ? widget.allSquadPlayers : widget.allPlayers;
    final filtered = _search.isEmpty
        ? displayPlayers
        : displayPlayers.where((p) => (p['name'] as String).toLowerCase().contains(_search.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('${widget.posLabel} Pozisyonu - Oyuncu Seç', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _showAll ? AppColors.primaryBlue.withAlpha(30) : AppColors.bgSurface, borderRadius: BorderRadius.circular(6)),
                  child: Text(_showAll ? 'Pozisyona göre' : 'Tüm kadro', style: TextStyle(color: _showAll ? AppColors.primaryBlue : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search
          TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Oyuncu ara...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
              filled: true, fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Oyuncu bulunamadı', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final name = p['name'] as String? ?? '';
                      final number = p['number'] ?? '';
                      final position = p['position'] as String? ?? '';
                      String posIcon;
                      switch (position) {
                        case 'Goalkeeper': posIcon = '🧤'; break;
                        case 'Defender': posIcon = '🛡️'; break;
                        case 'Midfielder': posIcon = '⚙️'; break;
                        case 'Attacker': posIcon = '⚡'; break;
                        default: posIcon = '⚽';
                      }
                      return GestureDetector(
                        onTap: () => widget.onSelect(name),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text('$number', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
                              Text('$posIcon $position', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TacticalPitchPainter extends CustomPainter {
  final String formation;
  final Map<String, List<List<int>>> formations;
  final Map<int, String> assignments;
  final List<String> posLabels;
  final bool isHome;

  _TacticalPitchPainter({required this.formation, required this.formations, required this.assignments, required this.posLabels, required this.isHome});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Green pitch with stripes
    for (int i = 0; i < 12; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, h * i / 12, w, h / 12),
        Paint()..color = (i % 2 == 0) ? const Color(0xFF2E7D32) : const Color(0xFF388E3C),
      );
    }

    // Field markings
    final p = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), p);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.1, p);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, 0, w * 0.7, h * 0.14), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.86, w * 0.7, h * 0.14), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.05), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.95, w * 0.4, h * 0.05), p);

    // Draw player positions
    final rows = formations[formation]!;
    int idx = 0;
    final totalRows = rows.length;

    for (int r = 0; r < totalRows; r++) {
      final count = rows[r][0];
      final yRatio = (totalRows - 1 - r) / totalRows;
      final y = 20 + yRatio * (h - 40);

      for (int c = 0; c < count; c++) {
        final x = (c + 1) * w / (count + 1);
        final hasPlayer = assignments.containsKey(idx);
        final label = idx < posLabels.length ? posLabels[idx] : '${idx + 1}';
        final playerName = assignments[idx] ?? '';

        // Player circle
        final color = isHome ? Colors.blue : Colors.red;
        canvas.drawCircle(Offset(x, y), 16, Paint()..color = color.withAlpha(180));
        canvas.drawCircle(Offset(x, y), 16, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

        // Position label on circle
        _text(canvas, label, x, y, 9, Colors.white);

        // Player name below
        if (hasPlayer) {
          _text(canvas, playerName, x, y + 22, 7, Colors.white);
        } else {
          _text(canvas, '+ ekle', x, y + 22, 7, Colors.white54);
        }

        idx++;
      }
    }
  }

  void _text(Canvas canvas, String text, double x, double y, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TacticalPitchPainter old) => true;
}
