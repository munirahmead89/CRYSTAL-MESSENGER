import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../auth/google_sign_in_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // If you add assets/crystal_logo.png, it will show here. For now show an icon
            const Icon(Icons.chat_bubble, size: 120, color: Color(0xFF075E54)),
            const SizedBox(height: 20),
            const Text('Welcome to Crystal Messenger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Secure, ephemeral, and fast. Chat like a pro with voice, video, and more.', textAlign: TextAlign.center),
            ),
            const Spacer(),
            const GoogleSignInButton(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Sign in with Email'),
              style: ElevatedButton.styleFrom(primary: const Color(0xFF25D366)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
