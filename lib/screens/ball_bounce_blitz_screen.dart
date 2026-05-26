import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Ball Bounce Blitz - Wave & Boss Edition
/// Wave system, Boss balls, Fireball power-up, Twinkling stars, Floating score text
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
  int _wave = 1;
  int _waveTimer = 0;
  int _bossWave = 5;
  bool _bossActive = false;
  int _bossHp = 0;
  bool _bossFlash = false;
  Timer? _timer;

  // --- Achievements ---
  final Set<String> _achievements = {};

  // --- Paddle ---
  double _paddleX = 0.5;
  static const double _paddleW = 0.22;
  static const double _paddleY = 0.88;
  double _paddleTargetX = 0.5;

  // --- Player Balls ---
  List<_PlayerBall> _playerBalls = [];

  // --- Enemy Balls ---
  List<_EnemyBall> _enemyBalls = [];
  int _nextEnemySpawn = 120;

  // --- Boss Ball ---
  _BossBall? _bossBall;

  // --- Power-ups ---
  List<_PowerUp> _powerUps = [];
  int _nextPowerUpSpawn = 300;
  String? _activePowerUp;
  int _powerUpTimer = 0;

  // --- Combo System ---
  int _combo = 0;
  int _comboTimer = 0;
  static const int _comboMax = 10;

  // --- Screen Shake ---
  double _shakeX = 0, _shakeY = 0;
  bool _shaking = false;

  // --- Particles ---
  List<_Particle> _particles = [];

  // --- Trail ---
  List<_TrailPoint> _trail = [];

  // --- Floating Score Texts ---
  List<_FloatText> _floatTexts = [];

  // --- Wave Announcement ---
  bool _waveAnnounce = false;
  int _waveAnnounceTimer = 0;

  // --- Level Up Flash ---
  bool _levelFlash = false;
  int _levelFlashTimer = 0;

  // --- Twinkling Stars ---
  late List<_TwinkleStar> _twinkleStars;

  // --- Touch ---
  Offset? _lastTouch;

  static const double _ballR = 0.04;
  static const double _kickVy = -0.018;
  static const double _maxVx = 0.018;

  @override
  void initState() {
    super.initState();
    _initStars();
  }

  void _initStars() {
    final rng = Random(99);
    _twinkleStars = List.generate(50, (i) => _TwinkleStar(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.75,
      size: 0.8 + rng.nextDouble() * 1.4,
      phase: rng.nextDouble() * 2 * pi,
      speed: 0.02 + rng.nextDouble() * 0.03,
    ));
  }

  void _start() {
    _paddleX = 0.5;
    _paddleTargetX = 0.5;
    _playerBalls = [
      _PlayerBall(
        x: 0.5, y: 0.55,
        vx: (Random().nextDouble() - 0.5) * 0.004,
        vy: -0.012, rotation: 0),
    ];
    _score = 0;
    _level = 1;
    _lives = 3;
    _combo = 0;
    _comboTimer = 0;
    _activePowerUp = null;
    _powerUpTimer = 0;
    _enemyBalls = [];
    _powerUps = [];
    _particles = [];
    _trail = [];
    _floatTexts = [];
    _frameCount = 0;
    _nextEnemySpawn = 120;
    _nextPowerUpSpawn = 300;
    _lastTouch = null;
    _shaking = false;
    _shakeX = 0; _shakeY = 0;
    _wave = 1;
    _waveTimer = 0;
    _bossActive = false;
    _bossBall = null;
    _waveAnnounce = true;
    _waveAnnounceTimer = 90;
    _levelFlash = false;
    _levelFlashTimer = 0;
    _bossFlash = false;
    _initStars();
    setState(() => _playing = true; _gameOver = false; _paused = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
  }

  int _frameCount = 0;

  void _triggerShake({double intensity = 6}) {
    _shaking = true;
    final rng = Random();
    _shakeX = (rng.nextDouble() - 0.5) * intensity;
    _shakeY = (rng.nextDouble() - 0.5) * intensity;
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() { _shaking = false; _shakeX = 0; _shakeY = 0; });
    });
  }

  void _spawnFloatText(String text, double x, double y, Color color, {double size = 14}) {
    _floatTexts.add(_FloatText(
      text: text, x: x, y: y,
      vy: -0.006,
      life: 45,
      color: color, size: size,
    ));
  }

  void _update() {
    if (!_playing || _paused) return;
    _frameCount++;

    // Wave timer
    _waveTimer++;

    // Wave announcement countdown
    if (_waveAnnounce) {
      _waveAnnounceTimer--;
      if (_waveAnnounceTimer <= 0) _waveAnnounce = false;
    }

    // Level flash
    if (_levelFlash) {
      _levelFlashTimer--;
      if (_levelFlashTimer <= 0) _levelFlash = false;
    }

    setState(() {
      // Move paddle smoothly
      _paddleX += (_paddleTargetX - _paddleX) * 0.18;

      // Apply slow-mo
      final timeScale = _activePowerUp == 'slowmo' ? 0.4 : 1.0;

      // Update player balls
      for (int bi = _playerBalls.length - 1; bi >= 0; bi--) {
        final b = _playerBalls[bi];
        b.vy += 0.00025 * timeScale;
        b.vx *= 0.998;
        b.x += b.vx * timeScale;
        b.y += b.vy * timeScale;
        b.rotation += b.vx * 6;

        // Wall bounce
        if (b.x < _ballR) { b.x = _ballR; b.vx = b.vx.abs(); }
        if (b.x > 1 - _ballR) { b.x = 1 - _ballR; b.vx = -b.vx.abs(); }

        // Ceiling bounce
        if (b.y < _ballR) { b.y = _ballR; b.vy = b.vy.abs(); }

        // Trail
        if (_frameCount % 2 == 0) {
          final trailColor = _activePowerUp == 'fireball'
              ? Colors.orange
              : _activePowerUp == 'multi'
                  ? Colors.cyan
                  : AppColors.primaryBlue;
          _trail.add(_TrailPoint(x: b.x, y: b.y, life: 18, r: _ballR * 0.7, color: trailColor));
          if (_trail.length > 50) _trail.removeAt(0);
        }

        // Paddle collision
        if (b.vy > 0 &&
            b.y + _ballR > _paddleY - 0.02 &&
            b.y - _ballR < _paddleY + 0.02 &&
            b.x > _paddleX - _paddleW / 2 &&
            b.x < _paddleX + _paddleW / 2) {
          b.y = _paddleY - _ballR - 0.001;
          b.vy = _kickVy - (_level * 0.0005);
          b.vx += (b.x - _paddleX) * 0.04;
          b.vx = b.vx.clamp(-_maxVx * 1.5, _maxVx * 1.5);

          _combo = min(_combo + 1, _comboMax);
          _comboTimer = 60;

          final multiplier = 1 + (_combo ~/ 3);
          _score += multiplier;
          if (_score > 0 && _score % 15 == 0) {
            _level++;
            _levelFlash = true;
            _levelFlashTimer = 40;
            _spawnFloatText('🎯 LEVEL UP!', 0.5, 0.3, Colors.yellow, size: 18);
            if (_level % _bossWave == 0 && !_bossActive) {
              _spawnBoss();
            }
          }

          _spawnKickParticles(b.x, _paddleY - 0.02, color: _activePowerUp == 'fireball' ? Colors.orange : Colors.yellow);
          HapticFeedback.lightImpact();
          if (_combo > 2) _triggerShake(intensity: 3);

          // Achievement: 10 combo
          if (_combo == 10 && !_achievements.contains('combo_10')) {
            _achievements.add('combo_10');
            _spawnFloatText('🏆 COMBO x10!', 0.5, 0.5, Colors.amber, size: 16);
          }
        }

        // Ball fell
        if (b.y > 1.1) {
          _playerBalls.removeAt(bi);
          if (_playerBalls.isEmpty) {
            _lives--;
            if (_lives <= 0) {
              _endGame();
              return;
            } else {
              _playerBalls.add(_PlayerBall(
                x: _paddleX, y: _paddleY - 0.1,
                vx: 0, vy: -0.015, rotation: 0));
              _spawnExplosion(_paddleX, 0.95, Colors.red, 12);
            }
          } else {
            _spawnExplosion(b.x, 0.95, Colors.red, 8);
          }
        }
      }

      // --- Enemy Balls ---
      _nextEnemySpawn = (_nextEnemySpawn - timeScale.toInt()).clamp(1, 9999).toInt();
      if (_nextEnemySpawn <= 0 && !_bossActive) {
        final side = Random().nextBool();
        _enemyBalls.add(_EnemyBall(
          x: side ? Random().nextDouble() : Random().nextDouble(),
          y: -0.06,
          vx: (Random().nextDouble() - 0.5) * 0.005,
          vy: (0.007 + _level * 0.001) * timeScale,
          r: 0.035,
          colorIdx: Random().nextInt(3),
        ));
        _nextEnemySpawn = max(80, 200 - _level * 15);
      }
      for (int i = _enemyBalls.length - 1; i >= 0; i--) {
        final e = _enemyBalls[i];
        e.x += e.vx * timeScale;
        e.y += e.vy * timeScale;
        e.angle = (e.angle ?? 0) + e.vx * 4;

        if (e.x < e.r) { e.x = e.r; e.vx = e.vx.abs(); }
        if (e.x > 1 - e.r) { e.x = 1 - e.r; e.vx = -e.vx.abs(); }

        if (e.y > 1.2) { _enemyBalls.removeAt(i); continue; }

        if (_activePowerUp != 'shield' &&
            e.y + e.r > _paddleY - 0.02 &&
            e.y < _paddleY + 0.02 &&
            e.x > _paddleX - _paddleW / 2 &&
            e.x < _paddleX + _paddleW / 2) {
          _enemyBalls.removeAt(i);
          _lives--;
          _spawnExplosion(e.x, _paddleY, Colors.red, 8);
          _triggerShake(intensity: 10);
          if (_lives <= 0) { _endGame(); return; }
          continue;
        }

        // Fireball destroys enemies on contact
        bool fireballKill = _activePowerUp == 'fireball';

        for (int bi = _playerBalls.length - 1; bi >= 0; bi--) {
          final b = _playerBalls[bi];
          final dx = b.x - e.x, dy = b.y - e.y;
          if (sqrt(dx * dx + dy * dy) < _ballR + e.r) {
            _enemyBalls.removeAt(i);
            final color = fireballKill ? Colors.orange : Colors.orange;
            _spawnExplosion(e.x, e.y, color, fireballKill ? 16 : 10);
            if (fireballKill) {
              _score += 5;
              _spawnFloatText('+5', e.x, e.y, Colors.orange);
            }
            if (_activePowerUp != 'shield') {
              _lives--;
              _triggerShake(intensity: 10);
              if (_lives <= 0) { _endGame(); return; }
            } else {
              _score += 3;
            }
            break;
          }
        }
      }

      // --- Boss Ball ---
      if (_bossActive && _bossBall != null) {
        final boss = _bossBall!;
        boss.x += boss.vx * timeScale;
        boss.y += boss.vy * timeScale;
        boss.angle = (boss.angle ?? 0) + boss.vx * 2;
        boss.bobPhase += 0.04;

        if (boss.x < boss.r) { boss.x = boss.r; boss.vx = boss.vx.abs(); }
        if (boss.x > 1 - boss.r) { boss.x = 1 - boss.r; boss.vx = -boss.vx.abs(); }
        if (boss.y > 0.25) { boss.y = 0.25; boss.vy = -boss.vy.abs(); }
        if (boss.y < 0.03) { boss.y = 0.03; boss.vy = boss.vy.abs(); }

        // Boss collision with paddle
        if (_activePowerUp != 'shield' &&
            boss.y + boss.r > _paddleY - 0.02 &&
            boss.y < _paddleY + 0.02 &&
            boss.x > _paddleX - _paddleW / 2 &&
            boss.x < _paddleX + _paddleW / 2) {
          _lives--;
          _triggerShake(intensity: 14);
          _spawnExplosion(boss.x, _paddleY, Colors.red, 15);
          if (_lives <= 0) { _endGame(); return; }
        }

        // Boss hit by player balls
        for (int bi = _playerBalls.length - 1; bi >= 0; bi--) {
          final b = _playerBalls[bi];
          final dx = b.x - boss.x, dy = b.y - boss.y;
          if (sqrt(dx * dx + dy * dy) < _ballR + boss.r) {
            boss.hp--;
            boss.flashTimer = 8;
            _spawnExplosion(boss.x, boss.y, Colors.red, 12);
            _score += 10;
            _spawnFloatText('💥 -1 HP!', boss.x, boss.y - 0.05, Colors.red, size: 16);
            _triggerShake(intensity: 6);
            if (boss.hp <= 0) {
              _killBoss();
            } else {
              // Bounce ball back
              b.vy = -b.vy.abs();
            }
          }
        }

        // Boss vs enemy ball collision
        for (int i = _enemyBalls.length - 1; i >= 0; i--) {
          final e = _enemyBalls[i];
          final dx = e.x - boss.x, dy = e.y - boss.y;
          if (sqrt(dx * dx + dy * dy) < boss.r + e.r) {
            _enemyBalls.removeAt(i);
            _spawnExplosion(e.x, e.y, Colors.orange, 8);
          }
        }
      }

      // --- Power-ups ---
      _nextPowerUpSpawn--;
      if (_nextPowerUpSpawn <= 0) {
        final types = ['life', 'multi', 'shield', 'slowmo', 'fireball'];
        final type = types[Random().nextInt(types.length)];
        _powerUps.add(_PowerUp(
          x: 0.1 + Random().nextDouble() * 0.8,
          y: -0.04,
          type: type,
        ));
        _nextPowerUpSpawn = 300 + Random().nextInt(200);
      }
      for (int i = _powerUps.length - 1; i >= 0; i--) {
        final p = _powerUps[i];
        p.y += 0.004;
        if (p.y > 1.1) { _powerUps.removeAt(i); continue; }
        bool collected = false;
        for (final b in _playerBalls) {
          final dx = b.x - p.x, dy = b.y - p.y;
          if (sqrt(dx * dx + dy * dy) < _ballR + 0.04) {
            collected = true; break;
          }
        }
        if (!collected) continue;
        _powerUps.removeAt(i);
        _score += 5;

        if (p.type == 'life') {
          _lives = min(_lives + 1, 5);
          _spawnKickParticles(p.x, p.y, color: Colors.red);
          _spawnFloatText('+1 ❤️', p.x, p.y, Colors.red);
        } else if (p.type == 'multi') {
          final ref = _playerBalls[0];
          for (int j = 0; j < 2; j++) {
            _playerBalls.add(_PlayerBall(
              x: ref.x + (j == 0 ? -0.05 : 0.05),
              y: ref.y,
              vx: ref.vx + (j == 0 ? -0.003 : 0.003),
              vy: ref.vy,
              rotation: 0,
            ));
          }
          _activePowerUp = 'multi';
          _powerUpTimer = 240;
          _spawnKickParticles(p.x, p.y, color: Colors.cyan);
          _spawnFloatText('⚡ MULTI-BALL!', p.x, p.y, Colors.cyan, size: 16);
        } else if (p.type == 'shield') {
          _activePowerUp = 'shield';
          _powerUpTimer = 300;
          _spawnKickParticles(p.x, p.y, color: Colors.purpleAccent);
          _spawnFloatText('🛡️ SHIELD!', p.x, p.y, Colors.purpleAccent, size: 16);
        } else if (p.type == 'slowmo') {
          _activePowerUp = 'slowmo';
          _powerUpTimer = 300;
          _spawnKickParticles(p.x, p.y, color: Colors.yellow);
          _spawnFloatText('⏱️ SLOW-MO!', p.x, p.y, Colors.yellow, size: 16);
        } else if (p.type == 'fireball') {
          _activePowerUp = 'fireball';
          _powerUpTimer = 240;
          _spawnKickParticles(p.x, p.y, color: Colors.deepOrange);
          _spawnFloatText('🔥 FIREBALL!', p.x, p.y, Colors.deepOrange, size: 16);
        }
      }

      if (_activePowerUp != null) {
        _powerUpTimer--;
        if (_powerUpTimer <= 0) _activePowerUp = null;
      }

      if (_comboTimer > 0) {
        _comboTimer--;
        if (_comboTimer <= 0) _combo = 0;
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

      // Trail fade
      for (int i = _trail.length - 1; i >= 0; i--) {
        _trail[i].life--;
        if (_trail[i].life <= 0) _trail.removeAt(i);
      }

      // Float texts
      for (int i = _floatTexts.length - 1; i >= 0; i--) {
        final ft = _floatTexts[i];
        ft.y += ft.vy;
        ft.life--;
        if (ft.life <= 0) _floatTexts.removeAt(i);
      }
    });
  }

  void _spawnBoss() {
    _bossActive = true;
    final bossHp = 3 + (_level ~/ _bossWave);
    _bossBall = _BossBall(
      x: 0.5, y: 0.1,
      vx: (Random().nextDouble() - 0.5) * 0.003,
      vy: 0.002,
      r: 0.08,
      hp: bossHp,
      maxHp: bossHp,
    );
    _spawnFloatText('💀 BOSS APPROACHES!', 0.5, 0.5, Colors.red, size: 20);
    _triggerShake(intensity: 12);
  }

  void _killBoss() {
    if (_bossBall == null) return;
    final boss = _bossBall!;
    for (int i = 0; i < 40; i++) {
      final a = Random().nextDouble() * 2 * pi;
      final spd = 0.005 + Random().nextDouble() * 0.015;
      _particles.add(_Particle(
        x: boss.x, y: boss.y,
        vx: cos(a) * spd,
        vy: sin(a) * spd,
        life: 40 + Random().nextInt(30),
        color: [Colors.red, Colors.orange, Colors.yellow][Random().nextInt(3)],
        r: 0.015 + Random().nextDouble() * 0.02,
      ));
    }
    _score += 50;
    _spawnFloatText('💀 BOSS DEFEATED! +50', 0.5, 0.4, Colors.amber, size: 18);
    _bossBall = null;
    _bossActive = false;
    _triggerShake(intensity: 16);

    // Achievement
    if (!_achievements.contains('boss_killer')) {
      _achievements.add('boss_killer');
    }
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
                Expanded(
                  child: Text('⚡ Ball Bounce Blitz',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold))),
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
                _hudItem('🌊', 'W$_wave', Colors.cyan),
                if (_combo > 1) _hudItem('🔥', 'x${1 + (_combo ~/ 3)}', Colors.orange),
              ]),
            ),

            // Boss HP bar
            if (_bossActive && _bossBall != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(100)),
                ),
                child: Row(children: [
                  const Text('💀 BOSS', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _bossBall!.hp / _bossBall!.maxHp,
                        backgroundColor: Colors.red.withAlpha(50),
                        valueColor: const AlwaysStoppedAnimation(Colors.red),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_bossBall!.hp}/${_bossBall!.maxHp}',
                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),

            // Power-up indicator
            if (_activePowerUp != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
                decoration: BoxDecoration(
                  color: _getPowerUpColor(_activePowerUp!).withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getPowerUpColor(_activePowerUp!).withAlpha(100)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${_getPowerUpIcon(_activePowerUp!)} ${_getPowerUpLabel(_activePowerUp!)} ',
                    style: TextStyle(color: _getPowerUpColor(_activePowerUp!), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('${(_powerUpTimer / 60).ceil()}s', style: TextStyle(color: _getPowerUpColor(_activePowerUp!), fontSize: 11)),
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
                      for (final b in _playerBalls) {
                        final dx = b.x - tx, dy = b.y - ty;
                        if (sqrt(dx * dx + dy * dy) < 0.12) {
                          setState(() {
                            b.vy = _kickVy * 0.7;
                            b.vx += dx * 0.02;
                          });
                          break;
                        }
                      }
                    },
                    child: Transform.translate(
                      offset: Offset(_shakeX, _shakeY),
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
                              playerBalls: _playerBalls,
                              enemyBalls: _enemyBalls,
                              powerUps: _powerUps,
                              particles: _particles,
                              trail: _trail,
                              floatTexts: _floatTexts,
                              score: _score, bestScore: _bestScore, level: _level, lives: _lives,
                              combo: _combo,
                              playing: _playing, gameOver: _gameOver,
                              activePowerUp: _activePowerUp,
                              slowmo: _activePowerUp == 'slowmo',
                              shield: _activePowerUp == 'shield',
                              fireball: _activePowerUp == 'fireball',
                              twinkleStars: _twinkleStars,
                              waveAnnounce: _waveAnnounce,
                              waveAnnounceTimer: _waveAnnounceTimer,
                              wave: _wave,
                              bossBall: _bossBall,
                              bossFlash: _bossFlash,
                              levelFlash: _levelFlash,
                              frameCount: _frameCount,
                            ),
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
                    const Text('💡 Paddle: sürükle | Topa tıkla: ekstra güç | 🔥 combo bonus!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPowerUpColor(String type) {
    switch (type) {
      case 'life': return Colors.red;
      case 'multi': return Colors.cyan;
      case 'shield': return Colors.purpleAccent;
      case 'slowmo': return Colors.yellow;
      case 'fireball': return Colors.deepOrange;
      default: return Colors.white;
    }
  }

  String _getPowerUpIcon(String type) {
    switch (type) {
      case 'life': return '❤️';
      case 'multi': return '⚡';
      case 'shield': return '🛡️';
      case 'slowmo': return '⏱️';
      case 'fireball': return '🔥';
      default: return '💎';
    }
  }

  String _getPowerUpLabel(String type) {
    switch (type) {
      case 'life': return 'EXTRA LIFE';
      case 'multi': return 'MULTI-BALL';
      case 'shield': return 'SHIELD ACTIVE';
      case 'slowmo': return 'SLOW-MO';
      case 'fireball': return 'FIREBALL';
      default: return 'POWER UP';
    }
  }

  Widget _hudItem(String icon, String val, Color color) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ---- Classes ----
class _PlayerBall {
  double x, y, vx, vy, rotation;
  _PlayerBall({required this.x, required this.y, required this.vx, required this.vy, required this.rotation});
}

class _EnemyBall {
  double x, y, vx, vy, r, angle;
  int colorIdx;
  _EnemyBall({required this.x, required this.y, required this.vx, required this.vy,
    required this.r, this.angle = 0, this.colorIdx = 0});
}

class _BossBall {
  double x, y, vx, vy, r, angle = 0, bobPhase = 0;
  int hp, maxHp;
  int flashTimer = 0;
  _BossBall({required this.x, required this.y, required this.vx, required this.vy,
    required this.r, required this.hp, required this.maxHp});
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

class _TrailPoint {
  double x, y, r;
  int life;
  Color color;
  _TrailPoint({required this.x, required this.y, required this.life, required this.r, required this.color});
}

class _FloatText {
  String text;
  double x, y, vy;
  int life;
  Color color;
  double size;
  _FloatText({required this.text, required this.x, required this.y, required this.vy,
    required this.life, required this.color, required this.size});
}

class _TwinkleStar {
  double x, y, size, phase, speed;
  _TwinkleStar({required this.x, required this.y, required this.size, required this.phase, required this.speed});
}

// ---- Painter ----
class _BlitzPainter extends CustomPainter {
  final double paddleX, paddleY, paddleW;
  final List<_PlayerBall> playerBalls;
  final List<_EnemyBall> enemyBalls;
  final List<_PowerUp> powerUps;
  final List<_Particle> particles;
  final List<_TrailPoint> trail;
  final List<_FloatText> floatTexts;
  final int score, bestScore, level, lives, combo;
  final bool playing, gameOver;
  final String? activePowerUp;
  final bool slowmo, shield, fireball;
  final List<_TwinkleStar> twinkleStars;
  final bool waveAnnounce;
  final int waveAnnounceTimer;
  final int wave;
  final _BossBall? bossBall;
  final bool bossFlash;
  final bool levelFlash;
  final int frameCount;

  _BlitzPainter({
    required this.paddleX, required this.paddleY, required this.paddleW,
    required this.playerBalls,
    required this.enemyBalls, required this.powerUps, required this.particles,
    required this.trail, required this.floatTexts,
    required this.score, required this.bestScore, required this.level, required this.lives,
    required this.combo,
    required this.playing, required this.gameOver,
    this.activePowerUp, this.slowmo = false, this.shield = false, this.fireball = false,
    required this.twinkleStars,
    required this.waveAnnounce, required this.waveAnnounceTimer, required this.wave,
    this.bossBall, this.bossFlash = false, this.levelFlash = false,
    required this.frameCount,
  });

  static const _enemyColors = [
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFFFF6B6B),
  ];

  static const _ballColors = [
    Colors.white,
    Color(0xFF5DADE2),
    Color(0xFF58D68D),
  ];

  Color _getPowerUpGlowColor(String type) {
    switch (type) {
      case 'life': return Colors.red;
      case 'multi': return Colors.cyan;
      case 'shield': return Colors.purpleAccent;
      case 'slowmo': return Colors.yellow;
      case 'fireball': return Colors.deepOrange;
      default: return Colors.white;
    }
  }

  String _getPowerUpSymbol(String type) {
    switch (type) {
      case 'life': return '❤';
      case 'multi': return '⚡';
      case 'shield': return '🛡️';
      case 'slowmo': return '⏱️';
      case 'fireball': return '🔥';
      default: return '💎';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Level flash overlay
    if (levelFlash) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Colors.yellow.withAlpha(40 * (levelFlash ? 1 : 0)));
    }

    // Twinkling stars
    for (final star in twinkleStars) {
      final brightness = 0.3 + 0.7 * ((sin(frameCount * star.speed + star.phase) + 1) / 2);
      final alpha = (brightness * 180).clamp(0.0, 255.0).toInt();
      canvas.drawCircle(
        Offset(star.x * w, star.y * h),
        star.size,
        Paint()..color = Colors.white.withAlpha(alpha),
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

    // Shield bubble around paddle
    if (shield) {
      final shieldPaint = Paint()
        ..color = Colors.purpleAccent.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final pw = paddleW * w, ph = 28.0;
      final px = paddleX * w - pw / 2, py = paddleY * h - ph / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 6, py - 6, pw + 12, ph + 12),
          const Radius.circular(12),
        ),
        shieldPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 6, py - 6, pw + 12, ph + 12),
          const Radius.circular(12),
        ),
        Paint()..color = Colors.purpleAccent.withAlpha(20),
      );
    }

    // Trail
    for (final t in trail) {
      final alpha = (t.life * 12).clamp(0, 120);
      canvas.drawCircle(
        Offset(t.x * w, t.y * h),
        t.r * w * (t.life / 18),
        Paint()..color = t.color.withAlpha(alpha),
      );
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
      final glowColor = _getPowerUpGlowColor(p.type);
      canvas.drawCircle(Offset(px, py), 22, Paint()..color = glowColor.withAlpha(40));
      canvas.drawCircle(Offset(px, py), 18, Paint()..color = glowColor.withAlpha(60));
      canvas.drawCircle(Offset(px, py), 14, Paint()..color = glowColor);
      final text = _getPowerUpSymbol(p.type);
      final tp = TextPainter(text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }

    // Enemy balls
    for (final e in enemyBalls) {
      final ex = e.x * w, ey = e.y * h, er = e.r * w;
      final color = _enemyColors[e.colorIdx % _enemyColors.length];
      // Glow
      canvas.drawCircle(Offset(ex, ey), er * 1.4, Paint()..color = color.withAlpha(30));
      canvas.drawCircle(Offset(ex, ey), er, Paint()..color = color);
      canvas.drawCircle(Offset(ex, ey), er, Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      // Angry face
      canvas.save();
      canvas.translate(ex, ey);
      final facePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(-er * 0.3, -er * 0.1), Offset(-er * 0.1, er * 0.1), facePaint);
      canvas.drawLine(Offset(er * 0.3, -er * 0.1), Offset(er * 0.1, er * 0.1), facePaint);
      canvas.drawArc(Rect.fromCenter(center: Offset(0, er * 0.3), width: er * 0.6, height: er * 0.3),
        pi, pi, false, facePaint);
      canvas.restore();
    }

    // Boss Ball
    if (bossBall != null) {
      final boss = bossBall;
      final bx = boss!.x * w;
      final by = (boss.y + sin(boss.bobPhase) * 0.015) * h;
      final br = boss.r * w;
      final bossColor = boss.flashTimer > 0 ? Colors.white : const Color(0xFF8B0000);
      // Pulsing outer glow
      canvas.drawCircle(Offset(bx, by), br * 2.0, Paint()..color = Colors.red.withAlpha(20));
      canvas.drawCircle(Offset(bx, by), br * 1.5, Paint()..color = Colors.red.withAlpha(30));
      // Shadow
      canvas.drawCircle(Offset(bx + 3, by + 3), br, Paint()..color = Colors.black.withAlpha(50));
      // Body
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = bossColor);
      // Skull pattern
      canvas.save();
      canvas.translate(bx, by);
      final sk = Paint()..color = Colors.black87;
      // Eyes
      canvas.drawOval(Rect.fromCenter(center: Offset(-br * 0.25, -br * 0.1), width: br * 0.35, height: br * 0.4), sk);
      canvas.drawOval(Rect.fromCenter(center: Offset(br * 0.25, -br * 0.1), width: br * 0.35, height: br * 0.4), sk);
      // Nose
      final nosePath = Path()
        ..moveTo(0, 0)
        ..lineTo(-br * 0.1, br * 0.15)
        ..lineTo(br * 0.1, br * 0.15)
        ..close();
      canvas.drawPath(nosePath, sk);
      // Teeth
      for (int i = -2; i <= 2; i++) {
        canvas.drawRect(Rect.fromLTWH(i * br * 0.18, br * 0.25, br * 0.12, br * 0.2), sk);
      }
      canvas.restore();
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Player balls
    for (int bi = 0; bi < playerBalls.length; bi++) {
      final b = playerBalls[bi];
      final bx = b.x * w, by = b.y * h, br = 0.04 * w;
      final ballColor = fireball
          ? Colors.deepOrange
          : _ballColors[bi % _ballColors.length];

      // Glow
      canvas.drawCircle(Offset(bx, by), br * 1.8, Paint()..color = ballColor.withAlpha(30));
      canvas.drawCircle(Offset(bx, by), br * 1.3, Paint()..color = ballColor.withAlpha(20));

      // Fireball flame effect
      if (fireball) {
        final flameRng = Random(bi * 100 + frameCount);
        for (int fi = 0; fi < 5; fi++) {
          final fa = flameRng.nextDouble() * 2 * pi;
          final fr = br * 0.8 + flameRng.nextDouble() * br * 0.8;
          final fx = bx + cos(fa) * fr;
          final fy = by + sin(fa) * fr;
          canvas.drawCircle(Offset(fx, fy), br * 0.4,
            Paint()..color = [Colors.orange, Colors.yellow, Colors.red][fi % 3].withAlpha(100));
        }
      }

      // Shadow
      canvas.drawCircle(Offset(bx + 1, by + 1), br, Paint()..color = Colors.black.withAlpha(30));

      // Ball body
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = ballColor);

      // Pentagon pattern
      canvas.save();
      canvas.translate(bx, by);
      final pp = Paint()..color = Colors.black87;
      for (int i = 0; i < 5; i++) {
        final angle = b.rotation + i * pi * 2 / 5;
        final cx = cos(angle) * br * 0.55;
        final cy = sin(angle) * br * 0.55;
        _drawPentagon(canvas, cx, cy, br * 0.25, pp);
      }
      canvas.restore();

      // Outline
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Shine
      canvas.drawCircle(Offset(bx - br * 0.3, by - br * 0.3), br * 0.22, Paint()..color = Colors.white.withAlpha(160));
    }

    // Paddle
    final pw = paddleW * w, ph = 14.0;
    final px = paddleX * w - pw / 2, py = paddleY * h - ph / 2;
    final paddleGrad = LinearGradient(
      colors: shield
          ? [Colors.purpleAccent, const Color(0xFF8E44AD)]
          : fireball
              ? [Colors.deepOrange, Colors.red]
              : [AppColors.primaryBlue, const Color(0xFF2980B9)],
    ).createShader(Rect.fromLTWH(px, py, pw, ph));
    final paddleRect = RRect.fromRectAndRadius(Rect.fromLTWH(px, py, pw, ph), const Radius.circular(8));
    canvas.drawRRect(paddleRect, Paint()..shader = paddleGrad);
    canvas.drawRRect(paddleRect, Paint()..color = Colors.white.withAlpha(60)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px + 4, py + 2, pw * 0.4, 4), const Radius.circular(2)),
      Paint()..color = Colors.white.withAlpha(80));

    // Slow-mo vignette
    if (slowmo) {
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0x4000BFFF)],
          stops: const [0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);
    }

    // Wave announcement
    if (waveAnnounce) {
      final alpha = (waveAnnounceTimer > 60
          ? ((90 - waveAnnounceTimer) / 30 * 255).clamp(0.0, 255.0)
          : (waveAnnounceTimer / 60 * 255)).clamp(0.0, 255.0).toInt();
      _text(canvas, '🌊 WAVE $wave', w / 2, h * 0.12, 22, Colors.cyan.withAlpha(alpha));
    }

    // Score popup
    if (score > 0 && playing) {
      final mult = 1 + (combo ~/ 3);
      final color = mult > 2 ? Colors.orange : mult > 1 ? Colors.yellow : Colors.white70;
      final extra = mult > 1 ? ' (x$mult)' : '';
      _text(canvas, '+$score$extra', w * 0.85, h * 0.06, 13 + min(score.toDouble(), 8) * 0.3, color);
    }

    // Float texts
    for (final ft in floatTexts) {
      final alpha = (ft.life * 6).clamp(0, 255).toInt();
      _text(canvas, ft.text, ft.x * w, ft.y * h, ft.size, ft.color.withAlpha(alpha));
    }

    // Overlay: Start
    if (!playing && !gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black45);
      _text(canvas, '⚡ Ball Bounce Blitz', w / 2, h * 0.25, 24, Colors.white);
      _text(canvas, '🎯 YENİ: Wave System + Boss Ball!', w / 2, h * 0.37, 12, Colors.cyan);
      _text(canvas, 'Paddle\'ı sürekle, düşmanlardan kaçın', w / 2, h * 0.47, 13, Colors.white70);
      _text(canvas, '🔥 Combo ile bonus puan kazan!', w / 2, h * 0.55, 13, Colors.orange);
      _text(canvas, '💀 Her 5 seviyede BOSS çıkıyor!', w / 2, h * 0.63, 13, Colors.red.shade300);
      _text(canvas, 'Başlamak için ▶ butonuna tıkla', w / 2, h * 0.73, 12, Colors.white54);
    }

    // Overlay: Game Over
    if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black60);
      _text(canvas, '💥 Oyun Bitti!', w / 2, h * 0.25, 28, Colors.red.shade300);
      _text(canvas, 'Skor: $score  |  Seviye: $level', w / 2, h * 0.38, 16, Colors.white);
      _text(canvas, 'En İyi: $bestScore', w / 2, h * 0.47, 14, AppColors.primaryOrange);
      if (combo > 0) {
        _text(canvas, 'Max Combo: 🔥 x${1 + (combo ~/ 3)}', w / 2, h * 0.55, 13, Colors.orange);
      }
      if (score >= bestScore && score > 0) {
        _text(canvas, '🎉 Yeni Rekor!', w / 2, h * 0.63, 18, Colors.yellow.shade300);
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
