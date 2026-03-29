import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum Difficulty { easy, normal, hard }
enum GamePhase { difficultyPick, placement, playing, gameOver }

class MiniFootballGameScreen extends StatefulWidget {
  const MiniFootballGameScreen({super.key});

  @override
  State<MiniFootballGameScreen> createState() => _MiniFootballGameScreenState();
}

class _MiniFootballGameScreenState extends State<MiniFootballGameScreen> {
  double ballX = 0.5, ballY = 0.5;
  double ballDx = 0, ballDy = 0;
  double playerX = 0.5, cpuX = 0.5;
  int playerScore = 0, cpuScore = 0;
  Timer? gameTimer;
  Difficulty difficulty = Difficulty.normal;
  GamePhase phase = GamePhase.difficultyPick;
  int goalFlashFrames = 0;
  String goalText = '';

  // CPU patrol state
  double _cpuDir = 1;
  double _cpuPatrolSpeed = 0.006;

  // Boost mechanic
  bool _boosting = false;
  int _boostCooldown = 0;
  static const int _boostMax = 120;

  // Player placement: 3 players on each half
  // playerPieces[i] = Offset(x, y) in 0..1 coords
  List<Offset> playerPieces = []; // user's 3 pieces (bottom half: y 0.5-0.9)
  List<Offset> cpuPieces = [];    // cpu's 3 pieces (top half: y 0.1-0.5)
  // Roles: first 2 = defense (slow ball), last 1 = forward (speed ball)
  int? _draggingPieceIndex;

  // Difficulty settings
  double get cpuBaseSpeed => switch (difficulty) { Difficulty.easy => 0.004, Difficulty.normal => 0.006, Difficulty.hard => 0.009 };
  double get ballSpeed => switch (difficulty) { Difficulty.easy => 0.008, Difficulty.normal => 0.012, Difficulty.hard => 0.016 };
  double get goalWidth => switch (difficulty) { Difficulty.easy => 0.40, Difficulty.normal => 0.35, Difficulty.hard => 0.30 };
  double get paddleW => switch (difficulty) { Difficulty.easy => 0.26, Difficulty.normal => 0.22, Difficulty.hard => 0.18 };
  int get maxScore => 5;

  static const double paddleH = 0.020;
  static const double ballR = 0.018;
  static const double pieceR = 0.025;

  void _selectDifficulty(Difficulty d) {
    setState(() {
      difficulty = d;
      _cpuPatrolSpeed = cpuBaseSpeed;
      phase = GamePhase.placement;
      // Default player pieces in bottom half
      playerPieces = [
        const Offset(0.3, 0.72),  // left defense
        const Offset(0.7, 0.72),  // right defense
        const Offset(0.5, 0.60),  // forward
      ];
      // Random CPU pieces in top half
      final rng = Random();
      cpuPieces = [
        Offset(0.2 + rng.nextDouble() * 0.6, 0.15 + rng.nextDouble() * 0.15),
        Offset(0.2 + rng.nextDouble() * 0.6, 0.15 + rng.nextDouble() * 0.15),
        Offset(0.2 + rng.nextDouble() * 0.6, 0.30 + rng.nextDouble() * 0.10),
      ];
    });
  }

  void _startGame() {
    setState(() { phase = GamePhase.playing; playerScore = 0; cpuScore = 0; goalFlashFrames = 0; _boostCooldown = 0; });
    _resetBall();
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
  }

  void _resetBall() {
    final rng = Random();
    ballX = 0.5; ballY = 0.5;
    ballDx = (rng.nextBool() ? 1 : -1) * (ballSpeed * 0.6 + rng.nextDouble() * ballSpeed * 0.4);
    ballDy = (rng.nextBool() ? 1 : -1) * (ballSpeed * 0.8 + rng.nextDouble() * ballSpeed * 0.3);
  }

