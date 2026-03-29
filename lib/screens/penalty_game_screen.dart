import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PenaltyGameScreen extends StatefulWidget {
  const PenaltyGameScreen({super.key});

  @override
  State<PenaltyGameScreen> createState() => _PenaltyGameScreenState();
}

class _PenaltyGameScreenState extends State<PenaltyGameScreen> with TickerProviderStateMixin {
  int _round = 0;
  int _goals = 0;
  int _saves = 0;
  bool _gameOver = false;
  static const int _totalRounds = 5;

  // Game phases
  // 0: aiming (crosshair moving), 1: power (bar filling), 2: shooting, 3: result
  int _phase = 0;

  // Aiming - crosshair moves left-right
  double _aimX = 0.5;
  double _aimDir = 1.0;
  static const double _aimSpeed = 0.012;
  Timer? _aimTimer;

  // Power bar
  double _power = 0.0;
  double _powerDir = 1.0;
  static const double _powerSpeed = 0.02;
  Timer? _powerTimer;

  // Shooting animation
  double _ballProgress = 0;
  double _keeperX = 0.5;
  double _keeperProgress = 0;
  bool _isGoal = false;
  bool _showResult = false;

  late AnimationController _shootCtrl;
  late Animation<double> _shootAnim;
  late AnimationController _keeperCtrl;
  late Animation<double> _keeperAnim;

