class UserProfile {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final int totalPoints;
  final int level;
  final int gamesPlayed;
  final int correctAnswers;
  final int bestStreak;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.avatarUrl = '',
    this.totalPoints = 0,
    this.level = 1,
    this.gamesPlayed = 0,
    this.correctAnswers = 0,
    this.bestStreak = 0,
  });

  double get accuracy =>
      gamesPlayed > 0 ? (correctAnswers / gamesPlayed * 100) : 0;

  String get levelTitle {
    if (level <= 5) return 'Çaylak';
    if (level <= 10) return 'Amatör';
    if (level <= 20) return 'Profesyonel';
    if (level <= 30) return 'Yıldız';
    return 'Efsane';
  }
}
