import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  NotificationService(this._messaging, this._firestore, this._auth);
  
  // Initialize notifications
  Future<void> initialize() async {
    // Request permission (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('Notification permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveDeviceToken(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveDeviceToken);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      // You can show a local notification here
    });
    
    // Handle when app is opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    
    // Handle when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
  
  // Save device token to Firestore
  Future<void> _saveDeviceToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore
        .collection('user_devices')
        .doc(userId)
        .set({
          'tokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    
    print('Device token saved for user $userId');
  }
  
  // Send prediction success notification
  Future<void> sendPredictionSuccessNotification({
    required String userId,
    required String matchId,
    required int pointsAwarded,
    required String predictionType,
  }) async {
    // Get user's device tokens
    final userDevicesDoc = await _firestore
        .collection('user_devices')
        .doc(userId)
        .get();
    
    final tokens = (userDevicesDoc.data()?['tokens'] as List<dynamic>?)?.cast<String>() ?? [];
    
    if (tokens.isEmpty) return;
    
    // Create notification payload
    final title = predictionType == 'score_prediction' 
        ? '🎯 Skor Tahminin Tuttu!' 
        : '👏 İlk 11 Tahminin Doğru!';
    
    final body = predictionType == 'score_prediction'
        ? '$pointsAwarded Falso Puan kazandın!'
        : 'Tebrikler, $pointsAwarded puan kazandın!';
    
    // In production, you would use Firebase Cloud Functions or a server
    // to send notifications. For now, we'll just log it.
    print('Would send notification to $userId: $title - $body');
    print('Device tokens: $tokens');
    
    // Save notification to Firestore for history
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': 'prediction_success',
      'matchId': matchId,
      'pointsAwarded': pointsAwarded,
      'predictionType': predictionType,
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  
  // Send daily match reminder
  Future<void> sendDailyMatchReminder({
    required String userId,
    required List<String> matchTitles,
  }) async {
    final userDevicesDoc = await _firestore
        .collection('user_devices')
        .doc(userId)
        .get();
    
    final tokens = (userDevicesDoc.data()?['tokens'] as List<dynamic>?)?.cast<String>() ?? [];
    
    if (tokens.isEmpty) return;
    
    final matchCount = matchTitles.length;
    final title = '⚽ Bugün $matchCount Maç Var!';
    final body = matchCount > 3 
        ? '${matchTitles.take(3).join(', ')} ve ${matchCount - 3} maç daha...'
        : matchTitles.join(', ');
    
    print('Would send daily reminder to $userId: $title - $body');
    
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': 'daily_reminder',
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  
  // Send streak notification
  Future<void> sendStreakNotification({
    required String userId,
    required int streakDays,
    required String badgeName,
  }) async {
    final userDevicesDoc = await _firestore
        .collection('user_devices')
        .doc(userId)
        .get();
    
    final tokens = (userDevicesDoc.data()?['tokens'] as List<dynamic>?)?.cast<String>() ?? [];
    
    if (tokens.isEmpty) return;
    
    final title = streakDays >= 7 
        ? '🔥 $streakDays Günlük Kombo!' 
        : '👍 $streakDays Gün Üst Üste!';
    
    final body = badgeName.isNotEmpty
        ? 'Tebrikler, "$badgeName" rozetini kazandın!'
        : 'Harika gidiyorsun, devam et!';
    
    print('Would send streak notification to $userId: $title - $body');
    
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': 'streak_notification',
      'streakDays': streakDays,
      'badgeName': badgeName,
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  
  // Send promotional notification (for new features, etc.)
  Future<void> sendPromotionalNotification({
    required String title,
    required String body,
    required String featureName,
  }) async {
    // Get all users with device tokens
    final usersSnapshot = await _firestore
        .collection('user_devices')
        .get();
    
    for (final doc in usersSnapshot.docs) {
      final userId = doc.id;
      final tokens = (doc.data()['tokens'] as List<dynamic>?)?.cast<String>() ?? [];
      
      if (tokens.isNotEmpty) {
        print('Would send promotional notification to $userId: $title');
        
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'type': 'promotional',
          'featureName': featureName,
          'sentAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    }
  }
  
  // Get user's notifications
  Future<QuerySnapshot> getUserNotifications(String userId, {int limit = 20}) async {
    return await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .get();
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final notifications = await getUserNotifications(userId, limit: 100);
    
    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }
  
  // Handle incoming message
  void _handleMessage(RemoteMessage message) {
    print('Message opened: ${message.notification?.title}');
    
    // Navigate to appropriate screen based on message data
    final data = message.data;
    if (data['type'] == 'prediction_success') {
      // Navigate to predictions screen
      print('Navigate to predictions screen');
    } else if (data['type'] == 'daily_reminder') {
      // Navigate to home screen
      print('Navigate to home screen');
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
  // You can show a local notification here
}