import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({Key? key}) : super(key: key);

  Future<void> _onTap(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(Provider.google);
    } catch (e) {
      AppLogger.e('GoogleSignIn', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.g_mobiledata, color: Colors.white),
      label: const Text('Continue with Google'),
      onPressed: () => _onTap(context),
      style: ElevatedButton.styleFrom(primary: const Color(0xFF4285F4)),
    );
  }
}
