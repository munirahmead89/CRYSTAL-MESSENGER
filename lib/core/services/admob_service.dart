import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdMobService {
  static final AdMobService instance = AdMobService._internal();
  AdMobService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint(
          '[AdMobService] Platform not supported for AdMob. Graceful degradation active.');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdMobService] AdMob Initialized successfully.');
    } catch (e) {
      debugPrint('[AdMobService] AdMob Initialization failed: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // PRODUCTION: Your actual AdMob Banner Ad Unit ID
      return const String.fromEnvironment('ADMOB_BANNER_ANDROID',
          defaultValue: 'ca-app-pub-5375584696804538/7151361153');
    } else if (Platform.isIOS) {
      // PRODUCTION: Your actual AdMob Banner Ad Unit ID
      return const String.fromEnvironment('ADMOB_BANNER_IOS',
          defaultValue: 'ca-app-pub-5375584696804538/7151361153');
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // PRODUCTION: Your actual AdMob Interstitial Ad Unit ID
      return const String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID',
          defaultValue: 'ca-app-pub-5375584696804538/7151361153');
    } else if (Platform.isIOS) {
      // PRODUCTION: Your actual AdMob Interstitial Ad Unit ID
      return const String.fromEnvironment('ADMOB_INTERSTITIAL_IOS',
          defaultValue: 'ca-app-pub-5375584696804538/7151361153');
    }
    return '';
  }

  // Load and show an interstitial ad instantly
  void showInterstitialAd() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('[AdMobService] Non-mobile platform. Skipping Interstitial.');
      return;
    }
    if (!_isInitialized) {
      debugPrint(
          '[AdMobService] AdMob not initialized yet. Cannot show Interstitial.');
      return;
    }
    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdMobService] Interstitial Ad loaded successfully.');
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                debugPrint(
                    '[AdMobService] Interstitial failed to show: $error');
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMobService] Interstitial failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdMobService] Interstitial load crash prevented: $e');
    }
  }

  // Returns a mobile ad widget or a premium glassmorphic placeholder on other platforms
  Widget getBannerAdWidget() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Crystal Sponsor Ad Placeholder (Platform: Desktop/Web)',
          style:
              TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
        ),
      );
    }
    return BannerAdContainer(adUnitId: bannerAdUnitId);
  }
}

class BannerAdContainer extends StatefulWidget {
  final String adUnitId;
  const BannerAdContainer({super.key, required this.adUnitId});

  @override
  State<BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends State<BannerAdContainer> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[AdMobService] Banner Ad failed to load: $error');
            ad.dispose();
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('[AdMobService] Banner Ad loading crash prevented: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Sponsored Ad Loading...',
        style: TextStyle(color: Colors.white30, fontSize: 10),
      ),
    );
  }
}
