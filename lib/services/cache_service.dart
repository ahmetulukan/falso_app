import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cache_entry.dart';

class CacheService {
  static const String _cacheCollection = 'api_cache';
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  
  final FirebaseFirestore? _firestore;
  late SharedPreferences _prefs;

  CacheService([this._firestore]);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // Cache is preserved between sessions — expired entries are cleaned automatically
  }

  // Save to local cache (SharedPreferences for quick access)
  Future<void> saveToLocalCache(String key, String dataType, Map<String, dynamic> data) async {
    final entry = CacheEntry(
      id: key,
      dataType: dataType,
      data: data,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(_defaultCacheDuration),
    );

    await _prefs.setString(key, json.encode(entry.toJson()));
  }

  // Save to Firestore (for persistence and sync across devices)
  Future<void> saveToFirestoreCache(String key, String dataType, Map<String, dynamic> data) async {
    if (_firestore == null) return;
    
    try {
      final entry = CacheEntry(
        id: key,
        dataType: dataType,
        data: data,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_defaultCacheDuration),
      );

      final entryJson = entry.toJson();
      entryJson['cachedAt'] = Timestamp.fromDate(entry.cachedAt);
      entryJson['expiresAt'] = Timestamp.fromDate(entry.expiresAt);

      await _firestore!
          .collection(_cacheCollection)
          .doc(key)
          .set(entryJson);
    } catch (e) {
      // Firestore unavailable, skip silently
    }
  }

  // Get from cache (tries local first, then Firestore)
  Future<Map<String, dynamic>?> getFromCache(String key, String dataType) async {
    // Try local cache first
    final localData = _prefs.getString(key);
    if (localData != null) {
      try {
        final entry = CacheEntry.fromJson(json.decode(localData));
        if (entry.isValid && entry.dataType == dataType) {
          return entry.data;
        }
      } catch (e) {
        // ignore
      }
    }

    // Try Firestore cache
    if (_firestore != null) {
      try {
        final doc = await _firestore!
            .collection(_cacheCollection)
            .doc(key)
            .get();

        if (doc.exists) {
          final entry = CacheEntry.fromJson(doc.data() as Map<String, dynamic>);
          if (entry.isValid && entry.dataType == dataType) {
            await saveToLocalCache(key, dataType, entry.data);
            return entry.data;
          } else if (entry.isExpired) {
            await _firestore!.collection(_cacheCollection).doc(key).delete();
            _prefs.remove(key);
          }
        }
      } catch (e) {
        // Firestore unavailable, skip silently
      }
    }

    return null;
  }

  // Clear expired cache entries
  Future<void> cleanupExpiredCache() async {
    if (_firestore == null) return;
    try {
      final snapshot = await _firestore!
          .collection(_cacheCollection)
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final batch = _firestore!.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        _prefs.remove(doc.id);
      }

      await batch.commit();
    } catch (e) {
      // ignore
    }
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_firestore == null) {
      return {'total': 0, 'valid': 0, 'expired': 0, 'cleanup_needed': false};
    }
    
    try {
      final snapshot = await _firestore!.collection(_cacheCollection).get();
      int total = snapshot.docs.length;
      int expired = 0;
      int valid = 0;
      
      for (final doc in snapshot.docs) {
        try {
          final entry = CacheEntry.fromJson(doc.data() as Map<String, dynamic>);
          if (entry.isExpired) {
            expired++;
          } else {
            valid++;
          }
        } catch (e) {
          // ignore
        }
      }

      return {
        'total': total,
        'valid': valid,
        'expired': expired,
        'cleanup_needed': expired > 0,
      };
    } catch (e) {
      return {'total': 0, 'valid': 0, 'expired': 0, 'cleanup_needed': false};
    }
  }
}