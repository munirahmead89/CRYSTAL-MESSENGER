import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumDashboard extends StatelessWidget {
  const PremiumDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crystal Premium', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF075E54), Color(0xFF128C7E), Color(0xFF075E54)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 100),
              _buildHeroSection(),
              const SizedBox(height: 40),
              _buildFeatureGrid(),
              const SizedBox(height: 40),
              _buildPricingCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        const Icon(Icons.star_rounded, size: 80, color: Colors.amber).animate().scale(duration: 800.ms),
        const SizedBox(height: 20),
        Text(
          'Elevate Your Experience',
          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        const Text(
          'Unlock exclusive founder features and premium themes',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildFeatureItem(Icons.music_note, 'Custom Ringtones', 'Unique calls for every contact'),
        _buildFeatureItem(Icons.timer, 'Extended TTL', 'Messages last up to 24 hours'),
        _buildFeatureItem(Icons.badge, 'Premium Badge', 'Founder status on your profile'),
        _buildFeatureItem(Icons.hd, 'HD Media', 'Send photos in original quality'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc) {
    return GlassContainer(
      blur: 10,
      color: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white10),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF25D366), size: 30),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 4),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return GlassContainer(
      blur: 20,
      color: Colors.white.withValues(alpha: 0.1),
      border: Border.all(color: Colors.white24),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text('Annual Plan', style: TextStyle(color: Colors.white70, letterSpacing: 2)),
            const SizedBox(height: 10),
            const Text('\$49.99 / year', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const Text('Save 20% compared to monthly', style: TextStyle(color: Color(0xFF25D366), fontSize: 12)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('UPGRADE TO PREMIUM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
