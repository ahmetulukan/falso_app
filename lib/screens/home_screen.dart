import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: _currentIndex == 0
              ? _buildHome()
              : _currentIndex == 1
                  ? _buildGames()
                  : _currentIndex == 2
                      ? _buildLeaderboardPlaceholder()
                      : _buildProfilePlaceholder(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Oyunlar'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Sıralama'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Merhaba! 👋', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Falso Oyuncusu', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.bgCard,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(child: _miniStat(Icons.star, '0', 'Puan')),
              const SizedBox(width: 12),
              Expanded(child: _miniStat(Icons.local_fire_department, '0', 'Seri')),
              const SizedBox(width: 12),
              Expanded(child: _miniStat(Icons.emoji_events, '-', 'Sıralama')),
            ],
          ),
          const SizedBox(height: 28),

          // Hemen Oyna button
          GradientButton(
            text: '🎮  HEMEN OYNA',
            onTap: () => Navigator.pushNamed(context, '/trivia'),
            gradient: AppColors.primaryGradient,
          ),
          const SizedBox(height: 28),

          // Kategoriler başlığı
          const Text('Oyun Kategorileri', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Kategori kartları
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: [
              CategoryCard(
                title: 'Futbol Trivia',
                subtitle: 'Bilgini test et!',
                icon: Icons.quiz_rounded,
                gradient: AppColors.primaryGradient,
                onTap: () => Navigator.pushNamed(context, '/trivia'),
              ),
              CategoryCard(
                title: 'Skor Tahmini',
                subtitle: 'Günlük maçlar',
                icon: Icons.scoreboard_rounded,
                gradient: AppColors.orangeGradient,
                onTap: () => Navigator.pushNamed(context, '/score_prediction'),
              ),
              CategoryCard(
                title: 'Şehir Bul',
                subtitle: 'Hangi şehirden?',
                icon: Icons.location_city_rounded,
                gradient: AppColors.blueGradient,
                onTap: () => Navigator.pushNamed(context, '/city_finder'),
              ),
              CategoryCard(
                title: 'Kim Bu?',
                subtitle: 'Futbolcuyu tahmin et',
                icon: Icons.person_search_rounded,
                gradient: AppColors.greenGradient,
                onTap: () => Navigator.pushNamed(context, '/guess_player'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGames() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Tüm Oyunlar', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _gameListTile(Icons.quiz_rounded, 'Futbol Trivia', '15 soru hazır', AppColors.primaryPurple, '/trivia'),
          _gameListTile(Icons.scoreboard_rounded, 'Skor Tahmini', 'Günlük maçları tahmin et', AppColors.primaryOrange, '/score_prediction'),
          _gameListTile(Icons.location_city_rounded, 'Şehir Bul', '12 takım, 12 şehir', AppColors.categoryBlue, '/city_finder'),
          _gameListTile(Icons.person_search_rounded, 'Kim Bu Futbolcu?', '8 yıldız futbolcu', AppColors.categoryGreen, '/guess_player'),
        ],
      ),
    );
  }

  Widget _gameListTile(IconData icon, String title, String subtitle, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.cardBox(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPlaceholder() {
    return const Center(child: Text('Sıralama - Yakında!', style: TextStyle(color: Colors.white, fontSize: 20)));
  }

  Widget _buildProfilePlaceholder() {
    return const Center(child: Text('Profil - Yakında!', style: TextStyle(color: Colors.white, fontSize: 20)));
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: AppDecorations.glassBox(),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textAccent, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }
}