import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      // print('Sign in error: $e');
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      // print('Sign up error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> saveUserPrediction(
    String userId,
    String matchId,
    int homeScore,
    int awayScore,
  ) async {
    await _firestore.collection('predictions').add({
      'userId': userId,
      'matchId': matchId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> getUserPredictions(String userId) async {
    return await _firestore
        .collection('predictions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<QuerySnapshot> getLeaderboard() async {
    return await _firestore
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(100)
        .get();
  }
}