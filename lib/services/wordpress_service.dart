import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WordPressPost {
  final String title;
  final String content;
  final String excerpt;
  final String status; // 'draft', 'publish', 'pending'
  final List<String> categories;
  final List<String> tags;
  final String? featuredImageUrl;
  final Map<String, String> meta; // SEO meta tags

  WordPressPost({
    required this.title,
    required this.content,
    required this.excerpt,
    this.status = 'draft',
    this.categories = const [],
    this.tags = const [],
    this.featuredImageUrl,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'status': status,
      'categories': categories,
      'tags': tags,
      'meta': meta,
    };
  }
}

class WordPressService {
  final String _windlarUrl;
  final String _windlarUsername;
  final String _windlarPassword;
  
  final String _petsisUrl;
  final String _petsisUsername;
  final String _petsisPassword;

  WordPressService()
      : _windlarUrl = dotenv.get('WORDPRESS_WINDLAR_URL', fallback: ''),
        _windlarUsername = dotenv.get('WORDPRESS_WINDLAR_USERNAME', fallback: ''),
        _windlarPassword = dotenv.get('WORDPRESS_WINDLAR_PASSWORD', fallback: ''),
        _petsisUrl = dotenv.get('WORDPRESS_PETSIS_URL', fallback: ''),
        _petsisUsername = dotenv.get('WORDPRESS_PETSIS_USERNAME', fallback: ''),
        _petsisPassword = dotenv.get('WORDPRESS_PETSIS_PASSWORD', fallback: '') {
    _validateConfig();
  }

  void _validateConfig() {
    if (_windlarUrl.isEmpty || _windlarUsername.isEmpty || _windlarPassword.isEmpty) {
      print('Warning: Windlar WordPress configuration incomplete');
    }
    if (_petsisUrl.isEmpty || _petsisUsername.isEmpty || _petsisPassword.isEmpty) {
      print('Warning: Petsis WordPress configuration incomplete');
    }
  }

  // Create a basic auth header
  String _getBasicAuth(String username, String password) {
    final credentials = '$username:$password';
    final bytes = utf8.encode(credentials);
    final base64Str = base64.encode(bytes);
    return 'Basic $base64Str';
  }

  // Publish post to Windlar
  Future<Map<String, dynamic>> publishToWindlar(WordPressPost post) async {
    return await _publishPost(_windlarUrl, _windlarUsername, _windlarPassword, post);
  }

  // Publish post to Petsis
  Future<Map<String, dynamic>> publishToPetsis(WordPressPost post) async {
    return await _publishPost(_petsisUrl, _petsisUsername, _petsisPassword, post);
  }

  // Generic publish method
  Future<Map<String, dynamic>> _publishPost(
    String baseUrl,
    String username,
    String password,
    WordPressPost post,
  ) async {
    if (baseUrl.isEmpty) {
      return {'error': 'WordPress URL not configured', 'success': false};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': _getBasicAuth(username, password),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': post.title,
          'content': post.content,
          'excerpt': post.excerpt,
          'status': post.status,
          'categories': _getCategoryIds(baseUrl, username, password, post.categories),
          'tags': _getTagIds(baseUrl, username, password, post.tags),
          'meta': post.meta,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('WordPress post published successfully: ${data['id']}');
        return {
          'success': true,
          'id': data['id'],
          'link': data['link'],
          'title': data['title']['rendered'],
        };
      } else {
        print('WordPress publish failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('WordPress publish error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get or create category IDs
  List<int> _getCategoryIds(String baseUrl, String username, String password, List<String> categoryNames) {
    // For now, return empty list - implement category lookup if needed
    return [];
  }

  // Get or create tag IDs
  List<int> _getTagIds(String baseUrl, String username, String password, List<String> tagNames) {
    // For now, return empty list - implement tag lookup if needed
    return [];
  }

  // Upload media (featured image)
  Future<int?> uploadMedia(String baseUrl, String username, String password, String imageUrl) async {
    try {
      // Download image
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        print('Failed to download image: ${imageResponse.statusCode}');
        return null;
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/media'),
      );
      
      request.headers['Authorization'] = _getBasicAuth(username, password);
      
      // Add image file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageResponse.bodyBytes,
        filename: 'featured_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        print('Media upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Media upload error: $e');
      return null;
    }
  }

  // Get existing posts
  Future<List<Map<String, dynamic>>> getPosts(String baseUrl, String username, String password, {int perPage = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?per_page=$perPage'),
        headers: {
          'Authorization': _getBasicAuth(username, password),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Failed to get posts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Get posts error: $e');
      return [];
    }
  }

  // Update post status (draft -> publish)
  Future<bool> updatePostStatus(
    String baseUrl,
    String username,
    String password,
    int postId,
    String status,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': _getBasicAuth(username, password),
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update post status error: $e');
      return false;
    }
  }

  // Create SEO optimized post
  WordPressPost createSeoPost({
    required String title,
    required String content,
    required String site, // 'windlar' or 'petsis'
    String? featuredImageUrl,
  }) {
    final excerpt = content.length > 150 ? content.substring(0, 150) + '...' : content;
    
    // Determine categories and tags based on site
    final categories = site == 'windlar'
        ? ['Drone Teknolojisi', 'Enerji', 'Yenilenebilir Enerji']
        : ['İş Güvenliği', 'Personel Takip', 'Endüstri 4.0'];
    
    final tags = site == 'windlar'
        ? ['drone', 'rüzgar enerjisi', 'bakım', 'teknoloji']
        : ['güvenlik', 'takip', 'verimlilik', 'iot'];

    // Create SEO meta
    final meta = {
      '_yoast_wpseo_title': '$title | ${site == 'windlar' ? 'Windlar' : 'Petsis'}',
      '_yoast_wpseo_metadesc': excerpt,
      '_yoast_wpseo_focuskw': title.split(' ').take(3).join(' '),
    };

    return WordPressPost(
      title: title,
      content: content,
      excerpt: excerpt,
      status: 'draft', // Start as draft, publish after approval
      categories: categories,
      tags: tags,
      featuredImageUrl: featuredImageUrl,
      meta: meta,
    );
  }

  // Test connection
  Future<bool> testConnection(String site) async {
    final url = site == 'windlar' ? _windlarUrl : _petsisUrl;
    final username = site == 'windlar' ? _windlarUsername : _petsisUsername;
    final password = site == 'windlar' ? _windlarPassword : _petsisPassword;

    if (url.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse(url.replaceAll('/wp/v2', '')),
        headers: {
          'Authorization': _getBasicAuth(username, password),
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('WordPress connection test failed for $site: $e');
      return false;
    }
  }

  // Get service status
  Map<String, dynamic> getStatus() {
    return {
      'windlar_configured': _windlarUrl.isNotEmpty && _windlarUsername.isNotEmpty && _windlarPassword.isNotEmpty,
      'petsis_configured': _petsisUrl.isNotEmpty && _petsisUsername.isNotEmpty && _petsisPassword.isNotEmpty,
      'environment': dotenv.get('ENVIRONMENT', fallback: 'development'),
    };
  }
}