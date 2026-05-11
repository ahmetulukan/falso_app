import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Ball Bounce Blitz - Oyuncu paddle ile topu yukarı sektirir
/// Düşman topları kaçınır, power-up'lar toplar
class BallBounceBlitzScreen extends StatefulWidget {
  const BallBounceBlitzScreen({super.key});

  @override
  State<BallBounceBlitzScreen> createState() => _BallBounceBlitzScreenState();
}

class _BallBounceBlitzScreenState extends State<BallBounceBlitzScreen>
    with TickerProviderStateMixin {
  // --- Game State ---
  bool _playing = false;
  bool _gameOver = false;
  bool _paused = false;
  int _score = 0;
  int _bestScore = 0;
  int _level = 1;
  int _lives = 3;
  Timer? _timer;
  int _frameCount = 0;

  // --- Paddle ---
  double _paddleX = 0.5;
  static const double _paddleW = 0.22;
  static const double _paddleY = 0.88;
  double _paddleTargetX = 0.5;

  // --- Player Ball ---
  double _ballX = 0.5, _ballY = 0.5;
  double _ballVx = 0, _ballVy = 0;
  static const double _ballR = 0.03;
  static const double _kickVy = -0.025;
  static const double _maxVx = 0.008;
  double _ballRotation = 0;

  // --- Enemy Balls ---
  List<_EnemyBall> _enemyBalls = [];
  int _nextEnemySpawn = 120;

  // --- Power-ups ---
  List<_PowerUp> _powerUps = [];
  int _nextPowerUpSpawn = 300;
  String? _activePowerUp;
  int _powerUpTimer = 0;

  // --- Particles ---
  List<_Particle> _particles = [];

  // --- Touch ---
  Offset? _lastTouch;

  void _start() {
    _paddleX = 0.5;
    _paddleTargetX = 0.5;
    _ballX = 0.5;
    _ballY = 0.55;
    _ballVx = (Random().nextDouble() - 0.5) * 0.004;
    _ballVy = -0.012;
    _score = 0;
    _level = 1;
    _lives = 3;
    _activePowerUp = null;
    _powerUpTimer = 0;
    _enemyBalls = [];
    _powerUps = [];
    _particles = [];
    _frameCount = 0;
    _nextEnemySpawn = 120;
    _nextPowerUpSpawn = 300;
    _lastTouch = null;
    setState(() => _playing = true; _gameOver = false; _paused = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
  }

  void _update() {
    if (!_playing || _paused) return;
    _frameCount++;
    setState(() {
      // Move paddle smoothly
      _paddleX += (_paddleTargetX - _paddleX) * 0.18;

      // Ball physics
      _ballVy += 0.00025; // gravity
      _ballVx *= 0.998;
      _ballX += _ballVx;
      _ballY += _ballVy;
      _ballRotation += _ballVx * 6;

      // Wall bounce (sides)
      if (_ballX < _ballR) { _ballX = _ballR; _ballVx = _ballVx.abs(); }
      if (_ballX > 1 - _ballR) { _ballX = 1 - _ballR; _ballVx = -_ballVx.abs(); }

      // Ceiling bounce
      if (_ballY < _ballR) { _ballY = _ballR; _ballVy = _ballVy.abs(); }

      // Paddle collision
      if (_ballVy > 0 &&
          _ballY + _ballR > _paddleY - 0.02 &&
          _ballY - _ballR < _paddleY + 0.02 &&
          _ballX > _paddleX - _paddleW / 2 &&
          _ballX < _paddleX + _paddleW / 2) {
        _ballY = _paddleY - _ballR - 0.001;
        _ballVy = _kickVy - (_level * 0.0005);
        _ballVx += (_ballX - _paddleX) * 0.04;
        _ballVx = _ballVx.clamp(-_maxVx * 1.5, _maxVx * 1.5);
        _score++;
        if (_score % 15 == 0) _level++;
        _spawnKickParticles(_ballX, _paddleY - 0.02);
        HapticFeedback.lightImpact();
      }

      // Ball fell — lose life
      if (_ballY > 1.1) {
        _lives--;
        if (_lives <= 0) {
          _endGame();
        } else {
          _ballX = _paddleX;
          _ballY = _paddleY - 0.1;
          _ballVx = 0;
          _ballVy = -0.015;
          _spawnExplosion(_ballX, 0.95, Colors.red, 12);
        }
        return;
      }

      // --- Enemy Balls ---
      _nextEnemySpawn--;
      if (_nextEnemySpawn <= 0) {
        final side = Random().nextBool();
        _enemyBalls.add(_EnemyBall(
          x: side ? Random().nextDouble() : Random().nextDouble(),
          y: -0.06,
          vx: (Random().nextDouble() - 0.5) * 0.005,
          vy: 0.007 + _level * 0.001,
          r: 0.035,
          colorIdx: Random().nextInt(3),
        ));
        _nextEnemySpawn = max(80, 200 - _level * 15);
      }
      for (int i = _enemyBalls.length - 1; i >= 0; i--) {
        final e = _enemyBalls[i];
        e.x += e.vx;
        e.y += e.vy;
        e.angle = (e.angle ?? 0) + e.vx * 4;
        // Wall bounce
        if (e.x < e.r) { e.x = e.r; e.vx = e.vx.abs(); }
        if (e.x > 1 - e.r) { e.x = 1 - e.r; e.vx = -e.vx.abs(); }
        // Remove if off screen
        if (e.y > 1.2) { _enemyBalls.removeAt(i); continue; }
        // Collision with paddle
        if (e.y + e.r > _paddleY - 0.02 &&
            e.y < _paddleY + 0.02 &&
            e.x > _paddleX - _paddleW / 2 &&
            e.x < _paddleX + _paddleW / 2) {
          _enemyBalls.removeAt(i);
          _lives--;
          _spawnExplosion(e.x, _paddleY, Colors.red, 8);
          if (_lives <= 0) { _endGame(); return; }
          continue;
        }
        // Collision with player ball
        final dx = _ballX - e.x, dy = _ballY - e.y;
        if (sqrt(dx * dx + dy * dy) < _ballR + e.r) {
          _enemyBalls.removeAt(i);
          _lives--;
          _spawnExplosion(e.x, e.y, Colors.orange, 8);
          if (_lives <= 0) { _endGame(); return; }
        }
      }

      // --- Power-ups ---
      _nextPowerUpSpawn--;
      if (_nextPowerUpSpawn <= 0) {
        _powerUps.add(_PowerUp(
          x: 0.1 + Random().nextDouble() * 0.8,
          y: -0.04,
          type: Random().nextBool() ? 'life' : 'multi',
        ));
        _nextPowerUpSpawn = 400 + Random().nextInt(200);
      }
      for (int i = _powerUps.length - 1; i >= 0; i--) {
        final p = _powerUps[i];
        p.y += 0.004;
        if (p.y > 1.1) { _powerUps.removeAt(i); continue; }
        // Collect by ball
        final dx = _ballX - p.x, dy = _ballY - p.y;
        if (sqrt(dx * dx + dy * dy) < _ballR + 0.04) {
          _powerUps.removeAt(i);
          _score += 5;
          if (p.type == 'life') { _lives = min(_lives + 1, 5); }
          else { _activePowerUp = 'multi'; _powerUpTimer = 180; }
          _spawnKickParticles(p.x, p.y, color: Colors.cyan);
        }
      }

      // Power-up timer
      if (_activePowerUp != null) {
        _powerUpTimer--;
        if (_powerUpTimer <= 0) _activePowerUp = null;
      }

      // Particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.0002;
        p.life--;
        if (p.life <= 0) _particles.removeAt(i);
      }
    });
  }

  void _endGame() {
    _playing = false;
    _gameOver = true;
    _timer?.cancel();
    if (_score > _bestScore) _bestScore = _score;
    HapticFeedback.heavyImpact();
  }

  void _spawnKickParticles(double x, double y, {Color color = Colors.yellow}) {
    final rng = Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(_Particle(
        x: x, y: y,
        vx: (rng.nextDouble() - 0.5) * 0.012,
        vy: -rng.nextDouble() * 0.012,
        life: 20 + rng.nextInt(15),
        color: color,
        r: 0.008 + rng.nextDouble() * 0.008,
      ));
    }
  }

  void _spawnExplosion(double x, double y, Color color, int count) {
    final rng = Random();
    for (int i = 0; i < count; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final spd = 0.005 + rng.nextDouble() * 0.01;
      _particles.add(_Particle(
        x: x, y: y,
        vx: cos(a) * spd,
        vy: sin(a) * spd,
        life: 25 + rng.nextInt(20),
        color: color,
        r: 0.01 + rng.nextDouble() * 0.01,
      ));
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!_playing) return;
    setState(() {
      _paddleTargetX = (details.localPosition.dx / size.width).clamp(_paddleW / 2, 1 - _paddleW / 2);
    });
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('⚡ Ball Bounce Blitz',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ]),
            ),

            // HUD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: AppDecorations.cardBox(),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _hudItem('❤️', '$_lives', AppColors.correct),
                _hudItem('⚡', '$_score', AppColors.primaryBlue),
                _hudItem('🏆', '$_bestScore', AppColors.primaryOrange),
                _hudItem('🎯', 'Lv $_level', Colors.purpleAccent),
              ]),
            ),

            // Power-up indicator
            if (_activePowerUp != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.withAlpha(100)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔮 MULTI-BALL ', style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('${(_powerUpTimer / 60).ceil()}s', style: const TextStyle(color: Colors.cyan, fontSize: 11)),
                ]),
              ),

            const SizedBox(height: 4),

            // Game Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth - 16, constraints.maxHeight);
                  return GestureDetector(
                    onPanUpdate: (d) => _onPanUpdate(d, size),
                    onTapDown: (d) {
                      if (!_playing) return;
                      final tx = d.localPosition.dx / size.width;
                      final ty = d.localPosition.dy / size.height;
                      final dx = _ballX - tx, dy = _ballY - ty;
                      if (sqrt(dx * dx + dy * dy) < 0.12) {
                        setState(() {
                          _ballVy = _kickVy * 0.7;
                          _ballVx += dx * 0.02;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CustomPaint(
                          size: size,
                          painter: _BlitzPainter(
                            paddleX: _paddleX, paddleY: _paddleY, paddleW: _paddleW,
                            ballX: _ballX, ballY: _ballY, ballR: _ballR,
                            ballVx: _ballVx, ballVy: _ballVy, ballRotation: _ballRotation,
                            enemyBalls: _enemyBalls,
                            powerUps: _powerUps,
                            particles: _particles,
                            score: _score, bestScore: _bestScore, level: _level, lives: _lives,
                            playing: _playing, gameOver: _gameOver,
                            activePowerUp: _activePowerUp,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),

            // Bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: !_playing
                ? ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: Text(_gameOver ? '🔄 Tekrar Oyna' : '▶ Başla',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('💡 Paddle\'ı sürükle | Topa tıkla = ekstra güç',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudItem(String icon, String val, Color color) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ---- Classes ----
class _EnemyBall {
  double x, y, vx, vy, r, angle;
  int colorIdx;
  _EnemyBall({required this.x, required this.y, required this.vx, required this.vy,
    required this.r, this.angle = 0, this.colorIdx = 0});
}

class _PowerUp {
  double x, y;
  String type;
  _PowerUp({required this.x, required this.y, required this.type});
}

class _Particle {
  double x, y, vx, vy, r;
  int life;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy,
    required this.life, required this.color, required this.r});
}

// ---- Painter ----
class _BlitzPainter extends CustomPainter {
  final double paddleX, paddleY, paddleW;
  final double ballX, ballY, ballR, ballVx, ballVy, ballRotation;
  final List<_EnemyBall> enemyBalls;
  final List<_PowerUp> powerUps;
  final List<_Particle> particles;
  final int score, bestScore, level, lives;
  final bool playing, gameOver;
  final String? activePowerUp;

  _BlitzPainter({
    required this.paddleX, required this.paddleY, required this.paddleW,
    required this.ballX, required this.ballY, required this.ballR,
    required this.ballVx, required this.ballVy, required this.ballRotation,
    required this.enemyBalls, required this.powerUps, required this.particles,
    required this.score, required this.bestScore, required this.level, required this.lives,
    required this.playing, required this.gameOver,
    this.activePowerUp,
  });

  static const _enemyColors = [
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFFFF6B6B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Background stars
    final starPaint = Paint()..color = Colors.white.withAlpha(60);
    final rng = Random(99);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.75),
        1 + rng.nextDouble(),
        starPaint,
      );
    }

    // Grid lines
    final gridPaint = Paint()..color = Colors.white.withAlpha(8)..strokeWidth = 0.5;
    for (int i = 1; i < 8; i++) {
      canvas.drawLine(Offset(w * i / 8, 0), Offset(w * i / 8, h), gridPaint);
    }
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(Offset(0, h * i / 6), Offset(w, h * i / 6), gridPaint);
    }

    // Particles
    for (final p in particles) {
      final alpha = (p.life * 12).clamp(0, 255);
      canvas.drawCircle(
        Offset(p.x * w, p.y * h),
        p.r * w,
        Paint()..color = p.color.withAlpha(alpha),
      );
    }

    // Power-ups
    for (final p in powerUps) {
      final px = p.x * w, py = p.y * h;
      canvas.drawCircle(Offset(px, py), 18, Paint()..color = (p.type == 'life' ? Colors.red : Colors.cyan).withAlpha(50));
      canvas.drawCircle(Offset(px, py), 14, Paint()..color = p.type == 'life' ? Colors.red.shade300 : Colors.cyan);
      final text = p.type == 'life' ? '❤' : '⚡';
      final tp = TextPainter(text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }

    // Enemy balls
    for (final e in enemyBalls) {
      final ex = e.x * w, ey = e.y * h, er = e.r * w;
      final color = _enemyColors[e.colorIdx % _enemyColors.length];
      canvas.drawCircle(Offset(ex + 2, ey + 2), er, Paint()..color = Colors.black.withAlpha(40));
      canvas.drawCircle(Offset(ex, ey), er, Paint()..color = color);
      canvas.drawCircle(Offset(ex, ey), er, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
      // Angry face
      canvas.save();
      canvas.translate(ex, ey);
      final facePaint = Paint()..color = Colors.white..strokeWidth = 2..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(-er * 0.3, -er * 0.1), Offset(-er * 0.1, er * 0.1), facePaint);
      canvas.drawLine(Offset(er * 0.3, -er * 0.1), Offset(er * 0.1, er * 0.1), facePaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(0, er * 0.3), width: er * 0.6, height: er * 0.3),
        pi, pi, false, facePaint);
      canvas.restore();
    }

    // Player ball
    if (playing || gameOver) {
      final bx = ballX * w, by = ballY * h, br = ballR * w;
      // Glow
      canvas.drawCircle(Offset(bx, by), br * 1.6, Paint()..color = AppColors.primaryBlue.withAlpha(40));
      // Ball
      canvas.drawCircle(Offset(bx + 1, by + 1), br, Paint()..color = Colors.black.withAlpha(30));
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
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
      // Shine
      canvas.drawCircle(Offset(bx - br * 0.3, by - br * 0.3), br * 0.2, Paint()..color = Colors.white.withAlpha(150));
    }

    // Paddle
    final pw = paddleW * w, ph = 14.0;
    final px = paddleX * w - pw / 2, py = paddleY * h - ph / 2;
    final paddleGrad = LinearGradient(
      colors: [AppColors.primaryBlue, const Color(0xFF2980B9)],
    ).createShader(Rect.fromLTWH(px, py, pw, ph));
    final paddleRect = RRect.fromRectAndRadius(Rect.fromLTWH(px, py, pw, ph), const Radius.circular(8));
    canvas.drawRRect(paddleRect, Paint()..shader = paddleGrad);
    canvas.drawRRect(paddleRect, Paint()..color = Colors.white.withAlpha(60)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Paddle shine
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px + 4, py + 2, pw * 0.4, 4), const Radius.circular(2)),
      Paint()..color = Colors.white.withAlpha(80));

    // Score popup effect
    if (score > 0 && playing) {
      final scoreText = '+$score';
      _text(canvas, scoreText, w * 0.85, h * 0.08, 14 + min(score.toDouble(), 8) * 0.3,
        score > 20 ? Colors.orange : score > 10 ? Colors.yellow : Colors.white70);
    }

    // Overlay: Start
    if (!playing && !gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black45);
      _text(canvas, '⚡ Ball Bounce Blitz', w / 2, h * 0.35, 24, Colors.white);
      _text(canvas, 'Paddle\'ı sürekle, düşmanlardan kaçın', w / 2, h * 0.48, 13, Colors.white70);
      _text(canvas, 'Power-up\'ları topla!', w / 2, h * 0.56, 13, Colors.cyan);
      _text(canvas, 'Başlamak için ▶ butonuna tıkla', w / 2, h * 0.68, 12, Colors.white54);
    }

    // Overlay: Game Over
    if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black60);
      _text(canvas, '💥 Oyun Bitti!', w / 2, h * 0.32, 28, Colors.red.shade300);
      _text(canvas, 'Skor: $score  |  Seviye: $level', w / 2, h * 0.45, 16, Colors.white);
      _text(canvas, 'En İyi: $bestScore', w / 2, h * 0.54, 14, AppColors.primaryOrange);
      if (score >= bestScore && score > 0) {
        _text(canvas, '🎉 Yeni Rekor!', w / 2, h * 0.64, 18, Colors.yellow.shade300);
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

  void _text(Canvas canvas, String text, double x, double y, double s, Color c) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: c, fontSize: s, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BlitzPainter old) => true;
}
