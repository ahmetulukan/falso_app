import 'dart:math';
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
  String? _selectedTeam;
  bool _answered = false;
  late List<String> _teamOptions;

  @override
  void initState() {
    super.initState();
    _teams = QuestionService.getCityFinderTeams();
    _teams.shuffle();
    _buildOptions();
  }

  void _buildOptions() {
    final correct = _teams[_currentIndex].name;
    final allTeams = _teams.map((t) => t.name).where((n) => n != correct).toList();
    allTeams.shuffle();
    _teamOptions = [correct, ...allTeams.take(3)];
    _teamOptions.shuffle();
  }

  void _selectTeam(String team) {
    if (_answered) return;
    final isCorrect = team == _teams[_currentIndex].name;
    setState(() { _selectedTeam = team; _answered = true; if (isCorrect) { _score += 100; _correctCount++; } });
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (_currentIndex < _teams.length - 1) {
      setState(() { _currentIndex++; _selectedTeam = null; _answered = false; });
      _buildOptions();
    } else { _showResults(); }
  }

  void _showResults() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(children: [
        const Icon(Icons.location_city, color: AppColors.primaryOrange, size: 56),
        const SizedBox(height: 12),
        const Text('Oyun Bitti!', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$_score puan', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$_correctCount / ${_teams.length} doğru', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ]),
      actions: [GradientButton(text: 'Ana Sayfaya Dön', onTap: () { Navigator.pop(context); Navigator.pop(context); }, gradient: AppColors.blueGradient)],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final team = _teams[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top bar
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
                Text('${_currentIndex + 1}/${_teams.length}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: AppDecorations.glassBox(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, color: AppColors.primaryOrange, size: 16),
                    const SizedBox(width: 4),
                    Text('$_score', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: (_currentIndex + 1) / _teams.length, backgroundColor: const Color(0xFFE5E7EB), valueColor: const AlwaysStoppedAnimation(AppColors.categoryBlue), minHeight: 4),
              ),
              const SizedBox(height: 10),

              // Map area — zoomed to city region with real borders
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A7BD5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CustomPaint(
                    painter: _RealMapPainter(
                      lat: team.lat, lon: team.lon,
                      cityName: team.city, country: team.country,
                      showCity: _answered,
                    ),
                    size: const Size(double.infinity, 220),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Question
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: AppDecorations.cardBox(),
                child: Column(children: [
                  const Text('📍 Bu şehirdeki takım hangisi?', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.flag, color: AppColors.primaryBlue, size: 14),
                    const SizedBox(width: 4),
                    Text('${team.country} • ${team.league}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ]),
                  if (_answered) ...[
                    const SizedBox(height: 4),
                    Text(team.city, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ]),
              ),
              const SizedBox(height: 10),

              // 2x2 grid options
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.8,
                  children: List.generate(_teamOptions.length, (i) {
                    final t = _teamOptions[i];
                    bool? isCorrect;
                    if (_answered) {
                      if (t == team.name) isCorrect = true;
                      else if (t == _selectedTeam) isCorrect = false;
                    }
                    return _gridOption(t, _selectedTeam == t, isCorrect, () => _selectTeam(t));
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridOption(String text, bool isSelected, bool? isCorrect, VoidCallback onTap) {
    Color bg = AppColors.bgSurface;
    Color textColor = AppColors.textPrimary;
    if (isCorrect == true) { bg = AppColors.correct; textColor = Colors.white; }
    else if (isCorrect == false && isSelected) { bg = AppColors.wrong; textColor = Colors.white; }
    else if (isSelected) { bg = AppColors.primaryBlue; textColor = Colors.white; }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Realistic map painter with detailed country border polygons
class _RealMapPainter extends CustomPainter {
  final double lat, lon;
  final String cityName, country;
  final bool showCity;

  _RealMapPainter({required this.lat, required this.lon, required this.cityName, required this.country, required this.showCity});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Zoomed view: center on city with ±6° range
    const viewRange = 6.0;
    final aspect = w / h;
    final minLat = lat - viewRange;
    final maxLat = lat + viewRange;
    final minLon = lon - viewRange * aspect;
    final maxLon = lon + viewRange * aspect;

    // Ocean gradient
    final oceanGrad = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = oceanGrad.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Draw all countries
    final landPaint = Paint()..color = const Color(0xFFE8ECF0);
    final borderPaint = Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final highlightPaint = Paint()..color = const Color(0xFFFED7AA); // highlight country

    Offset project(double pLat, double pLon) {
      final px = ((pLon - minLon) / (maxLon - minLon)) * w;
      final py = (1 - (pLat - minLat) / (maxLat - minLat)) * h;
      return Offset(px, py);
    }

    final countries = _getDetailedCountries();
    for (final entry in countries.entries) {
      final name = entry.key;
      final polygons = entry.value;
      final isHighlight = name.toLowerCase() == country.toLowerCase() ||
          (country == 'Türkiye' && name == 'Turkey') ||
          (country == 'İngiltere' && name == 'UK') ||
          (country == 'İspanya' && name == 'Spain') ||
          (country == 'Almanya' && name == 'Germany') ||
          (country == 'İtalya' && name == 'Italy') ||
          (country == 'Fransa' && name == 'France') ||
          (country == 'Hollanda' && name == 'Netherlands') ||
          (country == 'Portekiz' && name == 'Portugal') ||
          (country == 'İskoçya' && name == 'Scotland');

      for (final poly in polygons) {
        final points = poly.map((p) => project(p[0], p[1])).toList();
        if (points.any((p) => p.dx > -w * 0.5 && p.dx < w * 1.5 && p.dy > -h * 0.5 && p.dy < h * 1.5)) {
          final path = Path()..addPolygon(points, true);
          canvas.drawPath(path, isHighlight ? highlightPaint : landPaint);
          canvas.drawPath(path, borderPaint);
        }
      }
    }

    // Grid lines (subtle)
    final gridPaint = Paint()..color = Colors.white.withAlpha(20)..strokeWidth = 0.5;
    for (double gl = (minLat / 5).floorToDouble() * 5; gl <= maxLat; gl += 5) {
      final y = (1 - (gl - minLat) / (maxLat - minLat)) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (double gl = (minLon / 5).floorToDouble() * 5; gl <= maxLon; gl += 5) {
      final x = ((gl - minLon) / (maxLon - minLon)) * w;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // City marker at center
    final cx = w / 2, cy = h / 2;

    // Pulse rings
    canvas.drawCircle(Offset(cx, cy), 24, Paint()..color = Colors.red.withAlpha(20));
    canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = Colors.red.withAlpha(35));
    canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = Colors.red.withAlpha(50));
    // Shadow
    canvas.drawCircle(Offset(cx + 1, cy + 1), 8, Paint()..color = Colors.black26);
    // Pin
    canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = Colors.red.shade700);
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.white);

    // City name or question mark
    if (showCity) {
      _label(canvas, cityName, cx, cy - 24, 12, Colors.white, Colors.red.shade700);
    } else {
      _label(canvas, '?', cx, cy - 24, 15, Colors.white, Colors.red.shade700);
    }

    // Country hint at corner
    _drawText(canvas, country, w - 10, h - 12, 10, Colors.white70);
  }

  void _label(Canvas canvas, String text, double x, double y, double size, Color textColor, Color bg) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: textColor, fontSize: size, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: tp.width + 16, height: tp.height + 8), const Radius.circular(6));
    canvas.drawRRect(rect, Paint()..color = bg);
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color c) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr, textAlign: TextAlign.right)..layout();
    tp.paint(canvas, Offset(x - tp.width, y - tp.height));
  }

  /// Detailed country polygons with realistic borders [lat, lon]
  Map<String, List<List<List<double>>>> _getDetailedCountries() {
    return {
      'Spain': [[
        [43.4, -8.3], [43.8, -7.0], [43.3, -2.0], [42.8, -1.7], [42.7, 0.7], [42.5, 3.1],
        [41.4, 2.2], [40.5, 0.5], [39.9, -0.1], [38.8, 0.2], [38.0, -0.5], [37.8, -1.6],
        [36.7, -2.1], [36.0, -5.6], [37.0, -7.4], [37.2, -8.9], [38.7, -9.5], [39.5, -9.1],
        [40.2, -8.8], [41.9, -8.9], [42.1, -8.5],
      ]],
      'Portugal': [[
        [42.1, -8.5], [41.9, -8.9], [40.2, -8.8], [39.5, -9.1], [38.7, -9.5],
        [37.2, -8.9], [37.0, -7.4], [37.2, -7.4], [38.0, -7.0], [39.0, -7.5],
        [40.0, -7.0], [41.0, -7.2], [42.0, -7.5],
      ]],
      'France': [[
        [51.1, 2.5], [50.5, 1.5], [48.9, -1.8], [48.6, -4.5], [47.5, -3.0], [46.2, -1.2],
        [45.0, -1.1], [43.5, -1.5], [42.5, 0.7], [42.7, 0.7], [43.3, -2.0], [43.8, -7.0],
        [43.4, -8.3], [43.3, 3.0], [43.0, 6.0], [43.5, 7.0], [46.0, 7.0],
        [47.0, 7.5], [48.5, 8.0], [49.0, 6.5], [49.5, 6.0], [50.4, 4.0],
      ]],
      'UK': [[
        [50.0, -5.7], [50.8, -1.0], [51.5, 1.4], [52.0, 1.7], [52.9, 0.3],
        [53.5, -0.1], [54.0, -1.0], [55.0, -1.5], [55.8, -2.0], [56.5, -3.3],
        [57.5, -5.0], [58.5, -5.0], [58.6, -3.0], [57.5, -2.0], [56.0, -2.5],
        [55.5, -4.5], [54.0, -5.0], [53.0, -4.5], [52.0, -5.0], [51.5, -5.0],
      ]],
      'Scotland': [[
        [55.0, -5.5], [55.0, -1.5], [55.8, -2.0], [56.5, -3.3], [57.5, -5.0],
        [58.5, -5.0], [58.6, -3.0], [57.5, -2.0], [56.0, -2.5], [55.5, -4.5],
      ]],
      'Ireland': [[
        [51.4, -10.0], [51.5, -6.0], [52.5, -6.0], [53.5, -6.0], [54.5, -6.0],
        [55.4, -7.5], [55.2, -8.0], [54.0, -10.0], [52.0, -10.5],
      ]],
      'Italy': [[
        [47.0, 12.0], [46.5, 13.5], [45.5, 13.8], [44.0, 12.5], [43.5, 11.0],
        [42.5, 12.0], [41.5, 13.5], [41.0, 15.0], [40.5, 15.5], [40.0, 16.5],
        [39.0, 16.5], [38.2, 15.7], [37.5, 15.1], [38.0, 12.5], [40.0, 12.0],
        [41.0, 11.0], [42.5, 10.0], [44.0, 8.0], [44.5, 7.5], [45.5, 7.0],
        [46.0, 9.0], [46.5, 11.0],
      ],
      // Sicily
      [
        [38.2, 12.5], [38.3, 15.5], [37.5, 15.1], [37.0, 14.0], [37.5, 13.0],
      ],
      // Sardinia
      [
        [41.3, 8.2], [41.3, 9.8], [39.8, 9.6], [38.9, 8.3], [39.2, 8.0],
      ]],
      'Germany': [[
        [54.8, 8.3], [54.3, 10.0], [54.0, 12.0], [53.0, 14.0], [51.5, 15.0],
        [51.0, 14.5], [50.5, 12.5], [49.0, 13.0], [47.5, 13.0], [47.3, 10.5],
        [47.5, 7.5], [49.0, 8.0], [49.5, 6.0], [50.5, 6.0], [51.5, 6.5],
        [53.0, 7.0],
      ]],
      'Turkey': [[
        [42.0, 26.0], [41.5, 28.0], [42.0, 29.0], [42.0, 32.0], [41.0, 33.5],
        [41.5, 36.0], [42.0, 36.0], [41.0, 41.0], [41.2, 43.5],
        [39.5, 44.5], [37.0, 44.5], [37.0, 42.0], [36.5, 36.5], [36.0, 36.0],
        [36.2, 33.0], [36.7, 30.0], [36.2, 29.0], [36.5, 28.0],
        [37.0, 27.0], [38.3, 26.5], [39.0, 26.5], [40.0, 26.0], [41.0, 26.5],
      ],
      // Thrace
      [
        [42.0, 26.0], [41.0, 26.5], [40.0, 26.0], [40.5, 26.0], [41.0, 26.0],
        [41.0, 28.0], [41.5, 28.0], [42.0, 26.0],
      ]],
      'Greece': [[
        [41.5, 20.0], [41.7, 24.0], [41.2, 26.0], [40.0, 26.0], [39.0, 26.5],
        [38.5, 24.0], [37.5, 23.5], [36.5, 22.5], [36.4, 22.0], [37.0, 21.5],
        [37.5, 21.0], [38.0, 21.0], [38.5, 20.5], [39.0, 20.0], [39.5, 20.5],
      ]],
      'Netherlands': [[
        [53.4, 7.2], [53.2, 5.0], [52.0, 4.0], [51.4, 3.4], [51.0, 4.0],
        [51.5, 5.5], [51.5, 6.0], [52.0, 7.0], [53.0, 7.0],
      ]],
      'Belgium': [[
        [51.5, 2.5], [51.4, 3.4], [51.0, 4.0], [51.5, 5.5], [51.5, 6.0],
        [50.5, 6.0], [49.5, 6.0], [49.5, 5.5], [50.0, 4.0], [50.5, 2.5],
      ]],
      'Switzerland': [[
        [47.5, 7.5], [47.5, 10.5], [47.0, 10.0], [46.0, 9.0], [45.5, 7.0],
        [46.0, 6.0], [46.5, 6.0], [47.0, 7.0],
      ]],
      'Austria': [[
        [47.5, 10.5], [47.5, 13.0], [47.8, 16.0], [48.0, 17.0], [47.5, 16.5],
        [46.5, 16.0], [46.5, 13.5], [47.0, 12.0], [47.0, 10.0],
      ]],
      'Poland': [[
        [54.4, 14.0], [54.8, 18.5], [54.3, 23.0], [52.5, 23.5], [50.0, 24.0],
        [49.5, 22.5], [49.0, 18.5], [50.0, 16.0], [51.0, 14.5], [53.0, 14.0],
      ]],
      'Czech': [[
        [51.0, 14.5], [50.5, 12.5], [49.0, 13.0], [49.0, 18.5], [50.0, 16.0],
      ]],
      'Slovakia': [[
        [49.0, 18.5], [49.5, 22.5], [48.5, 22.0], [48.0, 17.0], [48.5, 17.0],
      ]],
      'Hungary': [[
        [48.0, 17.0], [48.5, 22.0], [47.0, 22.5], [46.0, 21.0], [46.0, 19.0],
        [46.5, 16.0], [47.5, 16.5],
      ]],
      'Romania': [[
        [48.0, 22.0], [48.5, 26.5], [47.5, 28.5], [46.0, 30.0], [44.0, 29.0],
        [43.5, 28.0], [44.0, 26.0], [44.0, 22.5], [46.0, 21.0], [47.0, 22.5],
      ]],
      'Bulgaria': [[
        [44.0, 22.5], [44.0, 26.0], [43.5, 28.0], [43.0, 28.0], [42.0, 28.0],
        [42.0, 26.0], [41.2, 26.0], [41.7, 24.0], [42.0, 23.0], [42.5, 22.5],
        [43.5, 22.5],
      ]],
      'Serbia': [[
        [46.0, 19.0], [46.0, 21.0], [44.0, 22.5], [43.5, 22.5], [42.5, 22.5],
        [42.5, 21.5], [43.0, 20.0], [44.5, 19.0], [45.0, 19.0],
      ]],
      'Croatia': [[
        [46.5, 16.0], [46.0, 19.0], [45.0, 19.0], [44.5, 19.0], [43.0, 17.0],
        [42.5, 18.5], [43.0, 16.0], [44.0, 15.0], [45.0, 14.0], [45.5, 13.8],
        [46.5, 13.5],
      ]],
      'Bosnia': [[
        [45.0, 19.0], [44.5, 19.0], [43.0, 20.0], [43.0, 17.0], [42.5, 18.5],
        [43.0, 17.0], [44.5, 16.0], [45.0, 16.5],
      ]],
      'Denmark': [[
        [57.7, 10.5], [56.5, 8.0], [55.5, 8.0], [55.0, 9.5], [55.0, 12.5],
        [55.5, 12.5], [56.0, 12.5], [57.0, 10.5],
      ]],
      'Norway': [[
        [58.0, 6.0], [59.0, 5.0], [60.5, 5.0], [62.0, 5.5], [64.0, 10.0],
        [66.0, 13.0], [69.0, 16.0], [71.0, 26.0], [70.0, 28.0], [69.0, 18.0],
        [65.0, 14.0], [62.0, 12.0], [60.0, 11.0], [59.0, 10.5], [58.0, 8.0],
      ]],
      'Sweden': [[
        [56.0, 12.5], [55.5, 14.0], [56.0, 16.0], [58.0, 16.5], [59.0, 18.5],
        [60.5, 18.0], [63.0, 18.0], [65.0, 14.0], [66.0, 15.0], [69.0, 18.0],
        [69.0, 16.0], [66.0, 13.0], [62.0, 12.0], [60.0, 11.0], [59.0, 10.5],
        [58.0, 11.5], [57.0, 12.0],
      ]],
      'Finland': [[
        [60.0, 20.0], [60.5, 24.0], [64.0, 28.0], [66.0, 26.0], [69.0, 28.0],
        [70.0, 28.0], [69.5, 25.0], [66.0, 24.0], [63.0, 22.0], [60.5, 22.0],
        [60.5, 18.0],
      ]],
      'Ukraine': [[
        [52.0, 24.0], [51.5, 31.0], [52.0, 36.0], [50.5, 40.0], [48.5, 40.0],
        [46.0, 38.0], [45.0, 36.0], [44.5, 34.0], [46.0, 30.0], [47.5, 28.5],
        [48.5, 26.5], [48.0, 22.0], [49.5, 22.5], [50.0, 24.0],
      ]],
      'Morocco': [[
        [35.8, -5.4], [35.2, -2.0], [34.0, -1.8], [32.0, -1.0], [30.0, -5.0],
        [29.0, -10.0], [32.0, -12.0], [34.0, -7.0],
      ]],
      'Algeria': [[
        [37.0, 6.0], [36.5, 3.0], [35.2, -2.0], [34.0, -1.8], [32.0, -1.0],
        [30.0, 0.0], [28.0, 2.0], [28.0, 8.0], [33.0, 9.5], [37.0, 8.5],
      ]],
      'Tunisia': [[
        [37.3, 8.5], [37.0, 10.0], [34.5, 10.5], [33.5, 8.0], [33.0, 9.5], [37.0, 8.5],
      ]],
      'Libya': [[
        [33.5, 12.0], [33.0, 11.0], [33.0, 9.5], [28.0, 8.0], [28.0, 12.0],
        [25.0, 17.0], [30.0, 20.0], [32.5, 25.0], [32.0, 12.0],
      ]],
    };
  }

  @override
  bool shouldRepaint(covariant _RealMapPainter old) => old.lat != lat || old.lon != lon || old.showCity != showCity;
}
