import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Main] .env load error: $e');
  }

  // Initialize Services
  await HiveService.instance.init();
  await SupabaseService.init();
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: CrystalMessengerApp(),
    ),
  );
}
