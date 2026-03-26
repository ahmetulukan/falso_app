import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/player.dart';

class ApiService {
  static const String _baseUrl = 'https://api-football-v1.p.rapidapi.com/v3';
  static const Map<String, String> _headers = {
    'X-RapidAPI-Key': 'YOUR_API_KEY',
    'X-RapidAPI-Host': 'api-football-v1.p.rapidapi.com',
  };

  Future<List<Match>> getUpcomingMatches() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/fixtures?next=10'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> fixtures = data['response'];
      return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
    } else {
      throw Exception('Failed to load matches');
    }
  }

  Future<List<Player>> searchPlayers(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players?search=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> players = data['response'];
      return players.map((player) => Player.fromJson(player)).toList();
    } else {
      throw Exception('Failed to load players');
    }
  }
}