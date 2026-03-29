import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class JugglingGameScreen extends StatefulWidget {
  const JugglingGameScreen({super.key});

  @override
  State<JugglingGameScreen> createState() => _JugglingGameScreenState();
}

class _JugglingGameScreenState extends State<JugglingGameScreen> {
  double _ballX = 0.5, _ballY = 0.4;
  double _ballVx = 0, _ballVy = 0;
  int _score = 0;
  int _bestScore = 0;
  int _combo = 0;
  int _bestCombo = 0;
  bool _playing = false;
  bool _gameOver = false;
  Timer? _timer;
  bool _showKickEffect = false;
  double _kickX = 0, _kickY = 0;

  // Improved physics
  static const double _gravity = 0.0004;
  static const double _ballRadius = 0.045;
  static const double _touchRadius = 0.18; // wider touch area
  static const double _kickVy = -0.018; // stronger upward kick
  static const double _maxVx = 0.008;
  static const double _friction = 0.97; // horizontal friction

  // Visual
  double _ballRotation = 0;
  int _comboTimer = 0;

  void _start() {
    setState(() {
      _ballX = 0.5; _ballY = 0.4; _ballVx = 0; _ballVy = 0;
      _score = 0; _combo = 0; _playing = true; _gameOver = false;
      _showKickEffect = false; _ballRotation = 0; _comboTimer = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
  }

  void _update() {
    if (!_playing) return;
    setState(() {
      _ballVy += _gravity;
      _ballX += _ballVx;
      _ballY += _ballVy;
      _ballRotation += _ballVx * 8;
      _ballVx *= _friction;

      // Reduce combo timer
      if (_comboTimer > 0) _comboTimer--;

      // Wall bounce (soft)
      if (_ballX <= _ballRadius) { _ballX = _ballRadius; _ballVx = _ballVx.abs() * 0.6; }
      if (_ballX >= 1 - _ballRadius) { _ballX = 1 - _ballRadius; _ballVx = -_ballVx.abs() * 0.6; }

      // Ball fell below screen
      if (_ballY > 1.1) {
        _playing = false;
        _gameOver = true;
        _timer?.cancel();
        if (_score > _bestScore) _bestScore = _score;
        if (_combo > _bestCombo) _bestCombo = _combo;
      }

      // Fade kick effect
      if (_showKickEffect && _comboTimer <= 0) _showKickEffect = false;
    });
  }

  void _tapKick(TapDownDetails details, Size fieldSize) {
    if (!_playing || _gameOver) return;
    final tapX = details.localPosition.dx / fieldSize.width;
    final tapY = details.localPosition.dy / fieldSize.height;
    final dx = _ballX - tapX;
    final dy = _ballY - tapY;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < _touchRadius) {
      setState(() {
        // Upward kick
        _ballVy = _kickVy;
        // Slight horizontal push based on tap offset
        _ballVx += (dx * 0.008).clamp(-_maxVx, _maxVx);

        _score++;
        _combo++;
        _comboTimer = 60;
        _showKickEffect = true;
        _kickX = tapX;
        _kickY = tapY;
      });
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Top Sektirme ⚽', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
            ),

            // Score bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: AppDecorations.cardBox(),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Column(children: [
                  const Text('Skor', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Text('$_score', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
                Column(children: [
                  const Text('Combo', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Text('$_combo', style: TextStyle(color: _combo > 5 ? AppColors.primaryOrange : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
                Column(children: [
                  const Text('En İyi', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Text('$_bestScore', style: const TextStyle(color: AppColors.correct, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ),
            const SizedBox(height: 4),

            // Game field
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final fieldSize = Size(constraints.maxWidth - 16, constraints.maxHeight);

                return GestureDetector(
                  onTapDown: (d) => _tapKick(d, fieldSize),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                    child: CustomPaint(
                      size: fieldSize,
                      painter: _JugglingPainter(
                        ballX: _ballX, ballY: _ballY,
                        ballR: _ballRadius,
                        ballRotation: _ballRotation,
                        playing: _playing, gameOver: _gameOver,
                        score: _score, bestScore: _bestScore, combo: _combo, bestCombo: _bestCombo,
                        showKick: _showKickEffect, kickX: _kickX, kickY: _kickY,
                        comboTimer: _comboTimer,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: !_playing
                ? ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: Text(_gameOver ? 'Tekrar Oyna' : '▶ Başla', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )
                : const Text('Topa dokunarak sektir! ⚽', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _JugglingPainter extends CustomPainter {
  final double ballX, ballY, ballR, ballRotation;
  final bool playing, gameOver, showKick;
  final int score, bestScore, combo, bestCombo, comboTimer;
  final double kickX, kickY;

  _JugglingPainter({
    required this.ballX, required this.ballY, required this.ballR,
    required this.ballRotation,
    required this.playing, required this.gameOver,
    required this.score, required this.bestScore,
    required this.combo, required this.bestCombo,
    required this.showKick, required this.kickX, required this.kickY,
    required this.comboTimer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Sky gradient
    final skyGrad = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF87CEEB), const Color(0xFF5DADE2), const Color(0xFF2E86C1)],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.75), Paint()..shader = skyGrad.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Sun
    canvas.drawCircle(Offset(w * 0.85, h * 0.08), 25, Paint()..color = Colors.yellow.shade300);
    canvas.drawCircle(Offset(w * 0.85, h * 0.08), 35, Paint()..color = Colors.yellow.shade100.withAlpha(50));

    // Clouds
    _drawCloud(canvas, w * 0.2, h * 0.06, 18);
    _drawCloud(canvas, w * 0.55, h * 0.12, 14);
    _drawCloud(canvas, w * 0.75, h * 0.20, 16);

    // Grass with gradient
    final grassGrad = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
    );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), Paint()..shader = grassGrad.createShader(Rect.fromLTWH(0, h * 0.75, w, h * 0.25)));
    // Grass blades
    final bladePaint = Paint()..color = const Color(0xFF388E3C)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final rng = Random(42);
    for (int i = 0; i < 40; i++) {
      final bx = rng.nextDouble() * w;
      final by = h * 0.75 + rng.nextDouble() * 5;
      canvas.drawLine(Offset(bx, by), Offset(bx + (rng.nextDouble() - 0.5) * 4, by - 4 - rng.nextDouble() * 6), bladePaint);
    }

    // Ball shadow (on grass, size depends on height)
    if (playing || gameOver) {
      final shadowScale = (ballY.clamp(0, 1) * 1.5 + 0.3).clamp(0.3, 1.5);
      final shadowX = ballX * w;
      final shadowY = h * 0.77;
      canvas.drawOval(Rect.fromCenter(center: Offset(shadowX, shadowY), width: ballR * w * 2.5 * shadowScale, height: ballR * w * 0.5 * shadowScale),
        Paint()..color = Colors.black.withAlpha((30 * shadowScale).toInt()));
    }

    // Ball
    final bx = ballX * w, by = ballY * h;
    final br = ballR * w;

    if (playing || gameOver) {
      // Ball base
      canvas.drawCircle(Offset(bx + 1, by + 2), br, Paint()..color = Colors.black.withAlpha(30));
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.white);

      // Pentagon pattern
      canvas.save();
      canvas.translate(bx, by);
      final pp = Paint()..color = Colors.black87;
      for (int i = 0; i < 5; i++) {
        final angle = ballRotation + i * pi * 2 / 5;
        final cx = cos(angle) * br * 0.55;
        final cy = sin(angle) * br * 0.55;
        _drawPentagon(canvas, cx, cy, br * 0.25, pp);
      }
      canvas.restore();

      // Ball outline
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
      // Shine
      canvas.drawCircle(Offset(bx - br * 0.3, by - br * 0.3), br * 0.15, Paint()..color = Colors.white.withAlpha(120));
    }

    // Kick effect
    if (showKick && comboTimer > 30) {
      final effectX = kickX * w, effectY = kickY * h;
      // Foot icon
      canvas.drawOval(Rect.fromCenter(center: Offset(effectX, effectY + 10), width: 30, height: 14),
        Paint()..color = Colors.brown.shade600);
      // Spark lines
      final sparkPaint = Paint()..color = Colors.yellow.shade200..strokeWidth = 2..strokeCap = StrokeCap.round;
      for (int i = 0; i < 6; i++) {
        final a = i * pi / 3 + ballRotation;
        final len = 8.0 + (comboTimer - 30) * 0.3;
        canvas.drawLine(
          Offset(effectX + cos(a) * 12, effectY + sin(a) * 12),
          Offset(effectX + cos(a) * (12 + len), effectY + sin(a) * (12 + len)),
          sparkPaint,
        );
      }
    }

    // Combo indicator
    if (combo > 2 && playing) {
      final comboText = 'x$combo COMBO!';
      final color = combo > 10 ? Colors.red.shade300 : combo > 5 ? Colors.orange.shade300 : Colors.yellow.shade300;
      _text(canvas, comboText, w / 2, h * 0.15, 20 + min(combo.toDouble(), 10), color);
    }

    // Start overlay
    if (!playing && !gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black38);
      _text(canvas, '⚽ Top Sektirme', w / 2, h / 2 - 30, 26, Colors.white);
      _text(canvas, 'Topa dokunarak sektir!', w / 2, h / 2 + 5, 14, Colors.white70);
      _text(canvas, 'Başlamak için aşağıdaki butona tıklayın ↓', w / 2, h / 2 + 30, 12, Colors.white54);
    }

    // Game over overlay
    if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black54);
      _text(canvas, '⚽ Oyun Bitti!', w / 2, h / 2 - 40, 26, Colors.white);
      _text(canvas, '$score sektirme', w / 2, h / 2, 20, Colors.orange.shade300);
      _text(canvas, 'En iyi combo: $bestCombo', w / 2, h / 2 + 25, 14, Colors.white70);
      if (score >= bestScore && score > 0) {
        _text(canvas, '🎉 Yeni Rekor!', w / 2, h / 2 + 50, 16, Colors.yellow.shade300);
      }
    }
  }

  void _drawPentagon(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final x = cx + cos(a) * r;
      final y = cy + sin(a) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCloud(Canvas canvas, double x, double y, double r) {
    final p = Paint()..color = Colors.white.withAlpha(200);
    canvas.drawCircle(Offset(x, y), r, p);
    canvas.drawCircle(Offset(x - r * 0.8, y + 2), r * 0.7, p);
    canvas.drawCircle(Offset(x + r * 0.8, y + 2), r * 0.7, p);
    canvas.drawCircle(Offset(x - r * 0.4, y - r * 0.4), r * 0.6, p);
    canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.3), r * 0.5, p);
  }

  void _text(Canvas canvas, String text, double x, double y, double s, Color c) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: c, fontSize: s, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _JugglingPainter old) => true;
}
