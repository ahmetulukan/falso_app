import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TrelloCard {
  final String name;
  final String desc;
  final String idList;
  final List<String> idLabels;
  final DateTime? due;
  final int? pos;
  final Map<String, dynamic> customFields;

  TrelloCard({
    required this.name,
    required this.desc,
    required this.idList,
    this.idLabels = const [],
    this.due,
    this.pos,
    this.customFields = const {},
  });

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'desc': desc,
      'idList': idList,
      'idLabels': idLabels.join(','),
    };

    if (due != null) {
      json['due'] = due!.toIso8601String();
    }

    if (pos != null) {
      json['pos'] = pos;
    }

    return json;
  }
}

class TrelloService {
  static const String _apiBaseUrl = 'https://api.trello.com/1';
  final String _apiKey;
  final String _token;

  TrelloService()
      : _apiKey = dotenv.get('TRELLO_API_KEY', fallback: ''),
        _token = dotenv.get('TRELLO_TOKEN', fallback: '') {
    _validateConfig();
  }

  void _validateConfig() {
    if (_apiKey.isEmpty) {
      print('Warning: Trello API key not configured');
    }
    if (_token.isEmpty) {
      print('Warning: Trello token not configured');
    }
  }

  // Get query parameters for Trello API
  Map<String, String> _getQueryParams() {
    return {
      'key': _apiKey,
      'token': _token,
    };
  }

