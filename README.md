# Falso ⚽

Futbol Tahmin ve Trivia Oyunu - Flutter + Flame ile geliştirilen interaktif futbol bilgi yarışması.

## 🎯 Özellikler
- Canlı maç tahminleri
- Transfer zinciri bulma oyunu
- Kadro tahmin modu
- Sosyal medya paylaşımı
- Rekabetçi lider tablosu

## 🛠️ Teknoloji Stack
- **Flutter 3.0+**
- **Flame Game Engine**
- **Firebase** (Auth, Firestore)
- **API-Football** (Canlı maç verileri)

## 📱 Ekranlar
1. Ana Menü
2. Maç Tahmin Ekranı
3. Transfer Zinciri Oyunu
4. Profil ve Lider Tablosu

## 🚀 Kurulum
```bash
git clone https://github.com/ahmetulukan/falso_app.git
cd falso_app
flutter pub get
flutter run
```

## 📁 Proje Yapısı
```
lib/
├── main.dart
├── game/
│   ├── falso_game.dart
│   └── components/
├── screens/
│   ├── home_screen.dart
│   ├── game_screen.dart
│   └── profile_screen.dart
├── models/
│   ├── player.dart
│   └── match.dart
└── services/
    ├── api_service.dart
    └── firebase_service.dart
```

## 🔧 Geliştirme
Proje Clean Architecture prensiplerine göre yapılandırılmıştır. State management için Riverpod kullanılır.

## 📄 Lisans
MIT License