import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trivia_screen.dart';
import 'screens/score_prediction_screen.dart';
import 'screens/city_finder_screen.dart';
import 'screens/guess_player_screen.dart';
import 'screens/transfer_chain_screen.dart';
import 'screens/lineup_prediction_screen.dart';
import 'screens/mini_football_game_screen.dart';
import 'screens/penalty_game_screen.dart';
import 'screens/juggling_game_screen.dart';
import 'screens/auth_screen.dart';
import 'services/cache_service.dart';
import 'services/api_service.dart';
import 'services/game_state_service.dart';
import 'services/ad_service.dart';
import 'services/custom_ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // debugPrint('dotenv load failed: $e');
  }
  
  // Initialize cache service in local-only mode first (always works)
  final cacheService = CacheService();
  await cacheService.initialize();
  
  // Try to initialize Firebase (non-blocking — app works without it)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // debugPrint('Firebase initialized successfully');
  } catch (e) {
    // debugPrint('Firebase unavailable, running in offline mode: $e');
  }
  
  // Initialize Google Mobile Ads SDK (non-blocking)
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    // debugPrint('AdMob init failed: $e');
  }
  
  // Initialize custom ad service (brand banners)
  final customAdService = CustomAdService();
  try { await customAdService.initialize(); } catch (_) {}
  
  // Initialize game state (auth, streak, badges)
  try { await GameStateService.getInstance(); } catch (_) {}
  
  // Initialize API service
  final apiService = ApiService(cacheService);
  
  runApp(FalsoApp(
    cacheService: cacheService,
    apiService: apiService,
  ));
}

class FalsoApp extends StatelessWidget {
  final CacheService cacheService;
  final ApiService apiService;
  
  const FalsoApp({
    super.key,
    required this.cacheService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Falso ⚽',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/trivia': (context) => const TriviaScreen(),
        '/score_prediction': (context) => ScorePredictionScreen(apiService: apiService),
        '/city_finder': (context) => const CityFinderScreen(),
        '/guess_player': (context) => const GuessPlayerScreen(),
        '/transfer_chain': (context) => const TransferChainScreen(),
        '/lineup_prediction': (context) => LineupPredictionScreen(apiService: apiService),
        '/mini_football': (context) => const MiniFootballGameScreen(),
        '/penalty': (context) => const PenaltyGameScreen(),
        '/juggling': (context) => const JugglingGameScreen(),
      },
    );
  }
}