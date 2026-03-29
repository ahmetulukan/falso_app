class Team {
  final String id;
  final String name;
  final String logoUrl;
  final String city;
  final String country;
  final String league;
  final String stadium;
  final double lat;
  final double lon;

  Team({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.city,
    required this.country,
    required this.league,
    required this.stadium,
    this.lat = 41.0,
    this.lon = 29.0,
  });
}
