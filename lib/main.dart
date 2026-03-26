import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trivia_screen.dart';
import 'screens/score_prediction_screen.dart';
import 'screens/city_finder_screen.dart';
import 'screens/guess_player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FalsoApp());
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