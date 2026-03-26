class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final int? homeScore;
  final int? awayScore;
  final String status;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    this.homeScore,
    this.awayScore,
    required this.status,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      homeTeam: json['homeTeam'],
      awayTeam: json['awayTeam'],
      date: DateTime.parse(json['date']),
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'date': date.toIso8601String(),
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
    };
  }
}