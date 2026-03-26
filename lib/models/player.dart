class Player {
  final String id;
  final String name;
  final String team;
  final String position;
  final int marketValue;

  Player({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    required this.marketValue,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      team: json['team'],
      position: json['position'],
      marketValue: json['marketValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'team': team,
      'position': position,
      'marketValue': marketValue,
    };
  }
}