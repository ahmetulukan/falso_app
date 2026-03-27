import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trivia_screen.dart';
import 'screens/score_prediction_screen.dart';
import 'screens/city_finder_screen.dart';
import 'screens/guess_player_screen.dart';
import 'services/cache_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  
  // Initialize cache service
  final cacheService = CacheService(FirebaseFirestore.instance);
  await cacheService.initialize();
  
  // Initialize API service with cache
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
        '/home': (context) => const HomeScreen(),
        '/trivia': (context) => const TriviaScreen(),
        '/score_prediction': (context) => const ScorePredictionScreen(),
        '/city_finder': (context) => const CityFinderScreen(),
        '/guess_player': (context) => const GuessPlayerScreen(),
      },
    );
  }
}

class FalsoApp extends StatelessWidget {
  const FalsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Falso ⚽',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/trivia': (context) => const TriviaScreen(),
        '/score_prediction': (context) => const ScorePredictionScreen(),
        '/city_finder': (context) => const CityFinderScreen(),
        '/guess_player': (context) => const GuessPlayerScreen(),
      },
    );
  }
}