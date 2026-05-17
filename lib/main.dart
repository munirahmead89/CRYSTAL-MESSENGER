import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/admob_service.dart';

Future<void> _initializeApp() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely.
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('[Init] Environment variables loaded successfully');
  } catch (e) {
    debugPrint('[Init] .env load error: $e - Using default configurations');
  }

  // Initialise essential services with graceful degradation.
  try {
    await HiveService.instance.init();
    debugPrint('[Init] Hive service initialized');
  } catch (e) {
    debugPrint('[Init] Hive service init failed: $e');
  }

  try {
    await SupabaseService.init();
    debugPrint('[Init] Supabase service initialized');
  } catch (e) {
    debugPrint(
        '[Init] Supabase init failed: $e - App may not function properly without backend');
  }

  try {
    await NotificationService.instance.initialize();
    debugPrint('[Init] Notification service initialized');
  } catch (e) {
    debugPrint(
        '[Init] Notification init failed: $e - Push notifications may not work');
  }

  try {
    await AdMobService.instance.initialize();
    debugPrint('[Init] AdMob service initialized');
  } catch (e) {
    debugPrint('[Init] AdMob init failed: $e - Ads will not display');
  }

  debugPrint('[Init] All services initialized with graceful degradation');
}

void main() async {
  await _initializeApp();
  runApp(const ProviderScope(child: CrystalMessengerApp()));
}
