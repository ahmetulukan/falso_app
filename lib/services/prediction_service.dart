import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match.dart';

class PredictionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  PredictionService(this._firestore, this._auth);
  
  // Save user's score prediction
  Future<void> saveScorePrediction({
    required String matchId,
    required int homeScore,
    required int awayScore,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    
    await _firestore.collection('predictions').add({
      'userId': uid,
      'matchId': matchId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'score_prediction',
      'status': 'pending', // pending, correct, incorrect
      'pointsAwarded': 0,
    });
  }
  
  // Save user's first 11 prediction
  Future<void> saveFirst11Prediction({
    required String matchId,
    required List<String> playerIds,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    
    await _firestore.collection('predictions').add({
      'userId': uid,
      'matchId': matchId,
      'predictedPlayers': playerIds,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'first11_prediction',
      'status': 'pending',
      'pointsAwarded': 0,
    });
  }
  
  // Verify predictions against actual match results
  Future<void> verifyPredictions(Match actualMatch) async {
    final matchId = actualMatch.id;
    final actualHomeScore = actualMatch.homeScore;
    final actualAwayScore = actualMatch.awayScore;
    
    // Get all pending predictions for this match
    final predictionsSnapshot = await _firestore
        .collection('predictions')
        .where('matchId', isEqualTo: matchId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    final batch = _firestore.batch();
    
    for (final doc in predictionsSnapshot.docs) {
      final data = doc.data();
      final predictionType = data['type'] as String?;
      
      if (predictionType == 'score_prediction') {
        final predictedHomeScore = data['homeScore'] as int? ?? 0;
        final predictedAwayScore = data['awayScore'] as int? ?? 0;
        
        final isCorrect = predictedHomeScore == actualHomeScore && 
                         predictedAwayScore == actualAwayScore;
        
        final points = calculateScorePredictionPoints(
          isCorrect: isCorrect,
          homeScore: actualHomeScore,
          awayScore: actualAwayScore,
          predictedHomeScore: predictedHomeScore,
          predictedAwayScore: predictedAwayScore,
        );
        
        // Update prediction status
        batch.update(doc.reference, {
          'status': isCorrect ? 'correct' : 'incorrect',
          'pointsAwarded': points,
          'verifiedAt': FieldValue.serverTimestamp(),
          'actualHomeScore': actualHomeScore,
          'actualAwayScore': actualAwayScore,
        });
        
        // Update user's total points if points > 0
        if (points > 0) {
          await _updateUserPoints(data['userId'] as String, points);
        }
        
      } else if (predictionType == 'first11_prediction') {
        // TODO: Implement first11 verification when we have actual lineup data
        // For now, mark as pending verification
        batch.update(doc.reference, {
          'status': 'needs_lineup_data',
          'verifiedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    await batch.commit();
  }
  
  // Calculate points for score prediction
  int calculateScorePredictionPoints({
    required bool isCorrect,
    required int homeScore,
    required int awayScore,
    required int predictedHomeScore,
    required int predictedAwayScore,
  }) {
    if (isCorrect) {
      // Exact score prediction: 50 points
      return 50;
    }
    
    // Calculate goal difference accuracy
    final actualDiff = homeScore - awayScore;
    final predictedDiff = predictedHomeScore - predictedAwayScore;
    
    if (actualDiff == predictedDiff) {
      // Correct goal difference: 25 points
      return 25;
    }
    
    // Check if predicted correct winner/draw
    final actualResult = _getMatchResult(homeScore, awayScore);
    final predictedResult = _getMatchResult(predictedHomeScore, predictedAwayScore);
    
    if (actualResult == predictedResult) {
      // Correct result (win/draw): 10 points
      return 10;
    }
    
    // Incorrect prediction: 0 points
    return 0;
  }
  
  String _getMatchResult(int homeScore, int awayScore) {
    if (homeScore > awayScore) return 'home_win';
    if (homeScore < awayScore) return 'away_win';
    return 'draw';
  }
  
  // Update user's total points
  Future<void> _updateUserPoints(String userId, int points) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      
      if (userDoc.exists) {
        final currentPoints = userDoc.data()?['totalPoints'] as int? ?? 0;
        transaction.update(userRef, {
          'totalPoints': currentPoints + points,
          'lastPointsUpdate': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(userRef, {
          'totalPoints': points,
          'lastPointsUpdate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  
  // Get user's prediction history
  Future<QuerySnapshot> getUserPredictions(String userId) async {
    return await _firestore
        .collection('predictions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
  }
  
  // Get user's prediction statistics
  Future<Map<String, dynamic>> getUserPredictionStats(String userId) async {
    final predictions = await getUserPredictions(userId);
    
    int total = 0;
    int correct = 0;
    int incorrect = 0;
    int pending = 0;
    int totalPoints = 0;
    
    for (final doc in predictions.docs) {
      total++;
      final status = doc.data()['status'] as String? ?? 'pending';
      final points = doc.data()['pointsAwarded'] as int? ?? 0;
      
      switch (status) {
        case 'correct':
          correct++;
          totalPoints += points;
          break;
        case 'incorrect':
          incorrect++;
          break;
        default:
          pending++;
      }
    }
    
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;
    
    return {
      'totalPredictions': total,
      'correctPredictions': correct,
      'incorrectPredictions': incorrect,
      'pendingPredictions': pending,
      'accuracyPercentage': accuracy,
      'totalPoints': totalPoints,
      'averagePoints': total > 0 ? (totalPoints / total).round() : 0,
    };
  }
  
  // Get leaderboard
  Future<QuerySnapshot> getLeaderboard({int limit = 100}) async {
    return await _firestore
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();
  }
  
  // Get matches that need verification (finished matches with pending predictions)
  Future<QuerySnapshot> getMatchesNeedingVerification() async {
    // This would query matches that have ended but predictions are still pending
    // For now, return empty - this needs integration with match scheduling
    return await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'finished')
        .limit(10)
        .get();
  }
}