import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF075E54).withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF075E54), Color(0xFF25D366)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.diamond_outlined, size: 80, color: Colors.white),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                const SizedBox(height: 40),
                Text(
                  'Crystal Messenger',
                  style: GoogleFonts.outfit(
                    fontSize: 45,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Premium Ephemeral Messaging',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Colors.white60,
                    fontWeight: FontWeight.w300,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const Spacer(),
                GlassContainer(
                  blur: 10,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(25),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'DESIGNED BY MUNIR WAHEED\nTHE FOUNDER OF CRYSTAL MESSENGER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'AGREE AND CONTINUE',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).moveY(begin: 30, end: 0),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

