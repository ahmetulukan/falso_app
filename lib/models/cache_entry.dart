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
    return CacheEntry(
      id: json['id'],
      dataType: json['dataType'],
      data: json['data'],
      cachedAt: (json['cachedAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataType': dataType,
      'data': data,
      'cachedAt': Timestamp.fromDate(cachedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isValid => !isExpired;
}