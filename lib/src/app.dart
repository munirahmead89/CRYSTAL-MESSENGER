import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_gate.dart';
import 'core/theme.dart';

class CrystalApp extends ConsumerWidget {
  const CrystalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Crystal Messenger',
      theme: whatsappTheme,
      home: const AuthGate(), // Handles routing to onboarding/profile/dashboard
      debugShowCheckedModeBanner: false,
    );
  }
}