  // Create a new card
  Future<Map<String, dynamic>> createCard(TrelloCard card) async {
    if (_apiKey.isEmpty || _token.isEmpty) {
      return {'error': 'Trello not configured', 'success': false};
    }

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/cards').replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(card.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Trello card created: ${data['id']}');
        return {
          'success': true,
          'id': data['id'],
          'url': data['url'],
          'name': data['name'],
        };
      } else {
        print('Trello create failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Trello create error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create daily task card
  Future<Map<String, dynamic>> createDailyTask({
    required String title,
    required String description,
    required String listId, // 'To Do', 'Doing', 'Done'
    required List<String> labels, // 'blog', 'youtube', 'development', 'health'
    DateTime? dueDate,
    Map<String, dynamic>? customFields,
  }) async {
    final card = TrelloCard(
      name: title,
      desc: description,
      idList: listId,
      idLabels: labels,
      due: dueDate,
      customFields: customFields ?? {},
    );

    return await createCard(card);
  }

  // Create blog task card
  Future<Map<String, dynamic>> createBlogTask({
    required String site, // 'windlar' or 'petsis'
    required String title,
    required String contentSummary,
    required DateTime publishDate,
    required List<String> keywords,
  }) async {
    final description = '''
**Site:** ${site == 'windlar' ? 'Windlar' : 'Petsis'}
**Publish Date:** ${publishDate.toIso8601String().split('T')[0]}
**Status:** Draft
**WordPress ID:** Pending

**Keywords:**
${keywords.map((k) => '- $k').join('\n')}

**Content Summary:**
$contentSummary

**Tasks:**
- [ ] Write SEO optimized content
- [ ] Add featured image
- [ ] Set categories and tags
- [ ] Add meta description
- [ ] Publish to WordPress
- [ ] Share on social media
''';

    return await createDailyTask(
      title: '📝 ${site == 'windlar' ? 'Windlar' : 'Petsis'} Blog: $title',
      description: description,
      listId: _getListId('To Do'), // Need to get actual list IDs
      labels: ['blog', site],
      dueDate: publishDate,
      customFields: {
        'site': site,
        'type': 'blog',
        'wordpress_status': 'draft',
        'seo_score': 0,
      },
    );
  }

  // Create YouTube task card
  Future<Map<String, dynamic>> createYouTubeTask({
    required String title,
    required String topic,
    required String description,
    required DateTime recordingDate,
    required DateTime editingDate,
    required DateTime publishDate,
    required List<String> keyPoints,
  }) async {
    final taskDescription = '''
**Topic:** $topic
**Recording Date:** ${recordingDate.toIso8601String().split('T')[0]}
**Editing Date:** ${editingDate.toIso8601String().split('T')[0]}
**Publish Date:** ${publishDate.toIso8601String().split('T')[0]}

**Description:**
$description

**Key Points:**
${keyPoints.map((p) => '- $p').join('\n')}

**Tasks:**
- [ ] Script writing
- [ ] Equipment setup
- [ ] Recording
- [ ] Video editing
- [ ] Thumbnail design
- [ ] SEO optimization
- [ ] YouTube upload
- [ ] Social media promotion
''';

    return await createDailyTask(
      title: '🎥 YouTube: $title',
      description: taskDescription,
      listId: _getListId('To Do'),
      labels: ['youtube', 'content'],
      dueDate: publishDate,
      customFields: {
        'type': 'youtube',
        'recording_date': recordingDate.toIso8601String(),
        'editing_date': editingDate.toIso8601String(),
        'publish_date': publishDate.toIso8601String(),
      },
    );
  }

  // Create health/medication reminder card
  Future<Map<String, dynamic>> createHealthReminder({
    required String medication,
    required String dosage,
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
    required String instructions,
  }) async {
    final description = '''
**Medication:** $medication
**Dosage:** $dosage
**Frequency:** $frequency
**Start Date:** ${startDate.toIso8601String().split('T')[0]}
**End Date:** ${endDate.toIso8601String().split('T')[0]}

**Instructions:**
$instructions

**Schedule:**
- [ ] Morning
- [ ] Afternoon  
- [ ] Evening
- [ ] Night

**Notes:**
- Take with food
- Avoid alcohol
- Store at room temperature
''';

    return await createDailyTask(
      title: '💊 $medication Reminder',
      description: description,
      listId: _getListId('To Do'),
      labels: ['health', 'medication'],
      dueDate: endDate,
      customFields: {
        'type': 'health',
        'medication': medication,
        'dosage': dosage,
        'frequency': frequency,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
  }

  // Create workout/exercise card
  Future<Map<String, dynamic>> createWorkoutTask({
    required String type, // 'running', 'weight', 'yoga', etc.
    required String workoutPlan,
    required DateTime date,
    required Map<String, dynamic> details,
  }) async {
    final description = '''
**Workout Type:** $type
**Date:** ${date.toIso8601String().split('T')[0]}

**Plan:**
$workoutPlan

**Details:**
${details.entries.map((e) => '- **${e.key}:** ${e.value}').join('\n')}

**Progress:**
- [ ] Warm-up
- [ ] Main workout
- [ ] Cool-down
- [ ] Stretching
- [ ] Hydration
- [ ] Nutrition

**Notes:**
- Listen to your body
- Maintain proper form
- Track your progress
''';

    return await createDailyTask(
      title: '🏃 ${type == 'running' ? 'Run' : 'Workout'}: ${details['distance'] ?? details['focus'] ?? ''}',
      description: description,
      listId: _getListId('To Do'),
      labels: ['health', 'fitness', type],
      dueDate: date,
      customFields: {
        'type': 'workout',
        'workout_type': type,
        'date': date.toIso8601String(),
        ...details,
      },
    );
  }

  // Get boards (need to implement based on your Trello setup)
  Future<List<Map<String, dynamic>>> getBoards() async {
    if (_apiKey.isEmpty || _token.isEmpty) {
      return [];
    }

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/members/me/boards').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).cast<Map<String, dynamic>>();
      } else {
        print('Trello get boards failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Trello get boards error: $e');
      return [];
    }
  }

  // Get lists from a board
  Future<List<Map<String, dynamic>>> getLists(String boardId) async {
    if (_apiKey.isEmpty || _token.isEmpty) {
      return [];
    }

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/boards/$boardId/lists').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).cast<Map<String, dynamic>>();
      } else {
        print('Trello get lists failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Trello get lists error: $e');
      return [];
    }
  }

  // Get labels from a board
  Future<List<Map<String, dynamic>>> getLabels(String boardId) async {
    if (_apiKey.isEmpty || _token.isEmpty) {
      return [];
    }

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/boards/$boardId/labels').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).cast<Map<String, dynamic>>();
      } else {
        print('Trello get labels failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Trello get labels error: $e');
      return [];
    }
  }

  // Update card status (move to different list)
  Future<bool> updateCardList(String cardId, String listId) async {
    if (_apiKey.isEmpty || _token.isEmpty) return false;

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/cards/$cardId').replace(queryParameters: {
        ...queryParams,
        'idList': listId,
      });

      final response = await http.put(uri);

      return response.statusCode == 200;
    } catch (e) {
      print('Trello update card error: $e');
      return false;
    }
  }

  // Add comment to card
  Future<bool> addComment(String cardId, String comment) async {
    if (_apiKey.isEmpty || _token.isEmpty) return false;

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/cards/$cardId/actions/comments').replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': comment}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Trello add comment error: $e');
      return false;
    }
  }

  // Helper method to get list ID (you need to configure this based on your Trello)
  String _getListId(String listName) {
    // This should be configured based on your Trello board
    // For now, return empty - you need to set up your Trello board first
    final listIds = {
      'To Do': '',
      'Doing': '',
      'Done': '',
      'Blog Queue': '',
      'YouTube Pipeline': '',
      'Health Tracking': '',
    };

    return listIds[listName] ?? '';
  }

  // Test connection
  Future<bool> testConnection() async {
    if (_apiKey.isEmpty || _token.isEmpty) return false;

    try {
      final queryParams = _getQueryParams();
      final uri = Uri.parse('$_apiBaseUrl/members/me').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      return response.statusCode == 200;
    } catch (e) {
      print('Trello connection test failed: $e');
      return false;
    }
  }

  // Get service status
  Map<String, dynamic> getStatus() {
    return {
      'api_key_configured': _apiKey.isNotEmpty,
      'token_configured': _token.isNotEmpty,
      'needs_setup': _getListId('To Do').isEmpty,
    };
  }
}