  void _activateBoost() {
    if (_boostCooldown > 0 || phase != GamePhase.playing) return;
    setState(() { _boosting = true; _boostCooldown = _boostMax; });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _boosting = false);
    });
  }

  void _update() {
    if (phase != GamePhase.playing) return;
    setState(() {
      if (goalFlashFrames > 0) { goalFlashFrames--; if (goalFlashFrames == 0) _resetBall(); return; }
      if (_boostCooldown > 0) _boostCooldown--;

      double speedMult = _boosting ? 2.5 : 1.0;
      ballX += ballDx * speedMult;
      ballY += ballDy * speedMult;

      if (_boosting) {
        ballDx += (Random().nextDouble() - 0.5) * 0.003;
      }

      // Wall bounce
      if (ballX <= ballR) { ballDx = ballDx.abs(); ballX = ballR; }
      if (ballX >= 1.0 - ballR) { ballDx = -ballDx.abs(); ballX = 1.0 - ballR; }

      // CPU patrol
      cpuX += _cpuDir * _cpuPatrolSpeed;
      if (cpuX >= 1.0 - paddleW / 2) { cpuX = 1.0 - paddleW / 2; _cpuDir = -1; }
      if (cpuX <= paddleW / 2) { cpuX = paddleW / 2; _cpuDir = 1; }
      if (Random().nextInt(200) == 0) _cpuDir = -_cpuDir;

      // Player paddle collision (bottom)
      if (ballY >= 0.92 - ballR && ballY <= 0.94 && ballDy > 0) {
        if ((ballX - playerX).abs() < paddleW / 2 + ballR) {
          ballDy = -ballDy.abs();
          double hitOff = (ballX - playerX) / (paddleW / 2);
          ballDx += hitOff * 0.006;
          ballDx = ballDx.clamp(-0.025, 0.025);
          if (ballDy.abs() < 0.025) ballDy *= 1.03;
        }
      }

      // CPU paddle collision (top)
      if (ballY <= 0.08 + ballR && ballY >= 0.06 && ballDy < 0) {
        if ((ballX - cpuX).abs() < paddleW / 2 + ballR) {
          ballDy = ballDy.abs();
          double hitOff = (ballX - cpuX) / (paddleW / 2);
          ballDx += hitOff * 0.006;
          ballDx = ballDx.clamp(-0.025, 0.025);
          if (ballDy.abs() < 0.025) ballDy *= 1.03;
        }
      }

      // Ball collision with player pieces (defense: slow, forward: boost)
      for (int i = 0; i < playerPieces.length; i++) {
        final p = playerPieces[i];
        final dist = sqrt(pow(ballX - p.dx, 2) + pow(ballY - p.dy, 2));
        if (dist < pieceR + ballR) {
          // Deflect
          final angle = atan2(ballY - p.dy, ballX - p.dx);
          if (i < 2) {
            // Defense: slow ball down
            ballDx = cos(angle) * ballSpeed * 0.5;
            ballDy = sin(angle) * ballSpeed * 0.5;
          } else {
            // Forward: boost ball
            ballDx = cos(angle) * ballSpeed * 2.0;
            ballDy = sin(angle) * ballSpeed * 2.0;
          }
          // Push ball out of piece
          ballX = p.dx + cos(angle) * (pieceR + ballR + 0.005);
          ballY = p.dy + sin(angle) * (pieceR + ballR + 0.005);
        }
      }

      // Ball collision with CPU pieces
      for (int i = 0; i < cpuPieces.length; i++) {
        final p = cpuPieces[i];
        final dist = sqrt(pow(ballX - p.dx, 2) + pow(ballY - p.dy, 2));
        if (dist < pieceR + ballR) {
          final angle = atan2(ballY - p.dy, ballX - p.dx);
          if (i < 2) {
            ballDx = cos(angle) * ballSpeed * 0.5;
            ballDy = sin(angle) * ballSpeed * 0.5;
          } else {
            ballDx = cos(angle) * ballSpeed * 2.0;
            ballDy = sin(angle) * ballSpeed * 2.0;
          }
          ballX = p.dx + cos(angle) * (pieceR + ballR + 0.005);
          ballY = p.dy + sin(angle) * (pieceR + ballR + 0.005);
        }
      }

      // Top goal
      if (ballY <= 0.005) {
        double gL = 0.5 - goalWidth / 2, gR = 0.5 + goalWidth / 2;
        if (ballX >= gL && ballX <= gR) {
          playerScore++; goalText = 'GOL! ⚽'; goalFlashFrames = 40;
          if (playerScore >= maxScore) { phase = GamePhase.gameOver; gameTimer?.cancel(); }
        } else { ballDy = ballDy.abs(); }
      }
      if (ballY >= 0.995) {
        double gL = 0.5 - goalWidth / 2, gR = 0.5 + goalWidth / 2;
        if (ballX >= gL && ballX <= gR) {
          cpuScore++; goalText = 'GOL! 😢'; goalFlashFrames = 40;
          if (cpuScore >= maxScore) { phase = GamePhase.gameOver; gameTimer?.cancel(); }
        } else { ballDy = -ballDy.abs(); }
      }
    });
  }

  @override
  void dispose() { gameTimer?.cancel(); super.dispose(); }

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
                const Expanded(child: Text('Mini Futbol ⚽', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold))),
                if (phase == GamePhase.playing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _diffColor().withAlpha(30), borderRadius: BorderRadius.circular(6)),
                    child: Text(_diffLabel(), style: TextStyle(color: _diffColor(), fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else const SizedBox(width: 48),
              ]),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: AppDecorations.cardBox(),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _scoreCol('Rakip', cpuScore, AppColors.categoryRed),
                Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
                _scoreCol('Sen', playerScore, AppColors.primaryBlue),
              ]),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final fw = constraints.maxWidth - 20;
                final fh = constraints.maxHeight - 4;

                if (phase == GamePhase.placement) {
                  return _buildPlacementField(fw, fh);
                }

                return GestureDetector(
                  onPanUpdate: (d) { setState(() { playerX = (d.localPosition.dx / (fw + 20)).clamp(paddleW / 2, 1.0 - paddleW / 2); }); },
                  onTapDown: (d) { setState(() { playerX = (d.localPosition.dx / (fw + 20)).clamp(paddleW / 2, 1.0 - paddleW / 2); }); },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24, width: 2)),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(fw, fh),
                        painter: _GamePainter(
                          ballX: ballX, ballY: ballY, ballR: ballR,
                          playerX: playerX, cpuX: cpuX,
                          paddleW: paddleW, paddleH: paddleH,
                          goalWidth: goalWidth,
                          goalFlash: goalFlashFrames > 0, goalText: goalText,
                          paused: phase == GamePhase.difficultyPick,
                          gameOver: phase == GamePhase.gameOver,
                          playerScore: playerScore, cpuScore: cpuScore, maxScore: maxScore,
                          boosting: _boosting,
                          playerPieces: playerPieces,
                          cpuPieces: cpuPieces,
                          pieceR: pieceR,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            if (phase == GamePhase.difficultyPick)
              _buildDifficultyPicker()
            else if (phase == GamePhase.placement)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🎯 Oyuncularını sahaya yerleştir!', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('🛡️ Mavi = Defans (yavaşlatır)   ⚡ Turuncu = Forvet (fırlatır)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
                    child: const Text('▶ Oyuna Başla', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]),
              )
            else if (phase == GamePhase.gameOver)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  Expanded(child: ElevatedButton(onPressed: () => setState(() => phase = GamePhase.difficultyPick), style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgSurface, foregroundColor: AppColors.textPrimary), child: const Text('Zorluk'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: () => _selectDifficulty(difficulty), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white), child: const Text('Tekrar Oyna'))),
                ]),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  Expanded(child: Text('⬅️ Sürükle ➡️', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _activateBoost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _boostCooldown > 0 ? AppColors.bgSurface : AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.bolt, color: _boostCooldown > 0 ? AppColors.textSecondary : Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(_boostCooldown > 0 ? '${(_boostCooldown / 60).ceil()}s' : 'BOOST', style: TextStyle(color: _boostCooldown > 0 ? AppColors.textSecondary : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementField(double fw, double fh) {
    return GestureDetector(
      onPanStart: (d) {
        final localX = d.localPosition.dx / (fw + 20);
        final localY = d.localPosition.dy / fh;
        // Find closest player piece to drag
        double minDist = double.infinity;
        int? closest;
        for (int i = 0; i < playerPieces.length; i++) {
          final dx = playerPieces[i].dx - localX;
          final dy = playerPieces[i].dy - localY;
          final dist = dx * dx + dy * dy;
          if (dist < minDist && dist < 0.01) { minDist = dist; closest = i; }
        }
        _draggingPieceIndex = closest;
      },
      onPanUpdate: (d) {
        if (_draggingPieceIndex == null) return;
        final localX = (d.localPosition.dx / (fw + 20)).clamp(0.05, 0.95);
        final localY = (d.localPosition.dy / fh).clamp(0.50, 0.88); // Only bottom half
        setState(() {
          playerPieces[_draggingPieceIndex!] = Offset(localX, localY);
        });
      },
      onPanEnd: (_) => _draggingPieceIndex = null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24, width: 2)),
        child: CustomPaint(
          size: Size(fw, fh),
          painter: _PlacementPainter(
            playerPieces: playerPieces,
            cpuPieces: cpuPieces,
            pieceR: pieceR,
            goalWidth: goalWidth,
            paddleW: paddleW,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyPicker() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Zorluk Seçin', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(children: [
        _diffBtn('Kolay', Difficulty.easy, AppColors.correct),
        const SizedBox(width: 8),
        _diffBtn('Normal', Difficulty.normal, AppColors.primaryOrange),
        const SizedBox(width: 8),
        _diffBtn('Zor', Difficulty.hard, AppColors.categoryRed),
      ]),
    ]),
  );

  Widget _diffBtn(String label, Difficulty d, Color c) => Expanded(
    child: GestureDetector(
      onTap: () => _selectDifficulty(d),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: c.withAlpha(80), blurRadius: 6, offset: const Offset(0, 3))]),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
      ),
    ),
  );

  Widget _scoreCol(String label, int score, Color c) => Column(children: [
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
    const SizedBox(height: 2),
    Text('$score', style: TextStyle(color: c, fontSize: 26, fontWeight: FontWeight.bold)),
  ]);

  Color _diffColor() => switch (difficulty) { Difficulty.easy => AppColors.correct, Difficulty.normal => AppColors.primaryOrange, Difficulty.hard => AppColors.categoryRed };
  String _diffLabel() => switch (difficulty) { Difficulty.easy => 'KOLAY', Difficulty.normal => 'NORMAL', Difficulty.hard => 'ZOR' };
}

