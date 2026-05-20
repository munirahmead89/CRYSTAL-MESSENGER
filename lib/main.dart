import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/app.dart';
import 'src/core/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for local dev (SUPABASE_URL, SUPABASE_ANON_KEY, ADMOB_* etc)
  await dotenv.load(fileName: ".env");

  // Initialize Hive for local caching
  await Hive.initFlutter();
  // Register adapters here if you create Hive types
  // Hive.registerAdapter(MessageAdapter());

  // Global error handling
  FlutterError.onError = (details) {
    AppLogger.e('FlutterError', details.exceptionAsString());
    FlutterError.dumpErrorToConsole(details);
  };

  await runZonedGuarded(() async {
    runApp(const ProviderScope(child: CrystalApp()));
  }, (error, stack) {
    AppLogger.e('Uncaught zone error', error.toString());
  });
}
