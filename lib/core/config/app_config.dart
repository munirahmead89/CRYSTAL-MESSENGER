/// Centralized app configuration for Supabase, AdMob, Agora, and feature flags
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // === SUPABASE CONFIGURATION ===
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';

  // === GOOGLE OAUTH ===
  static String get googleOAuthClientId =>
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? 'your-google-client-id';

  // === ADMOB CONFIGURATION ===
  static String get adMobAppIdAndroid =>
      dotenv.env['ADMOB_APP_ID_ANDROID'] ?? 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy';
  
  static String get adMobAppIdIos =>
      dotenv.env['ADMOB_APP_ID_IOS'] ?? 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy';
  
  static String get bannerAdUnitIdAndroid =>
      dotenv.env['BANNER_AD_UNIT_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544/6300978111'; // Test ID

  static String get bannerAdUnitIdIos =>
      dotenv.env['BANNER_AD_UNIT_ID_IOS'] ??
      'ca-app-pub-3940256099942544/2934735716'; // Test ID

  static String get interstitialAdUnitIdAndroid =>
      dotenv.env['INTERSTITIAL_AD_UNIT_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544/1033173712'; // Test ID

  static String get interstitialAdUnitIdIos =>
      dotenv.env['INTERSTITIAL_AD_UNIT_ID_IOS'] ??
      'ca-app-pub-3940256099942544/4411468910'; // Test ID

  // === AGORA VOICE/VIDEO CALLING ===
  static String get agoraAppId =>
      dotenv.env['AGORA_APP_ID'] ?? 'your-agora-app-id';

  static String get agoraAppCertificate =>
      dotenv.env['AGORA_APP_CERTIFICATE'] ?? 'your-agora-app-certificate';

  // === FEATURE FLAGS ===
  static bool get enableAdMob => dotenv.env['ENABLE_ADMOB'] == 'true';
  static bool get enableCalling => dotenv.env['ENABLE_CALLING'] == 'true';
  static bool get enableVoiceNotes => dotenv.env['ENABLE_VOICE_NOTES'] == 'true';
  static bool get enableMediaSharing =>
      dotenv.env['ENABLE_MEDIA_SHARING'] == 'true';
  static bool get enableTypingIndicators =>
      dotenv.env['ENABLE_TYPING_INDICATORS'] == 'true';

  // === APP METADATA ===
  static const String appName = 'Crystal Messenger';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // === ENDPOINTS & STORAGE ===
  static const String storageProfileBucketName = 'profiles';
  static const String storageChatMediaBucketName = 'chat-media';
  static const String storageVoiceNotesBucketName = 'voice-notes';

  // === TIMEOUTS & LIMITS ===
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxFileUploadSizeMB = 100;
  static const int maxProfilePictureSizeMB = 5;
  static const int messagePageSize = 20;
  static const int typingIndicatorTimeoutSeconds = 3;

  // === THEME ===
  static const String primaryColor = '#00A884'; // WhatsApp green
  static const String accentColor = '#128C7E';
  static const String errorColor = '#F23E5E';
  static const String backgroundColor = '#FFFFFF';
}
