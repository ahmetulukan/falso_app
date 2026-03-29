import 'package:cloud_firestore/cloud_firestore.dart';

class CacheEntry {
  final String id;
  final String dataType; // 'matches', 'players', 'teams', etc.
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final DateTime expiresAt;

  CacheEntry({
    required this.id,
    required this.dataType,
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }
    
    return CacheEntry(
      id: json['id'],
      dataType: json['dataType'],
      data: json['data'],
      cachedAt: parseDate(json['cachedAt']),
      expiresAt: parseDate(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataType': dataType,
      'data': data,
      'cachedAt': cachedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isValid => !isExpired;
}