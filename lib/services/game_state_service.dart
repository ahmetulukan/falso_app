import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameStateService {
  static GameStateService? _instance;
  late SharedPreferences _prefs;
  User? _currentUser;
  String _nickname = 'Futbolcu';

  GameStateService._();

  static Future<GameStateService> getInstance() async {
    if (_instance == null) {
      _instance = GameStateService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _nickname = _prefs.getString('nickname') ?? 'Futbolcu';
    // Use existing auth user (email or anonymous)
    try {
      final auth = FirebaseAuth.instance;
      _currentUser = auth.currentUser;
      if (_currentUser != null && _currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
        _nickname = _currentUser!.displayName!;
      }
    } catch (e) {
      debugPrint('Auth unavailable: $e');
    }
  }

  // ─── User ────────────────────────────────
  String get nickname => _nickname;
  String? get uid => _currentUser?.uid;
  bool get isAuthenticated => _currentUser != null;

  Future<void> setNickname(String name) async {
    _nickname = name;
    await _prefs.setString('nickname', name);
    if (isAuthenticated) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'nickname': name, 'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ─── Favorite Team ────────────────────────────────
  String? get favoriteTeam => _prefs.getString('favorite_team');
  String? get favoriteTeamLogo => _prefs.getString('favorite_team_logo');

  Future<void> setFavoriteTeam(String team, String logoUrl) async {
    await _prefs.setString('favorite_team', team);
    await _prefs.setString('favorite_team_logo', logoUrl);
  }

  // ─── Daily Streak ────────────────────────────────
  int get streak {
    final lastPlayStr = _prefs.getString('last_play_date');
    if (lastPlayStr == null) return 0;
    final lastPlay = DateTime.parse(lastPlayStr);
    final today = DateTime.now();
    final dayDiff = DateTime(today.year, today.month, today.day).difference(DateTime(lastPlay.year, lastPlay.month, lastPlay.day)).inDays;
    if (dayDiff > 1) return 0; // Streak broken
    return _prefs.getInt('streak') ?? 0;
  }

  Future<void> recordPlay() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastPlayStr = _prefs.getString('last_play_date');

    if (lastPlayStr == todayStr) return; // Already played today

    int currentStreak = streak;
    if (lastPlayStr != null) {
      final lastPlay = DateTime.parse(lastPlayStr);
      final dayDiff = DateTime(today.year, today.month, today.day).difference(DateTime(lastPlay.year, lastPlay.month, lastPlay.day)).inDays;
      if (dayDiff == 1) currentStreak++;
      else if (dayDiff > 1) currentStreak = 1;
    } else {
      currentStreak = 1;
    }

    await _prefs.setString('last_play_date', todayStr);
    await _prefs.setInt('streak', currentStreak);
    if (currentStreak > (_prefs.getInt('best_streak') ?? 0)) {
      await _prefs.setInt('best_streak', currentStreak);
    }
  }

  int get bestStreak => _prefs.getInt('best_streak') ?? 0;

  // ─── Scores ────────────────────────────────
  int get totalScore => _prefs.getInt('total_score') ?? 0;

  Future<void> addScore(String game, int points) async {
    final total = totalScore + points;
    await _prefs.setInt('total_score', total);
    final gameScore = (_prefs.getInt('score_$game') ?? 0) + points;
    await _prefs.setInt('score_$game', gameScore);
    final gameCount = (_prefs.getInt('plays_$game') ?? 0) + 1;
    await _prefs.setInt('plays_$game', gameCount);

    // Check badges
    await _checkBadges();

    // Sync to Firestore
    if (isAuthenticated) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'nickname': _nickname,
          'totalScore': total,
          'scores': {game: gameScore},
          'plays': {game: gameCount},
          'streak': streak,
          'bestStreak': bestStreak,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  int getGameScore(String game) => _prefs.getInt('score_$game') ?? 0;
  int getGamePlays(String game) => _prefs.getInt('plays_$game') ?? 0;

  // ─── Predictions ────────────────────────────────
  Future<void> savePrediction(String matchId, String date, int home, int away) async {
    final key = 'pred_${date}_$matchId';
    await _prefs.setString(key, json.encode({'home': home, 'away': away}));

    if (isAuthenticated) {
      try {
        await FirebaseFirestore.instance.collection('predictions').doc('${uid}_$matchId').set({
          'uid': uid, 'matchId': matchId, 'date': date,
          'homeScore': home, 'awayScore': away,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Map<String, int>? getPrediction(String matchId, String date) {
    final key = 'pred_${date}_$matchId';
    final data = _prefs.getString(key);
    if (data == null) return null;
    final map = json.decode(data) as Map<String, dynamic>;
    return {'home': map['home'] as int, 'away': map['away'] as int};
  }

  // ─── Badges ────────────────────────────────
  static const _allBadges = {
    'first_game': {'name': 'İlk Adım', 'desc': 'İlk oyununu oyna', 'icon': '🏅'},
    'score_500': {'name': '500 Puan', 'desc': '500 toplam puan', 'icon': '⭐'},
    'score_1000': {'name': '1000 Puan', 'desc': '1000 toplam puan', 'icon': '🌟'},
    'score_5000': {'name': '5000 Puan', 'desc': '5000 toplam puan', 'icon': '💎'},
    'streak_3': {'name': '3 Gün Serisi', 'desc': '3 gün üst üste oyna', 'icon': '🔥'},
    'streak_7': {'name': 'Haftalık Seri', 'desc': '7 gün üst üste oyna', 'icon': '📅'},
    'streak_30': {'name': 'Aylık Seri!', 'desc': '30 gün üst üste oyna', 'icon': '🏆'},
    'trivia_master': {'name': 'Trivia Ustası', 'desc': 'Trivia\'da 500+ puan', 'icon': '🧠'},
    'football_pro': {'name': 'Mini Futbol Pro', 'desc': 'Mini Futbol\'da 5 galibiyet', 'icon': '⚽'},
    'all_games': {'name': 'Hepsini Dene', 'desc': 'Tüm oyun modlarını oyna', 'icon': '🎮'},
  };

  List<Map<String, dynamic>> get badges {
    final earned = _prefs.getStringList('badges') ?? [];
    return _allBadges.entries.map((e) => {
      'id': e.key, ...e.value, 'earned': earned.contains(e.key),
    }).toList();
  }

  Future<void> _checkBadges() async {
    final earned = (_prefs.getStringList('badges') ?? []).toList();
    void earn(String id) { if (!earned.contains(id)) earned.add(id); }

    if (totalScore > 0) earn('first_game');
    if (totalScore >= 500) earn('score_500');
    if (totalScore >= 1000) earn('score_1000');
    if (totalScore >= 5000) earn('score_5000');
    if (streak >= 3) earn('streak_3');
    if (streak >= 7) earn('streak_7');
    if (streak >= 30) earn('streak_30');
    if (getGameScore('trivia') >= 500) earn('trivia_master');
    if (getGamePlays('mini_football') >= 5) earn('football_pro');

    final games = ['trivia', 'city_finder', 'guess_player', 'transfer', 'mini_football', 'penalty', 'juggling'];
    if (games.every((g) => getGamePlays(g) > 0)) earn('all_games');

    await _prefs.setStringList('badges', earned);
  }

  int get earnedBadgeCount => (_prefs.getStringList('badges') ?? []).length;
}
