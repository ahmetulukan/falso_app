import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/match.dart';
import '../models/player.dart';
import 'cache_service.dart';

class ApiService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  final CacheService _cacheService;
  
  ApiService(this._cacheService);
  
  static Map<String, String> get _headers {
    final apiKey = dotenv.get('API_KEY', fallback: '');
    final apiHost = dotenv.get('API_HOST', fallback: 'v3.football.api-sports.io');
    
    if (apiKey.isEmpty) {
      throw Exception('API_KEY is not configured. Please add it to .env file');
    }
    
    return {
      'x-apisports-key': apiKey,
      'x-apisports-host': apiHost,
    };
  }

  // League name keywords to EXCLUDE (youth, amateur, reserves, friendlies)
  static final _excludeKeywords = [
    'u17', 'u18', 'u19', 'u20', 'u21', 'u23',
    'youth', 'boys', 'girls', 'junior', 'cadets',
    'reserve', 'reserves',
    'amateur', 'regional',
    'women', 'feminine', 'femenina', 'femenil', 'frauen',
    'friendlies', 'friendly',
    'non league', 'oberliga', 'landesliga',
    'division 2 -', 'division one league',
    'diski challenge',
    'third league', '3. liga', '3. snl', '4. liga',
    'gamma ethniki', 'derde divisie', 'tweede divisie',
    'srpska liga', 'segunda división rfef',
  ];

  // Priority league IDs (sorted first when available)
  static const _priorityLeagues = [
    203, 204, // Turkey Süper Lig, 1.Lig
    39, 40, 41, 42, 43, // England PL, Championship, League One/Two, National League
    140, 141, // Spain La Liga, Segunda
    135, 138, // Italy Serie A, C
    78, // Germany Bundesliga
    61, // France Ligue 1
    2, 3, 848, // Champions League, Europa League, Conference
    1, 4, // World Cup, Euro
    5, // UEFA Nations League
    30, 31, 32, 33, 34, 35, // WC Qualifiers (Europe, S.America, Asia, Africa etc.)
    9, // Copa America
    6, // African Cup of Nations
    10, // AFC Asian Cup Qualifiers
    960, 961, // Euro Qualifiers, Euro Qualification Playoffs
    480, 481, // WC Qualification Playoffs
    88, // Eredivisie
    94, // Primeira Liga (Portugal)
    144, // Jupiler Pro (Belgium)
    235, // Russian Premier League
    128, 129, // Argentine Primera, Nacional
    71, // Serie A Brazil
    98, // J-League
    292, // K-League
    253, // MLS
    307, // Saudi Pro League
    110, // Wales
    179, // Scottish PL
  ];

  bool _shouldExcludeLeague(String leagueName) {
    final lower = leagueName.toLowerCase();
    return _excludeKeywords.any((kw) => lower.contains(kw));
  }

  Future<List<Match>> getUpcomingMatches({DateTime? date, bool forceRefresh = false}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final cacheKey = 'matches_v2_$dateStr';
    const dataType = 'matches';
    
    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> fixtures = cachedData['response'] ?? [];
        if (fixtures.isNotEmpty) {
          return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
        }
      }
    }
    
    // Fetch matches for the specific date
    final response = await http.get(
      Uri.parse('$_baseUrl/fixtures?date=$dateStr&timezone=Europe/Istanbul'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Check for API-Football specific errors (like rate limit) even on 200 OK
      final errors = data['errors'];
      if (errors != null && ((errors is Map && errors.isNotEmpty) || (errors is List && errors.isNotEmpty))) {
        debugPrint('API Error: $errors');
        final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
        if (cachedData != null) {
          final List<dynamic> cachedFixtures = cachedData['response'] ?? [];
          if (cachedFixtures.isNotEmpty) {
            return cachedFixtures.map((fixture) => Match.fromJson(fixture)).toList();
          }
        }
        throw Exception('API Limitine ulaşıldı veya sunucu hatası: $errors');
      }

      final List<dynamic> fixtures = data['response'] ?? [];
      
      // Step 1: Filter by valid status
      List<dynamic> filtered = fixtures.where((f) {
        final status = f['fixture']['status']['short'] as String;
        return status == 'NS' || status == '1H' || status == '2H' || status == 'HT' || status == 'FT' || status == 'PEN' || status == 'AET' || status == 'TBD' || status == 'PST';
      }).toList();
      
      // Step 2: Remove youth/amateur/friendlies by league name (blacklist approach)
      List<dynamic> cleaned = filtered.where((f) {
        final leagueName = (f['league']['name'] ?? '') as String;
        return !_shouldExcludeLeague(leagueName);
      }).toList();
      
      // Step 3: If after cleaning we have too few matches, use all filtered matches
      if (cleaned.isEmpty) {
        cleaned = filtered;
      }
      
      // Step 4: Sort — priority leagues first, then alphabetically by league name
      cleaned.sort((a, b) {
        final aId = a['league']['id'] as int;
        final bId = b['league']['id'] as int;
        final aIsPriority = _priorityLeagues.contains(aId);
        final bIsPriority = _priorityLeagues.contains(bId);
        
        if (aIsPriority && !bIsPriority) return -1;
        if (!aIsPriority && bIsPriority) return 1;
        
        // Within same tier, sort by league name
        final aName = (a['league']['name'] ?? '') as String;
        final bName = (b['league']['name'] ?? '') as String;
        return aName.compareTo(bName);
      });
      
      // Step 5: Cap at 80 matches to keep the UI responsive
      if (cleaned.length > 80) {
        cleaned = cleaned.sublist(0, 80);
      }
      
      // Save to cache
      final cacheData = {'response': cleaned};
      await _cacheService.saveToLocalCache(cacheKey, dataType, cacheData);
      await _cacheService.saveToFirestoreCache(cacheKey, dataType, cacheData);
      
      return cleaned.map((fixture) => Match.fromJson(fixture)).toList();
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
      'api_key_configured': dotenv.get('API_KEY', fallback: '').isNotEmpty,
      'api_host': dotenv.get('API_HOST', fallback: ''),
      'environment': dotenv.get('ENVIRONMENT', fallback: 'development'),
    };
  }

  /// Fetch squad/players for a team. Returns list of {name, number, position, photo}.
  Future<List<Map<String, dynamic>>> getTeamSquad(int teamId, {bool forceRefresh = false}) async {
    if (teamId <= 0) return [];
    final cacheKey = 'squad_$teamId';
    const dataType = 'squads';

    // Try cache first (7 day TTL for squads)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> players = cachedData['players'] ?? [];
        if (players.isNotEmpty) {
          return players.cast<Map<String, dynamic>>();
        }
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players/squads?team=$teamId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];
        if (responseList.isEmpty) return [];

        final List<dynamic> rawPlayers = responseList[0]['players'] ?? [];
        final players = rawPlayers.map<Map<String, dynamic>>((p) => {
          'name': p['name'] ?? '',
          'number': p['number'] ?? 0,
          'position': p['position'] ?? '',
          'photo': p['photo'] ?? '',
        }).toList();

        // Save to cache
        await _cacheService.saveToLocalCache(cacheKey, dataType, {'players': players});

        return players;
      }
    } catch (e) {
      // Try cached data on error
      final cachedData = await _cacheService.getFromCache(cacheKey, dataType);
      if (cachedData != null) {
        final List<dynamic> players = cachedData['players'] ?? [];
        return players.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }
}