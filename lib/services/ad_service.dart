import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdService {
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isInitialized = false;
  
  // Initialize Google Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _isInitialized = true;
    print('AdService initialized');
  }
  
  // Load and show a banner ad
  Future<BannerAd> loadBannerAd({
    AdSize size = AdSize.banner,
    void Function()? onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized) await initialize();
    
    // In production, use environment variable or remote config
    final adUnitId = dotenv.get('ADMOB_BANNER_ID', fallback: _testBannerAdUnitId);
    
    final bannerAd = BannerAd(
      size: size,
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
        onAdOpened: (ad) => print('Banner ad opened'),
        onAdClosed: (ad) => print('Banner ad closed'),
      ),
      request: const AdRequest(),
    );
    
    await bannerAd.load();
    _bannerAd = bannerAd;
    return bannerAd;
  }
  
  // Load an interstitial ad (to be shown later)
  Future<void> loadInterstitialAd({
    void Function()? onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
    void Function()? onAdDismissed,
  }) async {
    if (!_isInitialized) await initialize();
    
    final adUnitId = dotenv.get('ADMOB_INTERSTITIAL_ID', fallback: _testInterstitialAdUnitId);
    
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial ad loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Interstitial ad dismissed');
              onAdDismissed?.call();
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
            },
          );
          
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }
  
  // Show interstitial ad (if loaded)
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print('No interstitial ad loaded');
    }
  }
  
  // Load a rewarded ad
  Future<void> loadRewardedAd({
    void Function()? onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
    void Function(RewardItem)? onUserEarnedReward,
    void Function()? onAdDismissed,
  }) async {
    if (!_isInitialized) await initialize();
    
    final adUnitId = dotenv.get('ADMOB_REWARDED_ID', fallback: _testRewardedAdUnitId);
    
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Rewarded ad dismissed');
              onAdDismissed?.call();
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
            },
          );
          
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }
  
  // Show rewarded ad (if loaded)
  void showRewardedAd({
    required void Function(RewardItem) onUserEarnedReward,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
    } else {
      print('No rewarded ad loaded');
    }
  }
  
  // Clean up resources
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    print('AdService disposed');
  }
  
  // Check if ads are enabled (for premium users)
  bool areAdsEnabled() {
    // In production, check user's premium status from Firestore
    return dotenv.get('ENABLE_ADS', fallback: 'true') == 'true';
  }
  
  // Get ad configuration for current environment
  Map<String, dynamic> getAdConfig() {
    return {
      'environment': dotenv.get('ENVIRONMENT', fallback: 'development'),
      'ads_enabled': areAdsEnabled(),
      'test_mode': dotenv.get('ENVIRONMENT', fallback: 'development') == 'development',
      'banner_ad_unit_id': dotenv.get('ADMOB_BANNER_ID', fallback: _testBannerAdUnitId),
    };
  }
}