  @override
  void initState() {
    super.initState();
    _shootCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shootAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shootCtrl, curve: Curves.easeOut));
    _keeperCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _keeperAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _keeperCtrl, curve: Curves.easeInOut));

    _shootAnim.addListener(() => setState(() => _ballProgress = _shootAnim.value));
    _keeperAnim.addListener(() => setState(() => _keeperProgress = _keeperAnim.value));

    _startAiming();
  }

  void _startAiming() {
    _phase = 0;
    _aimX = 0.5;
    _aimDir = 1.0;
    _aimTimer?.cancel();
    _aimTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        _aimX += _aimDir * _aimSpeed;
        if (_aimX >= 0.85) { _aimX = 0.85; _aimDir = -1; }
        if (_aimX <= 0.15) { _aimX = 0.15; _aimDir = 1; }
      });
    });
  }

  void _lockAim() {
    _aimTimer?.cancel();
    setState(() => _phase = 1);
    _power = 0;
    _powerDir = 1;
    _powerTimer?.cancel();
    _powerTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        _power += _powerDir * _powerSpeed;
        if (_power >= 1.0) { _power = 1.0; _powerDir = -1; }
        if (_power <= 0.0) { _power = 0.0; _powerDir = 1; }
      });
    });
  }

  void _lockPowerAndShoot() {
    _powerTimer?.cancel();
    setState(() => _phase = 2);

    // Determine aim point based on aimX and power
    // Higher power = higher shot (lower y)
    final aimY = 0.35 - _power * 0.25; // 0.10 (top) to 0.35 (bottom of goal)

    // Random keeper dive
    final rng = Random();
    _keeperX = rng.nextDouble() * 0.6 + 0.2;

    _shootCtrl.forward(from: 0);
    _keeperCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 600), () {
      // Check goal
      bool inGoal = _aimX >= 0.15 && _aimX <= 0.85 && aimY >= 0.05 && aimY <= 0.40;
      // Keeper save zone: wider keeper (0.22 width contact)
      bool saved = inGoal && (_aimX - _keeperX).abs() < 0.22;
      // If power is too low, shot is weak and easily saved
      if (_power < 0.2) saved = true;
      // If power is too high (>0.95), shot goes over the bar
      if (_power > 0.95) { inGoal = false; saved = false; }

      setState(() {
        _showResult = true;
        _isGoal = inGoal && !saved;
        _phase = 3;
        if (_isGoal) _goals++;
        else _saves++;
        _round++;
        if (_round >= _totalRounds) _gameOver = true;
      });

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!_gameOver && mounted) {
          setState(() { _showResult = false; _ballProgress = 0; _keeperProgress = 0; });
          _shootCtrl.reset();
          _keeperCtrl.reset();
          _startAiming();
        }
      });
    });
  }

  void _handleTap() {
    if (_gameOver) return;
    switch (_phase) {
      case 0: _lockAim(); break;
      case 1: _lockPowerAndShoot(); break;
    }
  }

  void _restart() {
    setState(() { _round = 0; _goals = 0; _saves = 0; _gameOver = false; _showResult = false; _ballProgress = 0; _keeperProgress = 0; });
    _shootCtrl.reset(); _keeperCtrl.reset();
    _startAiming();
  }

  @override
  void dispose() {
    _aimTimer?.cancel(); _powerTimer?.cancel();
    _shootCtrl.dispose(); _keeperCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Penaltı Atışı 🥅', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
            ),

            // Scoreboard
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: AppDecorations.cardBox(),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Column(children: [
                  const Text('Gol', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Text('$_goals', style: const TextStyle(color: AppColors.correct, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
                Text('$_round/$_totalRounds', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Column(children: [
                  const Text('Kaçan', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Text('$_saves', style: const TextStyle(color: AppColors.wrong, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),

            // Field
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final fw = constraints.maxWidth - 16;
                final fh = constraints.maxHeight;

                return GestureDetector(
                  onTapDown: (_) => _handleTap(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomPaint(
                      size: Size(fw, fh),
                      painter: _PenaltyPainter(
                        aimX: _aimX,
                        power: _power,
                        phase: _phase,
                        ballProgress: _ballProgress,
                        keeperX: _keeperX,
                        keeperProgress: _keeperProgress,
                        showResult: _showResult,
                        isGoal: _isGoal,
                        gameOver: _gameOver,
                        goals: _goals,
                        totalRounds: _totalRounds,
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Power bar (visible during power phase)
            if (_phase == 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Column(children: [
                  const Text('💪 GÜÇ AYARLA', style: TextStyle(color: AppColors.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 18,
                      child: LinearProgressIndicator(
                        value: _power,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation(_power > 0.9 ? Colors.red : _power > 0.6 ? AppColors.primaryOrange : AppColors.correct),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Zayıf', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                    Text('${(_power * 100).toInt()}%', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Text('Aşırı!', style: TextStyle(color: AppColors.wrong, fontSize: 9)),
                  ]),
                ]),
              ),

            // Bottom instructions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _gameOver
                ? Row(children: [
                    Expanded(child: ElevatedButton(
                      onPressed: _restart,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Tekrar Oyna', style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                  ])
                : Text(
                    _phase == 0 ? '🎯 Dokunarak nişanı kilitle!' :
                    _phase == 1 ? '💪 Dokunarak güç ayarla!' :
                    '⚽ Atış!',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PenaltyPainter extends CustomPainter {
  final double aimX, power;
  final int phase;
  final double ballProgress, keeperX, keeperProgress;
  final bool showResult, isGoal, gameOver;
  final int goals, totalRounds;

  _PenaltyPainter({
    required this.aimX, required this.power, required this.phase,
    required this.ballProgress, required this.keeperX, required this.keeperProgress,
    required this.showResult, required this.isGoal, required this.gameOver,
    required this.goals, required this.totalRounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Grass with gradient
    final grassGrad = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = grassGrad.createShader(Rect.fromLTWH(0, 0, w, h)));
    // Darker stripes
    for (int i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, h * i / 10, w, h / 10), Paint()..color = const Color(0xFF388E3C).withAlpha(80));
    }

    // Goal frame
    final goalL = w * 0.12, goalR = w * 0.88, goalTop = h * 0.04, goalBottom = h * 0.35;
    final goalRect = Rect.fromLTRB(goalL, goalTop, goalR, goalBottom);

    // Goal net (detailed)
    final netPaint = Paint()..color = Colors.white.withAlpha(25)..strokeWidth = 0.5;
    for (double x = goalL; x <= goalR; x += 10) {
      canvas.drawLine(Offset(x, goalTop), Offset(x, goalBottom), netPaint);
    }
    for (double y = goalTop; y <= goalBottom; y += 10) {
      canvas.drawLine(Offset(goalL, y), Offset(goalR, y), netPaint);
    }
    // Goal posts (thick white)
    final postPaint = Paint()..color = Colors.white..strokeWidth = 5..style = PaintingStyle.stroke;
    canvas.drawRect(goalRect, postPaint);

    // Penalty spot
    canvas.drawCircle(Offset(w / 2, h * 0.75), 5, Paint()..color = Colors.white);

    // Penalty arc
    canvas.drawArc(Rect.fromCenter(center: Offset(w / 2, h * 0.75), width: w * 0.3, height: h * 0.12), pi, pi, false,
      Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Keeper (larger and more detailed)
    final keeperStartX = w / 2;
    final keeperEndX = keeperX * w;
    final kx = keeperStartX + (keeperEndX - keeperStartX) * keeperProgress;
    final ky = goalBottom - 20;
    final keeperWidth = w * 0.12; // Wider keeper

    // Keeper body
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(kx, ky), width: keeperWidth * 0.7, height: 55), const Radius.circular(6)),
      Paint()..color = Colors.yellow.shade700);
    // Keeper shorts
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(kx, ky + 22), width: keeperWidth * 0.65, height: 16), const Radius.circular(4)),
      Paint()..color = Colors.black87);
    // Head
    canvas.drawCircle(Offset(kx, ky - 35), 13, Paint()..color = const Color(0xFFFFCC80));
    // Hair
    canvas.drawArc(Rect.fromCenter(center: Offset(kx, ky - 38), width: 26, height: 14), pi, pi, false,
      Paint()..color = Colors.brown..style = PaintingStyle.fill);
    // Gloves (extend when diving)
    final armDx = (keeperEndX - keeperStartX).sign * keeperProgress * 30;
    final gloveColor = Colors.green.shade600;
    // Left arm
    canvas.drawLine(Offset(kx - 18, ky - 12), Offset(kx - 18 + armDx, ky - 30), Paint()..color = Colors.yellow.shade700..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(kx - 18 + armDx, ky - 32), 7, Paint()..color = gloveColor);
    // Right arm
    canvas.drawLine(Offset(kx + 18, ky - 12), Offset(kx + 18 + armDx, ky - 30), Paint()..color = Colors.yellow.shade700..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(kx + 18 + armDx, ky - 32), 7, Paint()..color = gloveColor);
    // Legs
    canvas.drawLine(Offset(kx - 8, ky + 28), Offset(kx - 12, ky + 45), Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(kx + 8, ky + 28), Offset(kx + 12, ky + 45), Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 4..strokeCap = StrokeCap.round);
    // Boots
    canvas.drawCircle(Offset(kx - 12, ky + 47), 5, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(kx + 12, ky + 47), 5, Paint()..color = Colors.black87);

    // Aim crosshair (visible during aiming phase)
    if (phase == 0) {
      final ax = aimX * w;
      final ay = h * 0.20;
      // Crosshair
      canvas.drawLine(Offset(ax - 15, ay), Offset(ax + 15, ay), Paint()..color = Colors.red..strokeWidth = 2);
      canvas.drawLine(Offset(ax, ay - 15), Offset(ax, ay + 15), Paint()..color = Colors.red..strokeWidth = 2);
      canvas.drawCircle(Offset(ax, ay), 12, Paint()..color = Colors.red.withAlpha(60)..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(Offset(ax, ay), 4, Paint()..color = Colors.red);
    }

    // Ball
    if (phase >= 2 && ballProgress > 0) {
      final startX = w / 2, startY = h * 0.72;
      final targetY = 0.35 - power * 0.25;
      final endX = aimX * w, endY = targetY * h;
      final bx = startX + (endX - startX) * ballProgress;
      final by = startY + (endY - startY) * ballProgress;
      final bSize = 14 - ballProgress * 4;
      canvas.drawCircle(Offset(bx + 1, by + 1), bSize, Paint()..color = Colors.black26);
      canvas.drawCircle(Offset(bx, by), bSize, Paint()..color = Colors.white);
      // Ball pattern
      canvas.drawCircle(Offset(bx, by), bSize, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1);
    } else if (phase < 2) {
      // Ball at penalty spot
      canvas.drawCircle(Offset(w / 2, h * 0.72), 13, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w / 2, h * 0.72), 13, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1);
      canvas.drawCircle(Offset(w / 2 - 2, h * 0.72 - 2), 4, Paint()..color = Colors.white.withAlpha(80));
    }

    // Result text
    if (showResult) {
      final text = isGoal ? 'GOL! ⚽🎉' : power > 0.95 ? 'AUTA! ⬆️' : 'KURTARIŞ! 🧤';
      final color = isGoal ? Colors.green.shade300 : Colors.red.shade300;
      final bgRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w / 2, h * 0.50), width: w * 0.6, height: 50), const Radius.circular(12));
      canvas.drawRRect(bgRect, Paint()..color = Colors.black.withAlpha(180));
      _drawText(canvas, text, w / 2, h * 0.50, 22, color);
    }

    if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black54);
      _drawText(canvas, '🏆 Sonuç: $goals/$totalRounds gol!', w / 2, h / 2 - 10, 24, Colors.white);
      _drawText(canvas, goals >= 4 ? 'Harika atış! 🎯' : goals >= 2 ? 'İyi deneme!' : 'Daha çok çalış!', w / 2, h / 2 + 25, 16, Colors.white70);
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color color) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PenaltyPainter old) => true;
}
