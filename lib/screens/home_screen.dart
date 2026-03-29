import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/firebase_service.dart';
import '../services/question_service.dart';
import '../services/game_state_service.dart';

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
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildHome()
            : _currentIndex == 1
                ? _buildGames()
                : _currentIndex == 2
                    ? _buildLeaderboard()
                    : _buildProfilePlaceholder(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
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
                  const Text('Falso Oyuncusu', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.bgCard,
                  child: Icon(Icons.person, color: AppColors.primaryBlue),
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
          const SizedBox(height: 24),

          // Hemen Oyna button
          GradientButton(
            text: '🎮  HEMEN OYNA',
            onTap: () => Navigator.pushNamed(context, '/trivia'),
            gradient: AppColors.primaryGradient,
          ),
          const SizedBox(height: 28),

          const Text('Oyun Kategorileri', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: [
              CategoryCard(
                title: 'Futbol Trivia',
                subtitle: '${QuestionService.getTriviaQuestions().length} soru',
                icon: Icons.quiz_rounded,
                gradient: AppColors.primaryGradient,
                onTap: () => Navigator.pushNamed(context, '/trivia'),
              ),
              CategoryCard(
                title: 'Skor Tahmini',
                subtitle: 'Canlı maçlar',
                icon: Icons.scoreboard_rounded,
                gradient: AppColors.orangeGradient,
                onTap: () => Navigator.pushNamed(context, '/score_prediction'),
              ),
              CategoryCard(
                title: 'Şehir Bul',
                subtitle: '${QuestionService.getCityFinderTeams().length} takım',
                icon: Icons.location_city_rounded,
                gradient: AppColors.blueGradient,
                onTap: () => Navigator.pushNamed(context, '/city_finder'),
              ),
              CategoryCard(
                title: 'Kim Bu?',
                subtitle: '${QuestionService.getGuessPlayerData().length} futbolcu',
                icon: Icons.person_search_rounded,
                gradient: AppColors.greenGradient,
                onTap: () => Navigator.pushNamed(context, '/guess_player'),
              ),
              CategoryCard(
                title: 'Transferler',
                subtitle: '${QuestionService.getTransferChains().length} zincir',
                icon: Icons.flight_takeoff,
                gradient: AppColors.purpleGradient,
                onTap: () => Navigator.pushNamed(context, '/transfer_chain'),
              ),
              CategoryCard(
                title: 'Kadro Tahmini',
                subtitle: 'İlk 11\'i kur',
                icon: Icons.group_add_rounded,
                gradient: AppColors.orangeGradient,
                onTap: () => Navigator.pushNamed(context, '/lineup_prediction'),
              ),
              CategoryCard(
                title: 'Mini Futbol',
                subtitle: 'Bilgisayara karşı!',
                icon: Icons.sports_soccer,
                gradient: AppColors.greenGradient,
                onTap: () => Navigator.pushNamed(context, '/mini_football'),
              ),
              CategoryCard(
                title: 'Penaltı',
                subtitle: 'Kaleye şut at!',
                icon: Icons.sports_handball,
                gradient: AppColors.orangeGradient,
                onTap: () => Navigator.pushNamed(context, '/penalty'),
              ),
              CategoryCard(
                title: 'Top Sektirme',
                subtitle: 'Kaç kez sektir?',
                icon: Icons.do_not_step,
                gradient: AppColors.blueGradient,
                onTap: () => Navigator.pushNamed(context, '/juggling'),
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
          const Text('Tüm Oyunlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _gameListTile(Icons.quiz_rounded, 'Futbol Trivia', '${QuestionService.getTriviaQuestions().length} soru hazır', AppColors.primaryBlue, '/trivia'),
          _gameListTile(Icons.scoreboard_rounded, 'Skor Tahmini', 'Günlük maçları tahmin et', AppColors.primaryOrange, '/score_prediction'),
          _gameListTile(Icons.location_city_rounded, 'Şehir Bul', '${QuestionService.getCityFinderTeams().length} takım', AppColors.categoryBlue, '/city_finder'),
          _gameListTile(Icons.person_search_rounded, 'Kim Bu Futbolcu?', '${QuestionService.getGuessPlayerData().length} yıldız futbolcu', AppColors.categoryGreen, '/guess_player'),
          _gameListTile(Icons.flight_takeoff, 'Transfer Zinciri', '${QuestionService.getTransferChains().length} transfer zinciri', AppColors.primaryBlue, '/transfer_chain'),
          _gameListTile(Icons.group_add_rounded, 'Kadro Tahmini', 'Maç öncesi ilk 11\'ini kur', AppColors.primaryOrange, '/lineup_prediction'),
          _gameListTile(Icons.sports_soccer, 'Mini Futbol', 'Bilgisayara karşı 2D maç', AppColors.categoryGreen, '/mini_football'),
        ],
      ),
    );
  }

  Widget _gameListTile(IconData icon, String title, String subtitle, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardBox(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    try {
      return FutureBuilder(
        future: FirebaseService().getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_rounded, color: Colors.grey.shade300, size: 64),
                  const SizedBox(height: 16),
                  const Text('Sıralama henüz mevcut değil.', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Oyun oynayarak sıralamaya katılın!', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aylık Liderlik Tablosu', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isFirst = index == 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isFirst ? AppColors.primaryOrange.withOpacity(0.1) : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isFirst ? AppColors.primaryOrange : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Text('#${index + 1}', style: TextStyle(color: isFirst ? AppColors.primaryOrange : AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 14),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                            child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(data['username'] ?? 'Falso Oyuncusu', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold))),
                          Text('${data['score'] ?? 0} RP', style: const TextStyle(color: AppColors.textAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                          if (isFirst) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                          ]
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.grey.shade300, size: 64),
            const SizedBox(height: 16),
            const Text('Sıralama şu anda kullanılamıyor.', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
      );
    }
  }

  Widget _buildProfilePlaceholder() {
    return FutureBuilder<GameStateService>(
      future: GameStateService.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
        final gs = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            // Profile header
            Center(child: Column(children: [
              CircleAvatar(radius: 36, backgroundColor: AppColors.primaryBlue.withAlpha(30), child: const Icon(Icons.person, color: AppColors.primaryBlue, size: 40)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final ctrl = TextEditingController(text: gs.nickname);
                  final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
                    backgroundColor: AppColors.bgCard,
                    title: const Text('Takma Adını Değiştir', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                    content: TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(filled: true, fillColor: AppColors.bgSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')), ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue), child: const Text('Kaydet', style: TextStyle(color: Colors.white)))],
                  ));
                  if (name != null && name.isNotEmpty) { await gs.setNickname(name); setState(() {}); }
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(gs.nickname, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, color: AppColors.textSecondary, size: 14),
                ]),
              ),
            ])),
            const SizedBox(height: 20),

            // Stats row
            Row(children: [
              Expanded(child: _miniStat(Icons.star, '${gs.totalScore}', 'Toplam Puan')),
              const SizedBox(width: 8),
              Expanded(child: _miniStat(Icons.local_fire_department, '${gs.streak}', 'Gün Serisi')),
              const SizedBox(width: 8),
              Expanded(child: _miniStat(Icons.emoji_events, '${gs.bestStreak}', 'En İyi Seri')),
            ]),
            const SizedBox(height: 20),

            // Badges
            const Text('Rozetler', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.75),
              itemCount: gs.badges.length,
              itemBuilder: (_, i) {
                final b = gs.badges[i];
                final earned = b['earned'] as bool;
                return GestureDetector(
                  onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
                    backgroundColor: AppColors.bgCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('${b['icon']} ${b['name']}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                    content: Text(b['desc'], style: const TextStyle(color: AppColors.textSecondary)),
                  )),
                  child: Column(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: earned ? AppColors.primaryOrange.withAlpha(25) : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: earned ? AppColors.primaryOrange.withAlpha(100) : const Color(0xFFE5E7EB)),
                      ),
                      child: Center(child: Text(b['icon'] ?? '🏅', style: TextStyle(fontSize: 20, color: earned ? null : Colors.grey.withAlpha(120)))),
                    ),
                    const SizedBox(height: 3),
                    Text(b['name'] ?? '', style: TextStyle(color: earned ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                );
              },
            ),
            const SizedBox(height: 20),

            // Game stats
            const Text('Oyun İstatistikleri', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _gameStat('Trivia', gs.getGamePlays('trivia'), gs.getGameScore('trivia'), Icons.quiz),
            _gameStat('Mini Futbol', gs.getGamePlays('mini_football'), gs.getGameScore('mini_football'), Icons.sports_soccer),
            _gameStat('Penaltı', gs.getGamePlays('penalty'), gs.getGameScore('penalty'), Icons.sports_handball),
            _gameStat('Top Sektirme', gs.getGamePlays('juggling'), gs.getGameScore('juggling'), Icons.do_not_step),
            _gameStat('Kim Bu?', gs.getGamePlays('guess_player'), gs.getGameScore('guess_player'), Icons.person_search),
            _gameStat('Şehir Bul', gs.getGamePlays('city_finder'), gs.getGameScore('city_finder'), Icons.location_city),
            _gameStat('Transfer', gs.getGamePlays('transfer'), gs.getGameScore('transfer'), Icons.flight_takeoff),
            const SizedBox(height: 30),
          ]),
        );
      },
    );
  }

  Widget _gameStat(String name, int plays, int score, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.cardBox(),
      child: Row(children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$score puan', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          Text('$plays oyun', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppDecorations.cardBox(),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}