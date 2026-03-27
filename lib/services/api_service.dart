import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/match.dart';
import '../models/player.dart';
import 'cache_service.dart';

class ApiService {
  static const String _baseUrl = 'https://api-football-v1.p.rapidapi.com/v3';
  final CacheService _cacheService;
  
  ApiService(this._cacheService);
  
  static Map<String, String> get _headers {
    final apiKey = dotenv.get('RAPIDAPI_KEY', fallback: '');
    final apiHost = dotenv.get('RAPIDAPI_HOST', fallback: 'api-football-v1.p.rapidapi.com');
    
    if (apiKey.isEmpty) {
      throw Exception('RAPIDAPI_KEY is not configured. Please add it to .env file');
    }
    
    return {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': apiHost,
    };
  }

  Future<List<Match>> getUpcomingMatches({bool forceRefresh = false}) async {
    const cacheKey = 'upcoming_matches';
    const dataType = 'matches';
    
    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> fixtures = cachedData['response'] ?? [];
        return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
      }
    }
    
    // Fetch from API
    final response = await http.get(
      Uri.parse('$_baseUrl/fixtures?next=10'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> fixtures = data['response'];
      
      // Save to cache
      await _cacheService.saveToLocalCache(cacheKey, dataType, data);
      await _cacheService.saveToFirestoreCache(cacheKey, dataType, data);
      
      return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
    } else {
      // If API fails, try to return cached data even if expired
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> fixtures = cachedData['response'] ?? [];
        return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
      }
      throw Exception('Failed to load matches. Status code: ${response.statusCode}');
    }
  }

  Future<List<Player>> searchPlayers(String query, {bool forceRefresh = false}) async {
    final cacheKey = 'players_${query.toLowerCase()}';
    const dataType = 'players';
    
    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> players = cachedData['response'] ?? [];
        return players.map((player) => Player.fromJson(player)).toList();
      }
    }
    
    // Fetch from API
    final response = await http.get(
      Uri.parse('$_baseUrl/players?search=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> players = data['response'];
      
      // Save to cache
      await _cacheService.saveToLocalCache(cacheKey, dataType, data);
      await _cacheService.saveToFirestoreCache(cacheKey, dataType, data);
      
      return players.map((player) => Player.fromJson(player)).toList();
    } else {
      // If API fails, try to return cached data even if expired
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> players = cachedData['response'] ?? [];
        return players.map((player) => Player.fromJson(player)).toList();
      }
      throw Exception('Failed to load players. Status code: ${response.statusCode}');
    }
  }

  // Get API usage statistics (for monitoring rate limits)
  Future<Map<String, dynamic>> getApiStats() async {
    final cacheStats = await _cacheService.getCacheStats();
    
    return {
      'cache': cacheStats,
      'api_key_configured': dotenv.get('RAPIDAPI_KEY', fallback: '').isNotEmpty,
      'api_host': dotenv.get('RAPIDAPI_HOST', fallback: ''),
      'environment': dotenv.get('ENVIRONMENT', fallback: 'development'),
    };
  }
}