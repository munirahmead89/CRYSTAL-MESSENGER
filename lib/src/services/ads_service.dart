import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdsService {
  AdsService._internal();

  static final AdsService instance = AdsService._internal();

  BannerAd? _banner;
  InterstitialAd? _interstitial;
  Widget? get bannerWidget => _banner != null ? AdWidget(ad: _banner!) : null;

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  void loadBannerAd() {
    final adUnitId = dotenv.env['ADMOB_BANNER_ID'] ?? 'ca-app-pub-3940256099942544/6300978111';
    _banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      listener: BannerAdListener(),
      request: const AdRequest(),
    )..load();
  }

  void loadInterstitialAd() {
    final adUnitId = dotenv.env['ADMOB_INTERSTITIAL_ID'] ?? 'ca-app-pub-3940256099942544/1033173712';
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
        _interstitial = ad;
      }, onAdFailedToLoad: (err) {}),
    );
  }

  void showInterstitial() {
    _interstitial?.show();
  }

  void dispose() {
    _banner?.dispose();
    _interstitial?.dispose();
  }
}
