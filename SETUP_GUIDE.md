# Falso App - Kurulum ve Geliştirme Rehberi

## 🚀 Hızlı Başlangıç

### 1. Gereksinimler
- Flutter SDK (3.0 veya üzeri)
- Dart SDK
- Android Studio / Xcode (platforma özgü geliştirme için)
- Firebase hesabı
- API-Football RapidAPI hesabı

### 2. Projeyi Klonlama ve Bağımlılıklar
```bash
git clone <repo-url>
cd falso_app
flutter pub get
```

### 3. Environment Variables (.env dosyası)
`.env.example` dosyasını kopyalayın ve `.env` olarak adlandırın:
```bash
cp .env.example .env
```

`.env` dosyasını düzenleyin:
```env
# API-Football Configuration
RAPIDAPI_KEY=your_actual_rapidapi_key_here
RAPIDAPI_HOST=api-football-v1.p.rapidapi.com

# App Configuration
APP_NAME=Falso App
APP_VERSION=1.0.0
ENVIRONMENT=development
```

### 4. Firebase Kurulumu

#### Android
1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. Yeni proje oluşturun veya var olanı seçin
3. "Android uygulaması ekle"yi tıklayın
4. Paket adını girin (örn: `com.falso.app`)
5. `google-services.json` dosyasını indirin
6. İndirilen dosyayı `android/app/google-services.json` konumuna kopyalayın

#### iOS
1. Firebase Console'da "iOS uygulaması ekle"yi tıklayın
2. Bundle ID'yi girin (örn: `com.falso.app`)
3. `GoogleService-Info.plist` dosyasını indirin
4. İndirilen dosyayı `ios/Runner/GoogleService-Info.plist` konumuna kopyalayın

### 5. API-Football Kurulumu
1. [RapidAPI API-Football sayfasına](https://rapidapi.com/api-sports/api/api-football) gidin
2. Abone olun ve API Key'inizi alın
3. `.env` dosyasındaki `RAPIDAPI_KEY` değerini güncelleyin

## 🏗️ Mimari

### Cache Sistemi
Uygulama iki katmanlı cache sistemi kullanır:
1. **Local Cache (SharedPreferences)**: Hızlı erişim için
2. **Firestore Cache**: Cihazlar arası senkronizasyon için

Cache süresi: 24 saat
API istek limiti: Günde 100 istek (RapidAPI ücretsiz plan)

### Servisler
- `ApiService`: API-Football entegrasyonu
- `FirebaseService`: Authentication ve Firestore işlemleri
- `CacheService`: Cache yönetimi
- `QuestionService`: Mock veri sağlama (geliştirme için)

## 🔧 Geliştirme

### Kod Yapısı
```
lib/
├── main.dart              # Uygulama giriş noktası
├── models/               # Veri modelleri
├── screens/              # Ekranlar (UI)
├── services/             # Business logic servisleri
├── theme/                # Tema ve stil ayarları
└── widgets/              # Özel widget'lar
```

### Commit Kuralları
- Gündüz mesaisi: `[DAY-SHIFT]` etiketi
- Gece mesaisi: `[NIGHT-SHIFT]` etiketi
- Örnek: `[DAY-SHIFT] add: API cache system`

### DEVELOPMENT_HANDOVER.md
Bu dosya gündüz ve gece mesaileri arasında senkronizasyon için kullanılır. Her mesai bitiminde güncellenmelidir.

## 🧪 Test
```bash
# Unit testler
flutter test

# UI testler
flutter test integration_test

# Build kontrolü
flutter analyze
```

## 📱 Build
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 🔄 Güncellemeler
- `flutter pub upgrade` - Bağımlılıkları güncelle
- `flutter clean` - Build cache'ini temizle
- `pod install` (iOS) - CocoaPods bağımlılıklarını güncelle

## 🆘 Sorun Giderme

### Common Issues
1. **API Key hatası**: `.env` dosyasını kontrol edin
2. **Firebase bağlantı hatası**: `google-services.json` ve `GoogleService-Info.plist` dosyalarını kontrol edin
3. **iOS build hatası**: `pod install` çalıştırın
4. **Cache temizleme**: Uygulamayı kapatıp açın veya `CacheService.cleanupExpiredCache()` çağırın

## 📞 İletişim
- Geliştirici: Ahmet Ulukan
- GitHub: https://github.com/ahmetulukan
- Proje: https://github.com/ahmetulukan/falso-app

---

**Not:** Bu rehber geliştiriciler arası senkronizasyon için hazırlanmıştır. Lütfen `DEVELOPMENT_HANDOVER.md` dosyasını düzenli olarak güncelleyin.