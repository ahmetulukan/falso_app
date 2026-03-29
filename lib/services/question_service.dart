import '../models/question.dart';
import '../models/team.dart';

class QuestionService {
  // ─── Futbol Trivia Soruları (60 soru) ────────────────────────────────
  static List<Question> getTriviaQuestions() {
    return [
      Question(id: '1', text: '2022 FIFA Dünya Kupası\'nı hangi ülke kazandı?', options: ['Fransa', 'Arjantin', 'Brezilya', 'Hırvatistan'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '2', text: 'Şampiyonlar Ligi\'nde en çok şampiyonluk kazanan takım hangisidir?', options: ['Barcelona', 'Milan', 'Real Madrid', 'Liverpool'], correctIndex: 2, category: 'Şampiyonlar Ligi'),
      Question(id: '3', text: 'Cristiano Ronaldo hangi ülkenin vatandaşıdır?', options: ['Brezilya', 'İspanya', 'Portekiz', 'İtalya'], correctIndex: 2, category: 'Oyuncular'),
      Question(id: '4', text: 'Galatasaray\'ın stadyumunun adı nedir?', options: ['Atatürk Olimpiyat', 'Ali Sami Yen', 'Rams Park', 'Şükrü Saracoğlu'], correctIndex: 2, category: 'Türk Futbolu'),
      Question(id: '5', text: 'Offside kuralını ilk uygulayan lig hangisidir?', options: ['La Liga', 'Serie A', 'Premier Lig', 'Bundesliga'], correctIndex: 2, category: 'Kurallar'),
      Question(id: '6', text: 'Bir futbol maçında penaltı atışı kaç metreden yapılır?', options: ['9 metre', '11 metre', '12 metre', '10 metre'], correctIndex: 1, category: 'Kurallar'),
      Question(id: '7', text: 'Lionel Messi 2023\'te hangi takıma transfer oldu?', options: ['PSG', 'Barcelona', 'Inter Miami', 'Al Hilal'], correctIndex: 2, category: 'Transferler'),
      Question(id: '8', text: 'Türkiye Süper Lig\'inde en çok şampiyonluk kazanan takım hangisidir?', options: ['Beşiktaş', 'Fenerbahçe', 'Galatasaray', 'Trabzonspor'], correctIndex: 2, category: 'Türk Futbolu'),
      Question(id: '9', text: 'Ballon d\'Or ödülünü en çok kazanan futbolcu kimdir?', options: ['Cristiano Ronaldo', 'Lionel Messi', 'Michel Platini', 'Johan Cruyff'], correctIndex: 1, category: 'Oyuncular'),
      Question(id: '10', text: 'FIFA Dünya Kupası ilk kez hangi yıl düzenlendi?', options: ['1926', '1930', '1934', '1938'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '11', text: 'Hangi oyuncu "Kral" lakabıyla bilinir?', options: ['Pelé', 'Maradona', 'Beckenbauer', 'Zidane'], correctIndex: 0, category: 'Oyuncular'),
      Question(id: '12', text: 'Camp Nou hangi takımın stadyumudur?', options: ['Real Madrid', 'Atletico Madrid', 'Barcelona', 'Valencia'], correctIndex: 2, category: 'Stadyumlar'),
      Question(id: '13', text: 'Premier Lig\'de en çok gol atan oyuncu kimdir?', options: ['Wayne Rooney', 'Alan Shearer', 'Thierry Henry', 'Andrew Cole'], correctIndex: 1, category: 'Rekorlar'),
      Question(id: '14', text: 'Fenerbahçe\'nin kuruluş yılı nedir?', options: ['1903', '1905', '1907', '1909'], correctIndex: 2, category: 'Türk Futbolu'),
      Question(id: '15', text: 'VAR ilk hangi Dünya Kupası\'nda kullanıldı?', options: ['2014', '2018', '2022', '2010'], correctIndex: 1, category: 'Kurallar'),
      Question(id: '16', text: 'Hangi takım "Sarı Duvar" tribünüyle bilinir?', options: ['Real Madrid', 'Borussia Dortmund', 'Galatasaray', 'Celtic'], correctIndex: 1, category: 'Stadyumlar'),
      Question(id: '17', text: '2006 Dünya Kupası finalinde Zidane kimi kafayla vurdu?', options: ['Cannavaro', 'Materazzi', 'Buffon', 'Gattuso'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '18', text: 'Hangi futbolcu "El Fenomeno" lakabıyla bilinir?', options: ['Ronaldinho', 'Ronaldo Nazário', 'Rivaldo', 'Roberto Carlos'], correctIndex: 1, category: 'Oyuncular'),
      Question(id: '19', text: 'Beşiktaş hangi yıl kuruldu?', options: ['1901', '1903', '1905', '1907'], correctIndex: 1, category: 'Türk Futbolu'),
      Question(id: '20', text: 'En çok FIFA Dünya Kupası kazanan ülke hangisidir?', options: ['Almanya', 'İtalya', 'Brezilya', 'Arjantin'], correctIndex: 2, category: 'Dünya Kupası'),
      Question(id: '21', text: 'Old Trafford hangi şehirdedir?', options: ['Londra', 'Liverpool', 'Manchester', 'Birmingham'], correctIndex: 2, category: 'Stadyumlar'),
      Question(id: '22', text: '"The Invincibles" olarak bilinen takım hangisidir?', options: ['Chelsea 2005', 'Man City 2018', 'Arsenal 2004', 'Liverpool 2020'], correctIndex: 2, category: 'Rekorlar'),
      Question(id: '23', text: 'Süper Lig\'de en çok gol atan yabancı oyuncu kimdir?', options: ['Mario Gomez', 'Hakan Şükür', 'Aílton', 'Samuel Eto\'o'], correctIndex: 0, category: 'Türk Futbolu'),
      Question(id: '24', text: 'Hangi ülke 2016 Avrupa Şampiyonası\'nı kazandı?', options: ['Fransa', 'Almanya', 'Portekiz', 'İspanya'], correctIndex: 2, category: 'Avrupa Şampiyonası'),
      Question(id: '25', text: 'Dünya Kupası\'nda en çok gol atan oyuncu kimdir?', options: ['Pelé', 'Miroslav Klose', 'Ronaldo', 'Gerd Müller'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '26', text: 'Hangi kaleci en fazla kaleyi gol yemeden korumuştur PL\'de?', options: ['Petr Čech', 'Edwin van der Sar', 'David de Gea', 'Schmeichel'], correctIndex: 0, category: 'Rekorlar'),
      Question(id: '27', text: 'Santiago Bernabéu hangi mahallededir?', options: ['Sol', 'Chamartín', 'Salamanca', 'Retiro'], correctIndex: 1, category: 'Stadyumlar'),
      Question(id: '28', text: 'Türkiye 2002 Dünya Kupası\'nda kaçıncı oldu?', options: ['Yarı final', '3.', 'Çeyrek final', '4.'], correctIndex: 1, category: 'Türk Futbolu'),
      Question(id: '29', text: 'La Liga\'da en çok gol atan oyuncu kimdir?', options: ['Cristiano Ronaldo', 'Raúl', 'Lionel Messi', 'Telmo Zarra'], correctIndex: 2, category: 'Rekorlar'),
      Question(id: '30', text: '"Tiki-taka" hangi takımla özdeşleşmiştir?', options: ['Real Madrid', 'Man United', 'Barcelona', 'Bayern Münih'], correctIndex: 2, category: 'Taktik'),
      Question(id: '31', text: 'Neymar PSG\'ye kaç milyon euroya transfer oldu?', options: ['100 M€', '160 M€', '222 M€', '180 M€'], correctIndex: 2, category: 'Transferler'),
      Question(id: '32', text: '"The Special One" lakabı kime aittir?', options: ['Guardiola', 'Ancelotti', 'Mourinho', 'Klopp'], correctIndex: 2, category: 'Teknik Direktörler'),
      Question(id: '33', text: 'Serie A\'da en çok şampiyonluk kazanan takım hangisidir?', options: ['Inter', 'Milan', 'Juventus', 'Roma'], correctIndex: 2, category: 'Ligler'),
      Question(id: '34', text: '"Hat-trick" kaç gol demektir?', options: ['2', '3', '4', '5'], correctIndex: 1, category: 'Kurallar'),
      Question(id: '35', text: '2018 Dünya Kupası nerede düzenlendi?', options: ['Brezilya', 'Katar', 'Rusya', 'G. Afrika'], correctIndex: 2, category: 'Dünya Kupası'),
      Question(id: '36', text: 'Bundesliga\'da bir sezonda en çok gol atan kimdir?', options: ['Lewandowski', 'Gerd Müller', 'Haaland', 'Aubameyang'], correctIndex: 1, category: 'Rekorlar'),
      Question(id: '37', text: 'Trabzonspor\'un stadyumunun adı nedir?', options: ['Yeni Malatya', 'Papara Park', 'Medical Park', 'Avni Aker'], correctIndex: 1, category: 'Türk Futbolu'),
      Question(id: '38', text: 'Pep Guardiola\'nın ilk CL şampiyonluğu hangi yıl?', options: ['2008', '2009', '2010', '2011'], correctIndex: 1, category: 'Teknik Direktörler'),
      Question(id: '39', text: 'Anfield\'a ev sahipliği yapan takım hangisidir?', options: ['Everton', 'Man United', 'Liverpool', 'Chelsea'], correctIndex: 2, category: 'Stadyumlar'),
      Question(id: '40', text: 'Mbappé hangi kulüpten Real Madrid\'e transfer oldu?', options: ['Monaco', 'Lyon', 'PSG', 'Marseille'], correctIndex: 2, category: 'Transferler'),
      Question(id: '41', text: 'Galatasaray 2000\'de hangi UEFA kupasını kazandı?', options: ['Şampiyonlar Ligi', 'UEFA Kupası', 'Kupa Galipleri', 'Süper Kupa'], correctIndex: 1, category: 'Türk Futbolu'),
      Question(id: '42', text: 'Futbol topunun çevresi kaç cm olmalıdır?', options: ['60-62', '68-70', '72-74', '55-57'], correctIndex: 1, category: 'Kurallar'),
      Question(id: '43', text: 'Hangi ülke EURO 2020\'yi kazandı?', options: ['İngiltere', 'İspanya', 'İtalya', 'Danimarka'], correctIndex: 2, category: 'Avrupa Şampiyonası'),
      Question(id: '44', text: '"Hand of God" golü kimin?', options: ['Pelé', 'Maradona', 'Zidane', 'Ronaldo'], correctIndex: 1, category: 'Dünya Kupası'),
      Question(id: '45', text: 'Türkiye EURO 2008\'de hangi başarıyı elde etti?', options: ['Şampiyon', 'Yarı final', 'Final', 'Çeyrek final'], correctIndex: 1, category: 'Türk Futbolu'),
      Question(id: '46', text: 'Hangi futbolcu "CR7" lakabıyla bilinir?', options: ['Cafu', 'Carlos Roa', 'C.Ronaldo', 'C.Seedorf'], correctIndex: 2, category: 'Oyuncular'),
      Question(id: '47', text: 'Ligue 1\'de en çok şampiyonluk kazanan takım?', options: ['PSG', 'Ol. Lyon', 'Marseille', 'Saint-Étienne'], correctIndex: 3, category: 'Ligler'),
      Question(id: '48', text: 'En pahalı transfer Neymar\'dan sonra kim?', options: ['Dembélé', 'Mbappé', 'Coutinho', 'Griezmann'], correctIndex: 1, category: 'Transferler'),
      Question(id: '49', text: 'Bir futbol maçı normal sürede kaç dakikadır?', options: ['80', '90', '100', '120'], correctIndex: 1, category: 'Kurallar'),
      Question(id: '50', text: 'Hangi takım "I Bianconeri" lakabıyla bilinir?', options: ['Roma', 'Napoli', 'Juventus', 'Lazio'], correctIndex: 2, category: 'Takımlar'),
      // 10 yeni soru
      Question(id: '51', text: 'İlk FIFA Puskas Ödülü\'nü kim kazandı?', options: ['C.Ronaldo', 'Neymar', 'C.Ronaldo (2009)', 'Grafite'], correctIndex: 2, category: 'Ödüller'),
      Question(id: '52', text: '2014 Dünya Kupası finalinde skoru belirleyen golü kim attı?', options: ['Messi', 'Higuain', 'Götze', 'Müller'], correctIndex: 2, category: 'Dünya Kupası'),
      Question(id: '53', text: 'Maradona hangi kulüpte efsane oldu?', options: ['Barcelona', 'Napoli', 'Boca Juniors', 'Sevilla'], correctIndex: 1, category: 'Oyuncular'),
      Question(id: '54', text: 'İstanbul\'da 2005 Şampiyonlar Ligi finalini kim kazandı?', options: ['Liverpool', 'Milan', 'Chelsea', 'Barcelona'], correctIndex: 0, category: 'Şampiyonlar Ligi'),
      Question(id: '55', text: 'Hangi hakem 3 Dünya Kupası finalinde görev aldı?', options: ['Collina', 'Howard Webb', 'Pitana', 'Néstor Pitana'], correctIndex: 0, category: 'Hakemler'),
      Question(id: '56', text: 'İlk sarı ve kırmızı kart hangi Dünya Kupası\'nda kullanıldı?', options: ['1962', '1966', '1970', '1974'], correctIndex: 2, category: 'Kurallar'),
      Question(id: '57', text: 'Hangi ülke 3 kez üst üste Avrupa Şampiyonası kazandı?', options: ['Almanya', 'İtalya', 'İspanya', 'Fransa'], correctIndex: 2, category: 'Avrupa Şampiyonası'),
      Question(id: '58', text: 'Sir Alex Ferguson Manchester United\'ı kaç yıl çalıştırdı?', options: ['20', '26', '22', '30'], correctIndex: 1, category: 'Teknik Direktörler'),
      Question(id: '59', text: 'Hakan Şükür\'ün Dünya Kupası rekor golü kaçıncı saniyede?', options: ['8', '11', '15', '6'], correctIndex: 1, category: 'Türk Futbolu'),
      Question(id: '60', text: 'Hangi kaleci en çok penaltı kurtarma rekortmenidir?', options: ['Buffon', 'Casillas', 'Neuer', 'Manuel Neuer'], correctIndex: 0, category: 'Rekorlar'),
    ];
  }

  // ─── Şehir Bul Soruları (25 takım + koordinatlar) ────────────────────────────────
  static List<Team> getCityFinderTeams() {
    return [
      Team(id: '1', name: 'Galatasaray', logoUrl: 'https://media.api-sports.io/football/teams/645.png', city: 'İstanbul', country: 'Türkiye', league: 'Süper Lig', stadium: 'Rams Park', lat: 41.01, lon: 28.97),
      Team(id: '2', name: 'Fenerbahçe', logoUrl: 'https://media.api-sports.io/football/teams/611.png', city: 'İstanbul', country: 'Türkiye', league: 'Süper Lig', stadium: 'Şükrü Saracoğlu', lat: 41.01, lon: 28.97),
      Team(id: '3', name: 'Beşiktaş', logoUrl: 'https://media.api-sports.io/football/teams/549.png', city: 'İstanbul', country: 'Türkiye', league: 'Süper Lig', stadium: 'Tüpraş Stadyumu', lat: 41.01, lon: 28.97),
      Team(id: '4', name: 'Trabzonspor', logoUrl: 'https://media.api-sports.io/football/teams/607.png', city: 'Trabzon', country: 'Türkiye', league: 'Süper Lig', stadium: 'Papara Park', lat: 41.00, lon: 39.72),
      Team(id: '5', name: 'Real Madrid', logoUrl: 'https://media.api-sports.io/football/teams/541.png', city: 'Madrid', country: 'İspanya', league: 'La Liga', stadium: 'Santiago Bernabéu', lat: 40.42, lon: -3.70),
      Team(id: '6', name: 'Barcelona', logoUrl: 'https://media.api-sports.io/football/teams/529.png', city: 'Barselona', country: 'İspanya', league: 'La Liga', stadium: 'Camp Nou', lat: 41.39, lon: 2.17),
      Team(id: '7', name: 'Manchester United', logoUrl: 'https://media.api-sports.io/football/teams/33.png', city: 'Manchester', country: 'İngiltere', league: 'Premier League', stadium: 'Old Trafford', lat: 53.48, lon: -2.24),
      Team(id: '8', name: 'Liverpool', logoUrl: 'https://media.api-sports.io/football/teams/40.png', city: 'Liverpool', country: 'İngiltere', league: 'Premier League', stadium: 'Anfield', lat: 53.43, lon: -2.96),
      Team(id: '9', name: 'Bayern Münih', logoUrl: 'https://media.api-sports.io/football/teams/157.png', city: 'Münih', country: 'Almanya', league: 'Bundesliga', stadium: 'Allianz Arena', lat: 48.14, lon: 11.58),
      Team(id: '10', name: 'Juventus', logoUrl: 'https://media.api-sports.io/football/teams/496.png', city: 'Torino', country: 'İtalya', league: 'Serie A', stadium: 'Allianz Stadium', lat: 45.07, lon: 7.69),
      Team(id: '11', name: 'PSG', logoUrl: 'https://media.api-sports.io/football/teams/85.png', city: 'Paris', country: 'Fransa', league: 'Ligue 1', stadium: 'Parc des Princes', lat: 48.85, lon: 2.35),
      Team(id: '12', name: 'Ajax', logoUrl: 'https://media.api-sports.io/football/teams/194.png', city: 'Amsterdam', country: 'Hollanda', league: 'Eredivisie', stadium: 'Johan Cruijff Arena', lat: 52.37, lon: 4.90),
      Team(id: '13', name: 'Chelsea', logoUrl: 'https://media.api-sports.io/football/teams/49.png', city: 'Londra', country: 'İngiltere', league: 'Premier League', stadium: 'Stamford Bridge', lat: 51.51, lon: -0.12),
      Team(id: '14', name: 'Arsenal', logoUrl: 'https://media.api-sports.io/football/teams/42.png', city: 'Londra', country: 'İngiltere', league: 'Premier League', stadium: 'Emirates Stadium', lat: 51.51, lon: -0.12),
      Team(id: '15', name: 'Milan', logoUrl: 'https://media.api-sports.io/football/teams/489.png', city: 'Milano', country: 'İtalya', league: 'Serie A', stadium: 'San Siro', lat: 45.47, lon: 9.19),
      Team(id: '16', name: 'Inter', logoUrl: 'https://media.api-sports.io/football/teams/505.png', city: 'Milano', country: 'İtalya', league: 'Serie A', stadium: 'San Siro', lat: 45.47, lon: 9.19),
      Team(id: '17', name: 'Borussia Dortmund', logoUrl: 'https://media.api-sports.io/football/teams/165.png', city: 'Dortmund', country: 'Almanya', league: 'Bundesliga', stadium: 'Signal Iduna Park', lat: 51.51, lon: 7.47),
      Team(id: '18', name: 'Atletico Madrid', logoUrl: 'https://media.api-sports.io/football/teams/530.png', city: 'Madrid', country: 'İspanya', league: 'La Liga', stadium: 'Wanda Metropolitano', lat: 40.42, lon: -3.70),
      Team(id: '19', name: 'Benfica', logoUrl: 'https://media.api-sports.io/football/teams/211.png', city: 'Lizbon', country: 'Portekiz', league: 'Primeira Liga', stadium: 'Estádio da Luz', lat: 38.72, lon: -9.14),
      Team(id: '20', name: 'Porto', logoUrl: 'https://media.api-sports.io/football/teams/212.png', city: 'Porto', country: 'Portekiz', league: 'Primeira Liga', stadium: 'Estádio do Dragão', lat: 41.16, lon: -8.63),
      Team(id: '21', name: 'Celtic', logoUrl: 'https://media.api-sports.io/football/teams/247.png', city: 'Glasgow', country: 'İskoçya', league: 'Scottish PL', stadium: 'Celtic Park', lat: 55.86, lon: -4.25),
      Team(id: '22', name: 'Napoli', logoUrl: 'https://media.api-sports.io/football/teams/492.png', city: 'Napoli', country: 'İtalya', league: 'Serie A', stadium: 'Maradona', lat: 40.85, lon: 14.27),
      Team(id: '23', name: 'Manchester City', logoUrl: 'https://media.api-sports.io/football/teams/50.png', city: 'Manchester', country: 'İngiltere', league: 'Premier League', stadium: 'Etihad Stadium', lat: 53.48, lon: -2.24),
      Team(id: '24', name: 'Bursaspor', logoUrl: 'https://media.api-sports.io/football/teams/3563.png', city: 'Bursa', country: 'Türkiye', league: '1. Lig', stadium: 'Bursa Stadyumu', lat: 40.19, lon: 29.06),
      Team(id: '25', name: 'Roma', logoUrl: 'https://media.api-sports.io/football/teams/497.png', city: 'Roma', country: 'İtalya', league: 'Serie A', stadium: 'Olimpico', lat: 41.90, lon: 12.50),
    ];
  }

  // ─── Kim Bu Futbolcu (20 futbolcu + takım logosu) ────────────────────────────────
  static List<Map<String, dynamic>> getGuessPlayerData() {
    return [
      {'name': 'Lionel Messi', 'hints': ['Arjantinli', '8 Ballon d\'Or', 'Barcelona efsanesi', 'Inter Miami'], 'team': 'Inter Miami', 'teamLogo': 'https://media.api-sports.io/football/teams/18857.png'},
      {'name': 'Cristiano Ronaldo', 'hints': ['Portekizli', 'CR7 lakabı', 'ManU, Real, Juve', 'Al Nassr'], 'team': 'Al Nassr', 'teamLogo': 'https://media.api-sports.io/football/teams/2939.png'},
      {'name': 'Hakan Çalhanoğlu', 'hints': ['Türk milli takımı', 'Serbest vuruş uzmanı', 'Milan→Inter', 'Orta saha'], 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png'},
      {'name': 'Arda Güler', 'hints': ['Genç Türk yetenek', 'Real Madrid', 'FB altyapısı', '10 numara'], 'team': 'Real Madrid', 'teamLogo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'Erling Haaland', 'hints': ['Norveçli golcü', 'Man City', 'Dortmund\'dan transfer', 'Fiziksel güç'], 'team': 'Man City', 'teamLogo': 'https://media.api-sports.io/football/teams/50.png'},
      {'name': 'Kylian Mbappé', 'hints': ['Fransız yıldız', 'PSG→Real Madrid', 'Dünya Kupası gol kralı', 'Hız'], 'team': 'Real Madrid', 'teamLogo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'Neymar Jr.', 'hints': ['Brezilyalı', 'Barça ve PSG', 'Santos altyapısı', 'Çalım'], 'team': 'Al Hilal', 'teamLogo': 'https://media.api-sports.io/football/teams/2932.png'},
      {'name': 'Robert Lewandowski', 'hints': ['Polonyalı golcü', 'Bayern rekortmen', 'Barcelona', '9 numara'], 'team': 'Barcelona', 'teamLogo': 'https://media.api-sports.io/football/teams/529.png'},
      {'name': 'Vinícius Jr.', 'hints': ['Brezilyalı kanat', 'Real Madrid', 'Flamengo', 'Dribling'], 'team': 'Real Madrid', 'teamLogo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'Luka Modrić', 'hints': ['Hırvat efsane', '2018 Ballon d\'Or', 'Real Madrid', 'Tottenham'], 'team': 'Real Madrid', 'teamLogo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'Kevin De Bruyne', 'hints': ['Belçikalı', 'Man City yıldızı', 'Chelsea\'den', 'Asist kralı'], 'team': 'Man City', 'teamLogo': 'https://media.api-sports.io/football/teams/50.png'},
      {'name': 'Mohamed Salah', 'hints': ['Mısırlı golcü', 'Liverpool kanat', 'Roma\'dan', 'PL gol kralı'], 'team': 'Liverpool', 'teamLogo': 'https://media.api-sports.io/football/teams/40.png'},
      {'name': 'İlkay Gündoğan', 'hints': ['Türk asıllı Alman', 'BVB, City, Barça', 'Orta saha', 'Almanya'], 'team': 'Barcelona', 'teamLogo': 'https://media.api-sports.io/football/teams/529.png'},
      {'name': 'Kerem Aktürkoğlu', 'hints': ['Türk kanat', 'GS\'da parladı', 'EURO 2024 golcü', 'Hızlı'], 'team': 'Galatasaray', 'teamLogo': 'https://media.api-sports.io/football/teams/645.png'},
      {'name': 'Cengiz Ünder', 'hints': ['Türk kanat', 'Roma macerası', 'Fenerbahçe', 'Sağ ayak'], 'team': 'Fenerbahçe', 'teamLogo': 'https://media.api-sports.io/football/teams/611.png'},
      {'name': 'Jude Bellingham', 'hints': ['İngiliz yıldız', 'BVB→Real Madrid', 'Genç lider', 'Orta saha'], 'team': 'Real Madrid', 'teamLogo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'Bukayo Saka', 'hints': ['İngiliz kanat', 'Arsenal altyapı', 'Çok yönlü', 'Genç yıldız'], 'team': 'Arsenal', 'teamLogo': 'https://media.api-sports.io/football/teams/42.png'},
      {'name': 'Antoine Griezmann', 'hints': ['Fransız forvet', 'Atletico', 'Barça macerası', '"Küçük Prens"'], 'team': 'Atletico Madrid', 'teamLogo': 'https://media.api-sports.io/football/teams/530.png'},
      {'name': 'Mauro Icardi', 'hints': ['Arjantinli golcü', 'Inter kaptanı', 'PSG ve GS', 'Ceza sahası'], 'team': 'Galatasaray', 'teamLogo': 'https://media.api-sports.io/football/teams/645.png'},
      {'name': 'Ferdi Kadıoğlu', 'hints': ['Türk-Hollandalı', 'FB\'de parladı', 'Brighton', 'Bek/kanat'], 'team': 'Brighton', 'teamLogo': 'https://media.api-sports.io/football/teams/51.png'},
    ];
  }

  // ─── Transfer Zinciri (20 zincir) ────────────────────────────────
  static List<Map<String, dynamic>> getTransferChains() {
    return [
      {'name': 'Mauro Icardi', 'chain': [
        {'team': 'Sampdoria', 'logo': 'https://media.api-sports.io/football/teams/498.png', 'years': '2011-2013'},
        {'team': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png', 'years': '2013-2019'},
        {'team': 'PSG', 'logo': 'https://media.api-sports.io/football/teams/85.png', 'years': '2019-2022'},
        {'team': 'Galatasaray', 'logo': 'https://media.api-sports.io/football/teams/645.png', 'years': '2022-'},
      ]},
      {'name': 'Cristiano Ronaldo', 'chain': [
        {'team': 'Sporting', 'logo': 'https://media.api-sports.io/football/teams/228.png', 'years': '2002-2003'},
        {'team': 'Man. United', 'logo': 'https://media.api-sports.io/football/teams/33.png', 'years': '2003-2009'},
        {'team': 'Real Madrid', 'logo': 'https://media.api-sports.io/football/teams/541.png', 'years': '2009-2018'},
        {'team': 'Juventus', 'logo': 'https://media.api-sports.io/football/teams/496.png', 'years': '2018-2021'},
        {'team': 'Man. United', 'logo': 'https://media.api-sports.io/football/teams/33.png', 'years': '2021-2022'},
        {'team': 'Al Nassr', 'logo': 'https://media.api-sports.io/football/teams/2939.png', 'years': '2023-'},
      ]},
      {'name': 'Wesley Sneijder', 'chain': [
        {'team': 'Ajax', 'logo': 'https://media.api-sports.io/football/teams/194.png', 'years': '2002-2007'},
        {'team': 'Real Madrid', 'logo': 'https://media.api-sports.io/football/teams/541.png', 'years': '2007-2009'},
        {'team': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png', 'years': '2009-2013'},
        {'team': 'Galatasaray', 'logo': 'https://media.api-sports.io/football/teams/645.png', 'years': '2013-2018'},
      ]},
      {'name': 'Zlatan Ibrahimovic', 'chain': [
        {'team': 'Malmö', 'logo': 'https://media.api-sports.io/football/teams/372.png', 'years': '1999-2001'},
        {'team': 'Ajax', 'logo': 'https://media.api-sports.io/football/teams/194.png', 'years': '2001-2004'},
        {'team': 'Juventus', 'logo': 'https://media.api-sports.io/football/teams/496.png', 'years': '2004-2006'},
        {'team': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png', 'years': '2006-2009'},
        {'team': 'Barcelona', 'logo': 'https://media.api-sports.io/football/teams/529.png', 'years': '2009-2010'},
        {'team': 'Milan', 'logo': 'https://media.api-sports.io/football/teams/489.png', 'years': '2010-2012'},
        {'team': 'PSG', 'logo': 'https://media.api-sports.io/football/teams/85.png', 'years': '2012-2016'},
        {'team': 'Man. United', 'logo': 'https://media.api-sports.io/football/teams/33.png', 'years': '2016-2018'},
        {'team': 'Milan', 'logo': 'https://media.api-sports.io/football/teams/489.png', 'years': '2020-2023'},
      ]},
      {'name': 'Mesut Özil', 'chain': [
        {'team': 'Schalke', 'logo': 'https://media.api-sports.io/football/teams/174.png', 'years': '2006-2008'},
        {'team': 'Werder Bremen', 'logo': 'https://media.api-sports.io/football/teams/162.png', 'years': '2008-2010'},
        {'team': 'Real Madrid', 'logo': 'https://media.api-sports.io/football/teams/541.png', 'years': '2010-2013'},
        {'team': 'Arsenal', 'logo': 'https://media.api-sports.io/football/teams/42.png', 'years': '2013-2021'},
        {'team': 'Fenerbahçe', 'logo': 'https://media.api-sports.io/football/teams/611.png', 'years': '2021-2022'},
        {'team': 'Başakşehir', 'logo': 'https://media.api-sports.io/football/teams/1001.png', 'years': '2022-2023'},
      ]},
      {'name': 'Arda Turan', 'chain': [
        {'team': 'Galatasaray', 'logo': 'https://media.api-sports.io/football/teams/645.png', 'years': '2005-2011'},
        {'team': 'Atletico Madrid', 'logo': 'https://media.api-sports.io/football/teams/530.png', 'years': '2011-2015'},
        {'team': 'Barcelona', 'logo': 'https://media.api-sports.io/football/teams/529.png', 'years': '2015-2020'},
        {'team': 'Galatasaray', 'logo': 'https://media.api-sports.io/football/teams/645.png', 'years': '2020-2022'},
      ]},
      {'name': 'David Beckham', 'chain': [
        {'team': 'Man. United', 'logo': 'https://media.api-sports.io/football/teams/33.png', 'years': '1992-2003'},
        {'team': 'Real Madrid', 'logo': 'https://media.api-sports.io/football/teams/541.png', 'years': '2003-2007'},
        {'team': 'LA Galaxy', 'logo': 'https://media.api-sports.io/football/teams/1599.png', 'years': '2007-2012'},
        {'team': 'PSG', 'logo': 'https://media.api-sports.io/football/teams/85.png', 'years': '2013'},
      ]},
      {'name': 'Thierry Henry', 'chain': [
        {'team': 'Monaco', 'logo': 'https://media.api-sports.io/football/teams/91.png', 'years': '1994-1999'},
        {'team': 'Juventus', 'logo': 'https://media.api-sports.io/football/teams/496.png', 'years': '1999'},
        {'team': 'Arsenal', 'logo': 'https://media.api-sports.io/football/teams/42.png', 'years': '1999-2007'},
        {'team': 'Barcelona', 'logo': 'https://media.api-sports.io/football/teams/529.png', 'years': '2007-2010'},
        {'team': 'NY Red Bulls', 'logo': 'https://media.api-sports.io/football/teams/1602.png', 'years': '2010-2014'},
      ]},
      {'name': 'Hakan Çalhanoğlu', 'chain': [
        {'team': 'Karlsruhe', 'logo': 'https://media.api-sports.io/football/teams/170.png', 'years': '2012-2013'},
        {'team': 'Hamburg', 'logo': 'https://media.api-sports.io/football/teams/167.png', 'years': '2013-2014'},
        {'team': 'B. Leverkusen', 'logo': 'https://media.api-sports.io/football/teams/168.png', 'years': '2014-2017'},
        {'team': 'Milan', 'logo': 'https://media.api-sports.io/football/teams/489.png', 'years': '2017-2021'},
        {'team': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png', 'years': '2021-'},
      ]},
      {'name': 'Robin van Persie', 'chain': [
        {'team': 'Feyenoord', 'logo': 'https://media.api-sports.io/football/teams/215.png', 'years': '2001-2004'},
        {'team': 'Arsenal', 'logo': 'https://media.api-sports.io/football/teams/42.png', 'years': '2004-2012'},
        {'team': 'Man. United', 'logo': 'https://media.api-sports.io/football/teams/33.png', 'years': '2012-2015'},
        {'team': 'Fenerbahçe', 'logo': 'https://media.api-sports.io/football/teams/611.png', 'years': '2015-2018'},
        {'team': 'Feyenoord', 'logo': 'https://media.api-sports.io/football/teams/215.png', 'years': '2018-2019'},
      ]},
      {'name': 'Didier Drogba', 'chain': [
        {'team': 'Marseille', 'logo': 'https://media.api-sports.io/football/teams/81.png', 'years': '2003-2004'},
        {'team': 'Chelsea', 'logo': 'https://media.api-sports.io/football/teams/49.png', 'years': '2004-2012'},
        {'team': 'Galatasaray', 'logo': 'https://media.api-sports.io/football/teams/645.png', 'years': '2013'},
        {'team': 'Chelsea', 'logo': 'https://media.api-sports.io/football/teams/49.png', 'years': '2014-2015'},
      ]},
      {'name': 'Edin Dzeko', 'chain': [
        {'team': 'Wolfsburg', 'logo': 'https://media.api-sports.io/football/teams/161.png', 'years': '2007-2011'},
        {'team': 'Man. City', 'logo': 'https://media.api-sports.io/football/teams/50.png', 'years': '2011-2015'},
        {'team': 'Roma', 'logo': 'https://media.api-sports.io/football/teams/497.png', 'years': '2015-2021'},
        {'team': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png', 'years': '2021-2023'},
        {'team': 'Fenerbahçe', 'logo': 'https://media.api-sports.io/football/teams/611.png', 'years': '2023-'},
      ]},
    ];
  }

  // ─── Şehir Alternatiflerini Oluştur ────────────────────────────────
  static List<String> getCityOptions(String correctCity) {
    final allCities = [
      'İstanbul', 'Ankara', 'İzmir', 'Trabzon', 'Bursa', 'Antalya', 'Konya',
      'Madrid', 'Barselona', 'Sevilla', 'Valencia', 'Bilbao',
      'Manchester', 'Liverpool', 'Londra', 'Birmingham', 'Leeds',
      'Münih', 'Berlin', 'Dortmund', 'Hamburg', 'Frankfurt',
      'Torino', 'Milano', 'Roma', 'Napoli', 'Floransa',
      'Paris', 'Lyon', 'Marsilya', 'Nice',
      'Amsterdam', 'Rotterdam', 'Eindhoven',
      'Lizbon', 'Porto', 'Glasgow',
    ];
    final wrongCities = allCities.where((c) => c != correctCity).toList();
    wrongCities.shuffle();
    final options = [correctCity, ...wrongCities.take(3)];
    options.shuffle();
    return options;
  }
}
