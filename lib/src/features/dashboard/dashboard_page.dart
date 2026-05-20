import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../chat/chat_list_page.dart';
import '../../services/ads_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    AdsService.instance.loadBannerAd();
    AdsService.instance.loadInterstitialAd();
  }

  @override
  void dispose() {
    AdsService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crystal'),
      ),
      body: Column(
        children: [
          Expanded(child: const ChatListPage()),
          // Banner Ad at bottom
          Container(height: 60, color: Colors.transparent, child: AdsService.instance.bannerWidget ?? const SizedBox.shrink()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.chat),
      ),
    );
  }
}
