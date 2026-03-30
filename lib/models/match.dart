class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final int leagueId;
  final String leagueName;
  final String leagueLogo;
  final int homeTeamId;
  final int awayTeamId;
  final String? homeLogo;
  final String? awayLogo;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    this.homeScore,
    this.awayScore,
    required this.status,
    this.leagueId = 0,
    this.leagueName = '',
    this.leagueLogo = '',
    this.homeTeamId = 0,
    this.awayTeamId = 0,
    this.homeLogo,
    this.awayLogo,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['fixture']['id'].toString(),
      homeTeam: json['teams']['home']['name'],
      awayTeam: json['teams']['away']['name'],
      date: DateTime.parse(json['fixture']['date']),
      homeScore: json['goals']['home'],
      awayScore: json['goals']['away'],
      status: json['fixture']['status']['short'],
      leagueId: json['league']?['id'] ?? 0,
      leagueName: json['league']?['name'] ?? '',
      leagueLogo: json['league']?['logo'] ?? '',
      homeTeamId: json['teams']?['home']?['id'] ?? 0,
      awayTeamId: json['teams']?['away']?['id'] ?? 0,
      homeLogo: json['teams']?['home']?['logo'],
      awayLogo: json['teams']?['away']?['logo'],
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
      'leagueId': leagueId,
      'leagueName': leagueName,
      'leagueLogo': leagueLogo,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
    };
  }
}