// Placement phase painter
class _PlacementPainter extends CustomPainter {
  final List<Offset> playerPieces, cpuPieces;
  final double pieceR, goalWidth, paddleW;

  _PlacementPainter({required this.playerPieces, required this.cpuPieces, required this.pieceR, required this.goalWidth, required this.paddleW});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Stripes
    for (int i = 0; i < 10; i += 2) canvas.drawRect(Rect.fromLTWH(0, h * i / 10, w, h / 10), Paint()..color = const Color(0xFF2E7D32));

    // Markings
    final lp = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), lp);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.1, lp);
    canvas.drawRect(Rect.fromLTWH(w * 0.2, 0, w * 0.6, h * 0.15), lp);
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.85, w * 0.6, h * 0.15), lp);

    // Half-line zone indicator
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.4), Paint()..color = Colors.blue.withAlpha(15));
    _text(canvas, 'Senin yarı sahan', w / 2, h * 0.48, 10, Colors.white38);

    // CPU pieces (red, semi-transparent)
    for (int i = 0; i < cpuPieces.length; i++) {
      final p = cpuPieces[i];
      final px = p.dx * w, py = p.dy * h;
      final isForward = i == 2;
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = (isForward ? Colors.orange : Colors.red).withAlpha(150));
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _text(canvas, isForward ? '⚡' : '🛡️', px, py, 10, Colors.white);
    }

    // Player pieces (blue, draggable)
    for (int i = 0; i < playerPieces.length; i++) {
      final p = playerPieces[i];
      final px = p.dx * w, py = p.dy * h;
      final isForward = i == 2;
      canvas.drawCircle(Offset(px, py), pieceR * w + 2, Paint()..color = Colors.white.withAlpha(40));
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = isForward ? Colors.orange.shade600 : Colors.blue.shade600);
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      _text(canvas, isForward ? '⚡' : '🛡️', px, py, 12, Colors.white);
    }

    // Instructions
    _text(canvas, '↕ Oyuncuları sürükleyerek yerleştir', w / 2, h * 0.95, 11, Colors.white60);
  }

  void _text(Canvas canvas, String text, double x, double y, double s, Color c) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: c, fontSize: s, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// Game painter (with pieces on field)
