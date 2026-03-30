import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAd {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String advertiser; // "agora", "windlar", "petsis", etc.
  final DateTime startDate;
  final DateTime endDate;
  final int displayCount;
  final int maxDisplayCount;
  final bool isActive;
  
  CustomAd({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.advertiser,
    required this.startDate,
    required this.endDate,
    this.displayCount = 0,
    this.maxDisplayCount = 1000,
    this.isActive = true,
  });
  
  bool get isValid => 
      isActive && 
      DateTime.now().isAfter(startDate) && 
      DateTime.now().isBefore(endDate) &&
      displayCount < maxDisplayCount;
}

class CustomAdService {
  final List<CustomAd> _ads = [];
  
  // Initialize with your brands
  Future<void> initialize() async {
    // Add your custom brands here
    _ads.addAll([
      CustomAd(
        id: 'agora_banner_1',
        title: 'Agora - Digital Marketing',
        imageUrl: 'https://example.com/agora_banner.png', // Replace with actual URL
        targetUrl: 'https://agora.example.com',
        advertiser: 'agora',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        maxDisplayCount: 5000,
      ),
      CustomAd(
        id: 'windlar_banner_1',
        title: 'Windlar - Drone Inspection',
        imageUrl: 'https://example.com/windlar_banner.png', // Replace with actual URL
        targetUrl: 'https://windlar.example.com',
        advertiser: 'windlar',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        maxDisplayCount: 5000,
      ),
      CustomAd(
        id: 'petsis_banner_1',
        title: 'Petsis - Personnel Tracking',
        imageUrl: 'https://example.com/petsis_banner.png', // Replace with actual URL
        targetUrl: 'https://petsis.example.com',
        advertiser: 'petsis',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        maxDisplayCount: 5000,
      ),
    ]);
    
    print('CustomAdService initialized with ${_ads.length} ads');
  }
  
  // Get a random valid ad
  CustomAd? getRandomAd({String? preferredAdvertiser}) {
    final validAds = _ads.where((ad) => ad.isValid).toList();
    
    if (validAds.isEmpty) return null;
    
    // Filter by preferred advertiser if specified
    if (preferredAdvertiser != null) {
      final filteredAds = validAds.where((ad) => ad.advertiser == preferredAdvertiser).toList();
      if (filteredAds.isNotEmpty) {
        return filteredAds[DateTime.now().millisecondsSinceEpoch % filteredAds.length];
      }
    }
    
    // Return random ad from all valid ads
    return validAds[DateTime.now().millisecondsSinceEpoch % validAds.length];
  }
  
  // Get all ads for a specific advertiser
  List<CustomAd> getAdsByAdvertiser(String advertiser) {
    return _ads.where((ad) => ad.advertiser == advertiser && ad.isValid).toList();
  }
  
  // Get a random banner widget (convenience method)
  Widget getRandomBanner({double height = 60}) {
    final ad = getRandomAd();
    if (ad != null) {
      return createBannerWidget(ad: ad, height: height);
    }
    return const SizedBox.shrink();
  }
  
  // Create a banner widget from an ad
  Widget createBannerWidget({
    required CustomAd ad,
    double height = 50,
    double borderRadius = 8,
    VoidCallback? onTap,
    VoidCallback? onDisplay,
  }) {
    // Call onDisplay callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onDisplay?.call();
    });
    
    return GestureDetector(
      onTap: () {
        _launchUrl(ad.targetUrl);
        onTap?.call();
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(
            imageUrl: ad.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  ad.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Create a custom interstitial widget
  Widget createInterstitialWidget({
    required CustomAd ad,
    required VoidCallback onClose,
    double borderRadius = 16,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Ad content
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ad image
                GestureDetector(
                  onTap: () => _launchUrl(ad.targetUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: ad.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            ad.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Ad info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sponsored by ${ad.advertiser.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _launchUrl(ad.targetUrl),
                            child: const Text('VISIT WEBSITE'),
                          ),
                          TextButton(
                            onPressed: onClose,
                            child: const Text('CLOSE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Launch URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
    }
  }
  
  // Track ad display
  void trackDisplay(String adId) {
    final adIndex = _ads.indexWhere((ad) => ad.id == adId);
    if (adIndex != -1) {
      // In production, you would update this in a database
      print('Ad $adId displayed');
    }
  }
  
  // Track ad click
  void trackClick(String adId) {
    final adIndex = _ads.indexWhere((ad) => ad.id == adId);
    if (adIndex != -1) {
      // In production, you would update this in a database
      print('Ad $adId clicked');
    }
  }
  
  // Add a new custom ad
  void addAd(CustomAd ad) {
    _ads.add(ad);
    print('Added custom ad: ${ad.title}');
  }
  
  // Remove an ad
  void removeAd(String adId) {
    _ads.removeWhere((ad) => ad.id == adId);
    print('Removed custom ad: $adId');
  }
  
  // Get ad statistics
  Map<String, dynamic> getAdStats() {
    final totalAds = _ads.length;
    final activeAds = _ads.where((ad) => ad.isValid).length;
    final totalDisplays = _ads.fold(0, (sum, ad) => sum + ad.displayCount);
    
    return {
      'total_ads': totalAds,
      'active_ads': activeAds,
      'total_displays': totalDisplays,
      'advertisers': _ads.map((ad) => ad.advertiser).toSet().toList(),
    };
  }
}