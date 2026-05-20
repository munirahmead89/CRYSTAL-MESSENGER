import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../onboarding/welcome_page.dart';
import '../profile/profile_page.dart';
import '../dashboard/dashboard_page.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((event) => event.session?.user);
});

class AuthGate extends ConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) {
        if (user == null) {
          return const WelcomePage();
        } else {
          // In a production app, check if profile exists. For brevity, route to profile creation then dashboard.
          return const ProfilePage();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Auth Error: $e'))),
    );
  }
}