class _GamePainter extends CustomPainter {
  final double ballX, ballY, ballR, playerX, cpuX, paddleW, paddleH, goalWidth, pieceR;
  final int playerScore, cpuScore, maxScore;
  final bool goalFlash, paused, gameOver, boosting;
  final String goalText;
  final List<Offset> playerPieces, cpuPieces;

  _GamePainter({
    required this.ballX, required this.ballY, required this.ballR,
    required this.playerX, required this.cpuX,
    required this.paddleW, required this.paddleH, required this.goalWidth,
    required this.playerScore, required this.cpuScore,
    required this.goalFlash, required this.goalText,
    required this.paused, required this.gameOver, required this.maxScore,
    required this.boosting,
    required this.playerPieces, required this.cpuPieces, required this.pieceR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Stripes
    final s1 = Paint()..color = const Color(0xFF2E7D32);
    for (int i = 0; i < 10; i += 2) canvas.drawRect(Rect.fromLTWH(0, h * i / 10, w, h / 10), s1);

    // Markings
    final lp = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), lp);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.1, lp);
    canvas.drawRect(Rect.fromLTWH(w * 0.2, 0, w * 0.6, h * 0.15), lp);
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.85, w * 0.6, h * 0.15), lp);

    // Goals
    final goalL = w * (0.5 - goalWidth / 2);
    canvas.drawRect(Rect.fromLTWH(goalL, 0, w * goalWidth, 4), Paint()..color = Colors.red.shade400);
    canvas.drawRect(Rect.fromLTWH(goalL, h - 4, w * goalWidth, 4), Paint()..color = Colors.blue.shade400);

    // Draw field pieces
    for (int i = 0; i < cpuPieces.length; i++) {
      final p = cpuPieces[i];
      final px = p.dx * w, py = p.dy * h;
      final isForward = i == 2;
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = (isForward ? Colors.orange : Colors.red).withAlpha(120));
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = Colors.white38..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    for (int i = 0; i < playerPieces.length; i++) {
      final p = playerPieces[i];
      final px = p.dx * w, py = p.dy * h;
      final isForward = i == 2;
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = (isForward ? Colors.orange : Colors.blue).withAlpha(140));
      canvas.drawCircle(Offset(px, py), pieceR * w, Paint()..color = Colors.white38..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // CPU Paddle
    _drawPaddle(canvas, cpuX * w, h * 0.07, paddleW * w, paddleH * h, Colors.red.shade400);
    // Player Paddle
    _drawPaddle(canvas, playerX * w, h * 0.93 - paddleH * h, paddleW * w, paddleH * h, Colors.blue.shade400);

    // Ball
    if (!goalFlash) {
      final bx = ballX * w, by = ballY * h;
      canvas.drawCircle(Offset(bx + 1, by + 2), ballR * w, Paint()..color = Colors.black26);
      canvas.drawCircle(Offset(bx, by), ballR * w, Paint()..color = Colors.white);
      if (boosting) {
        canvas.drawCircle(Offset(bx, by), ballR * w + 3, Paint()..color = Colors.orange.withAlpha(80)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }

    if (goalFlash) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withAlpha(40));
      _text(canvas, goalText, w / 2, h / 2, 28, Colors.white);
    }

    if (paused && !gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black54);
      _text(canvas, '⚽ Mini Futbol', w / 2, h / 2 - 20, 24, Colors.white);
      _text(canvas, 'Zorluk seçin ↓', w / 2, h / 2 + 12, 14, Colors.white70);
    }

    if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black54);
      final won = playerScore >= maxScore;
      _text(canvas, won ? '🎉 Kazandın!' : '😢 Kaybettin', w / 2, h / 2 - 20, 24, Colors.white);
      _text(canvas, '$playerScore - $cpuScore', w / 2, h / 2 + 12, 20, Colors.white70);
    }
  }

  void _drawPaddle(Canvas canvas, double cx, double cy, double pw, double ph, Color c) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + ph / 2), width: pw, height: ph), const Radius.circular(4)), Paint()..color = c);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + ph / 2), width: pw, height: ph), const Radius.circular(4)), Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _text(Canvas canvas, String text, double x, double y, double s, Color c) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: c, fontSize: s, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
