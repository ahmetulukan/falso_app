import '../models/question.dart';
import '../models/team.dart';

class QuestionService {
  // ─── Futbol Trivia Soruları ────────────────────────────────
  static List<Question> getTriviaQuestions() {
    return [
      Question(id: '1', text: '2022 FIFA Dünya Kupası\'nı hangi ülke kazandı?', options: ['Fransa', 'Arjantin', 'Brezilya', 'Hırvatistan'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '2', text: 'Şampiyonlar Ligi\'nde en çok şampiyonluk kazanan takım hangisidir?', options: ['Barcelona', 'Milan', 'Real Madrid', 'Liverpool'], correctIndex: 2, category: 'Şampiyonlar Ligi'),
      Question(id: '3', text: 'Cristiano Ronaldo hangi ülkenin vatandaşıdır?', options: ['Brezilya', 'İspanya', 'Portekiz', 'İtalya'], correctIndex: 2, category: 'Oyuncular'),
      Question(id: '4', text: 'Galatasaray\'ın stadyumunun adı nedir?', options: ['Atatürk Olimpiyat', 'Ali Sami Yen', 'Rams Park', 'Şükrü Saracoğlu'], correctIndex: 2, category: 'Türk Futbolu'),
      Question(id: '5', text: 'Offside (ofsayt) kuralını ilk uygulayan lig hangisidir?', options: ['La Liga', 'Serie A', 'Premier Lig', 'Bundesliga'], correctIndex: 2, category: 'Kurallar'),
      Question(id: '6', text: 'Bir futbol maçında penaltı atışı kaç metreden yapılır?', options: ['9 metre', '11 metre', '12 metre', '10 metre'], correctIndex: 1, category: 'Kurallar'),
      Question(id: '7', text: 'Lionel Messi 2023\'te hangi takıma transfer oldu?', options: ['PSG', 'Barcelona', 'Inter Miami', 'Al Hilal'], correctIndex: 2, category: 'Transferler'),
      Question(id: '8', text: 'Türkiye Süper Lig\'inde en çok şampiyonluk kazanan takım hangisidir?', options: ['Beşiktaş', 'Fenerbahçe', 'Galatasaray', 'Trabzonspor'], correctIndex: 2, category: 'Türk Futbolu'),
      Question(id: '9', text: 'Ballon d\'Or ödülünü en çok kazanan futbolcu kimdir?', options: ['Cristiano Ronaldo', 'Lionel Messi', 'Michel Platini', 'Johan Cruyff'], correctIndex: 1, category: 'Oyuncular'),
      Question(id: '10', text: 'FIFA Dünya Kupası ilk kez hangi yıl düzenlendi?', options: ['1926', '1930', '1934', '1938'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '11', text: 'Hangi oyuncu "Kral" lakabıyla bilinir?', options: ['Pelé', 'Maradona', 'Beckenbauer', 'Zidane'], correctIndex: 0, category: 'Oyuncular'),
      Question(id: '12', text: 'Camp Nou hangi takımın stadyumudur?', options: ['Real Madrid', 'Atletico Madrid', 'Barcelona', 'Valencia'], correctIndex: 2, category: 'Stadyumlar'),
      Question(id: '13', text: 'Premier Lig\'de en çok gol atan oyuncu kimdir?', options: ['Wayne Rooney', 'Alan Shearer', 'Thierry Henry', 'Andrew Cole'], correctIndex: 1, category: 'Rekorlar'),
      Question(id: '14', text: 'Fenerbahçe\'nin kuruluş yılı nedir?', options: ['1903', '1905', '1907', '1909'], correctIndex: 2, category: 'Türk Futbolu'),
      Question(id: '15', text: 'VAR (Video Yardımcı Hakem) ilk hangi Dünya Kupası\'nda kullanıldı?', options: ['2014', '2018', '2022', '2010'], correctIndex: 1, category: 'Kurallar'),
    ];
  }

  // ─── Şehir Bul Soruları ────────────────────────────────
  static List<Team> getCityFinderTeams() {
    return [
      Team(id: '1', name: 'Galatasaray', logoUrl: 'https://media.api-sports.io/football/teams/645.png', city: 'İstanbul', country: 'Türkiye', league: 'Süper Lig', stadium: 'Rams Park'),
      Team(id: '2', name: 'Fenerbahçe', logoUrl: 'https://media.api-sports.io/football/teams/611.png', city: 'İstanbul', country: 'Türkiye', league: 'Süper Lig', stadium: 'Şükrü Saracoğlu'),
      Team(id: '3', name: 'Beşiktaş', logoUrl: 'https://media.api-sports.io/football/teams/549.png', city: 'İstanbul', country: 'Türkiye', league: 'Süper Lig', stadium: 'Tüpraş Stadyumu'),
      Team(id: '4', name: 'Trabzonspor', logoUrl: 'https://media.api-sports.io/football/teams/607.png', city: 'Trabzon', country: 'Türkiye', league: 'Süper Lig', stadium: 'Papara Park'),
      Team(id: '5', name: 'Real Madrid', logoUrl: 'https://media.api-sports.io/football/teams/541.png', city: 'Madrid', country: 'İspanya', league: 'La Liga', stadium: 'Santiago Bernabéu'),
      Team(id: '6', name: 'Barcelona', logoUrl: 'https://media.api-sports.io/football/teams/529.png', city: 'Barcelona', country: 'İspanya', league: 'La Liga', stadium: 'Camp Nou'),
      Team(id: '7', name: 'Manchester United', logoUrl: 'https://media.api-sports.io/football/teams/33.png', city: 'Manchester', country: 'İngiltere', league: 'Premier League', stadium: 'Old Trafford'),
      Team(id: '8', name: 'Liverpool', logoUrl: 'https://media.api-sports.io/football/teams/40.png', city: 'Liverpool', country: 'İngiltere', league: 'Premier League', stadium: 'Anfield'),
      Team(id: '9', name: 'Bayern Münih', logoUrl: 'https://media.api-sports.io/football/teams/157.png', city: 'Münih', country: 'Almanya', league: 'Bundesliga', stadium: 'Allianz Arena'),
      Team(id: '10', name: 'Juventus', logoUrl: 'https://media.api-sports.io/football/teams/496.png', city: 'Torino', country: 'İtalya', league: 'Serie A', stadium: 'Allianz Stadium'),
      Team(id: '11', name: 'PSG', logoUrl: 'https://media.api-sports.io/football/teams/85.png', city: 'Paris', country: 'Fransa', league: 'Ligue 1', stadium: 'Parc des Princes'),
      Team(id: '12', name: 'Ajax', logoUrl: 'https://media.api-sports.io/football/teams/194.png', city: 'Amsterdam', country: 'Hollanda', league: 'Eredivisie', stadium: 'Johan Cruijff Arena'),
    ];
  }

  // ─── Kim Bu Futbolcu Soruları ────────────────────────────────
  static List<Map<String, dynamic>> getGuessPlayerData() {
    return [
      {'name': 'Lionel Messi', 'hints': ['Arjantinli', '8 Ballon d\'Or', 'Barcelona efsanesi', 'Inter Miami'], 'team': 'Inter Miami'},
      {'name': 'Cristiano Ronaldo', 'hints': ['Portekizli', 'CR7 lakabı', 'Manchester United, Real Madrid, Juventus', 'Al Nassr'], 'team': 'Al Nassr'},
      {'name': 'Hakan Çalhanoğlu', 'hints': ['Türk milli takımı', 'Serbest vuruş uzmanı', 'Milan\'dan Inter\'e transfer', 'Orta saha'], 'team': 'Inter'},
      {'name': 'Arda Güler', 'hints': ['Genç Türk yetenek', 'Real Madrid', 'Fenerbahçe altyapısı', '10 numara'], 'team': 'Real Madrid'},
      {'name': 'Erling Haaland', 'hints': ['Norveçli golcü', 'Manchester City', 'Dortmund\'dan transfer', 'Fiziksel güç'], 'team': 'Manchester City'},
      {'name': 'Kylian Mbappé', 'hints': ['Fransız yıldız', 'PSG\'den Real Madrid\'e', 'Dünya Kupası gol kralı', 'Hızlı kanat'], 'team': 'Real Madrid'},
      {'name': 'Neymar Jr.', 'hints': ['Brezilyalı', 'Barcelona ve PSG', 'Santos altyapısı', 'Çalım ustası'], 'team': 'Al Hilal'},
      {'name': 'Robert Lewandowski', 'hints': ['Polonyalı golcü', 'Bayern Münih rekortmeni', 'Barcelona', '9 numara'], 'team': 'Barcelona'},
    ];
  }

  // ─── Şehir Alternatiflerini Oluştur ────────────────────────────────
  static List<String> getCityOptions(String correctCity) {
    final allCities = [
      'İstanbul', 'Ankara', 'İzmir', 'Trabzon', 'Bursa',
      'Madrid', 'Barcelona', 'Sevilla', 'Valencia',
      'Manchester', 'Liverpool', 'Londra', 'Birmingham',
      'Münih', 'Berlin', 'Dortmund', 'Hamburg',
      'Torino', 'Milano', 'Roma', 'Napoli',
      'Paris', 'Lyon', 'Marsilya',
      'Amsterdam', 'Rotterdam',
    ];

    final wrongCities = allCities.where((c) => c != correctCity).toList();
    wrongCities.shuffle();
    final options = [correctCity, ...wrongCities.take(3)];
    options.shuffle();
    return options;
  }
}
