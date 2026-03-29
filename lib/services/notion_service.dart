import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotionPage {
  final String title;
  final Map<String, dynamic> properties;
  final List<Map<String, dynamic>> children; // Notion blocks
  final String? parentDatabaseId;
  final String? parentPageId;

  NotionPage({
    required this.title,
    required this.properties,
    this.children = const [],
    this.parentDatabaseId,
    this.parentPageId,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'properties': {
        'Name': {
          'title': [
            {
              'text': {
                'content': title,
              },
            },
          ],
        },
        ...properties,
      },
    };

    if (children.isNotEmpty) {
      json['children'] = children;
    }

    if (parentDatabaseId != null) {
      json['parent'] = {
        'database_id': parentDatabaseId,
      };
    } else if (parentPageId != null) {
      json['parent'] = {
        'page_id': parentPageId,
      };
    }

    return json;
  }
}

class NotionService {
  static const String _apiBaseUrl = 'https://api.notion.com/v1';
  final String _apiKey;
  final String _databaseId;

  NotionService()
      : _apiKey = dotenv.get('NOTION_API_KEY', fallback: ''),
        _databaseId = dotenv.get('NOTION_DATABASE_ID', fallback: '') {
    _validateConfig();
  }

  void _validateConfig() {
    if (_apiKey.isEmpty) {
      print('Warning: Notion API key not configured');
    }
    if (_databaseId.isEmpty) {
      print('Warning: Notion database ID not configured');
    }
  }

  // Get headers for Notion API
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_apiKey',
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
    };
  }

  // Create a new page in Dinko Merkezi database
  Future<Map<String, dynamic>> createDailyLog({
    required String title,
    required String date,
    required Map<String, dynamic> content,
  }) async {
    if (_apiKey.isEmpty || _databaseId.isEmpty) {
      return {'error': 'Notion not configured', 'success': false};
    }

    try {
      final page = NotionPage(
        title: title,
        parentDatabaseId: _databaseId,
        properties: {
          'Date': {
            'date': {
              'start': date,
            },
          },
          'Status': {
            'select': {
              'name': '📝 Draft',
            },
          },
          'Type': {
            'select': {
              'name': 'Daily Log',
            },
          },
        },
        children: _convertContentToBlocks(content),
      );

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/pages'),
        headers: _getHeaders(),
        body: json.encode(page.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Notion page created: ${data['id']}');
        return {
          'success': true,
          'id': data['id'],
          'url': data['url'],
          'title': title,
        };
      } else {
        print('Notion create failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Notion create error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Convert content map to Notion blocks
  List<Map<String, dynamic>> _convertContentToBlocks(Map<String, dynamic> content) {
    final blocks = <Map<String, dynamic>>[];

    content.forEach((sectionTitle, sectionContent) {
      // Add heading for section
      blocks.add({
        'object': 'block',
        'type': 'heading_2',
        'heading_2': {
          'rich_text': [
            {
              'type': 'text',
              'text': {
                'content': sectionTitle,
              },
              'annotations': {
                'bold': true,
              },
            },
          ],
        },
      });

      // Add content based on type
      if (sectionContent is String) {
        blocks.add({
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {
                  'content': sectionContent,
                },
              },
            ],
          },
        });
      } else if (sectionContent is List) {
        for (final item in sectionContent) {
          blocks.add({
            'object': 'block',
            'type': 'bulleted_list_item',
            'bulleted_list_item': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': item.toString(),
                  },
                },
              ],
            },
          });
        }
      } else if (sectionContent is Map) {
        // Handle nested content
        sectionContent.forEach((key, value) {
          blocks.add({
            'object': 'block',
            'type': 'paragraph',
            'paragraph': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': '$key: $value',
                  },
                },
              ],
            },
          });
        });
      }
    });

    return blocks;
  }

  // Create blog content draft in Notion
  Future<Map<String, dynamic>> createBlogDraft({
    required String title,
    required String content,
    required String site, // 'windlar' or 'petsis'
    required List<String> keywords,
    required String targetAudience,
  }) async {
    if (_apiKey.isEmpty || _databaseId.isEmpty) {
      return {'error': 'Notion not configured', 'success': false};
    }

    try {
      final page = NotionPage(
        title: '📝 $title',
        parentDatabaseId: _databaseId,
        properties: {
          'Date': {
            'date': {
              'start': DateTime.now().toIso8601String().split('T')[0],
            },
          },
          'Status': {
            'select': {
              'name': '✍️ Writing',
            },
          },
          'Type': {
            'select': {
              'name': 'Blog Content',
            },
          },
          'Site': {
            'select': {
              'name': site == 'windlar' ? 'Windlar' : 'Petsis',
            },
          },
          'Keywords': {
            'multi_select': keywords.map((keyword) => {'name': keyword}).toList(),
          },
          'Target Audience': {
            'rich_text': [
              {
                'type': 'text',
                'text': {
                  'content': targetAudience,
                },
              },
            ],
          },
        },
        children: [
          {
            'object': 'block',
            'type': 'paragraph',
            'paragraph': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': content,
                  },
                },
              ],
            },
          },
        ],
      );

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/pages'),
        headers: _getHeaders(),
        body: json.encode(page.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'id': data['id'],
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create YouTube content plan
  Future<Map<String, dynamic>> createYouTubePlan({
    required String title,
    required String topic,
    required String description,
    required List<String> keyPoints,
    required DateTime recordingDate,
    required DateTime editingDate,
    required DateTime publishDate,
  }) async {
    if (_apiKey.isEmpty || _databaseId.isEmpty) {
      return {'error': 'Notion not configured', 'success': false};
    }

    try {
      final page = NotionPage(
        title: '🎥 $title',
        parentDatabaseId: _databaseId,
        properties: {
          'Date': {
            'date': {
              'start': DateTime.now().toIso8601String().split('T')[0],
            },
          },
          'Status': {
            'select': {
              'name': '📅 Planned',
            },
          },
          'Type': {
            'select': {
              'name': 'YouTube Content',
            },
          },
          'Topic': {
            'select': {
              'name': topic,
            },
          },
          'Recording Date': {
            'date': {
              'start': recordingDate.toIso8601String().split('T')[0],
            },
          },
          'Editing Date': {
            'date': {
              'start': editingDate.toIso8601String().split('T')[0],
            },
          },
          'Publish Date': {
            'date': {
              'start': publishDate.toIso8601String().split('T')[0],
            },
          },
        },
        children: [
          {
            'object': 'block',
            'type': 'heading_2',
            'heading_2': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': 'Description',
                  },
                },
              ],
            },
          },
          {
            'object': 'block',
            'type': 'paragraph',
            'paragraph': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': description,
                  },
                },
              ],
            },
          },
          {
            'object': 'block',
            'type': 'heading_2',
            'heading_2': {
              'rich_text': [
                {
                  'type': 'text',
                  'text': {
                    'content': 'Key Points',
                  },
                },
              ],
            },
          },
          ...keyPoints.map((point) => {
                'object': 'block',
                'type': 'bulleted_list_item',
                'bulleted_list_item': {
                  'rich_text': [
                    {
                      'type': 'text',
                      'text': {
                        'content': point,
                      },
                    },
                  ],
                },
              }).toList(),
        ],
      );

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/pages'),
        headers: _getHeaders(),
        body: json.encode(page.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'id': data['id'],
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Query database for daily logs
  Future<List<Map<String, dynamic>>> queryDailyLogs({int pageSize = 10}) async {
    if (_apiKey.isEmpty || _databaseId.isEmpty) {
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/databases/$_databaseId/query'),
        headers: _getHeaders(),
        body: json.encode({
          'filter': {
            'property': 'Type',
            'select': {
              'equals': 'Daily Log',
            },
          },
          'sorts': [
            {
              'property': 'Date',
              'direction': 'descending',
            },
          ],
          'page_size': pageSize,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List).cast<Map<String, dynamic>>();
      } else {
        print('Notion query failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Notion query error: $e');
      return [];
    }
  }

  // Update page status
  Future<bool> updatePageStatus(String pageId, String status) async {
    if (_apiKey.isEmpty) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/pages/$pageId'),
        headers: _getHeaders(),
        body: json.encode({
          'properties': {
            'Status': {
              'select': {
                'name': status,
              },
            },
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Notion update error: $e');
      return false;
    }
  }

  // Test connection
  Future<bool> testConnection() async {
    if (_apiKey.isEmpty || _databaseId.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/databases/$_databaseId'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Notion connection test failed: $e');
      return false;
    }
  }

  // Get service status
  Map<String, dynamic> getStatus() {
    return {
      'api_key_configured': _apiKey.isNotEmpty,
      'database_id_configured': _databaseId.isNotEmpty,
      'database_url': 'https://www.notion.so/$_databaseId',
    };
  }
}