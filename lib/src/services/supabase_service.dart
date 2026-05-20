import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/logger.dart';

class SupabaseService {
  SupabaseClient client;

  SupabaseService._(this.client);

  static Future<SupabaseService> init() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (url.isEmpty || anon.isEmpty) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not set in .env');
    }
    await Supabase.initialize(url: url, anonKey: anon, authCallbackUrlHostname: 'login-callback');
    final client = Supabase.instance.client;
    return SupabaseService._(client);
  }

  // Auth: Google sign-in via Supabase
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final res = await client.auth.signInWithOAuth(Provider.google);
      return res;
    } catch (e, st) {
      AppLogger.e('SupabaseAuth', e.toString());
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Upload file to storage
  Future<String?> uploadFile(String bucket, String path, List<int> bytes) async {
    try {
      final res = await client.storage.from(bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(cacheControl: '3600'));
      if (res == null) return null;
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      return publicUrl.data;
    } catch (e) {
      AppLogger.e('SupabaseStorage', e.toString());
      rethrow;
    }
  }

  // Realtime subscribe helper for a table (messages, typing, calls)
  RealtimeChannel subscribe(String table, void Function(RealtimePostgresChangesPayload) onMessage) {
    final channel = client.channel('public:$table');
    channel.on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: table), (payload, [ref]) {
      if (payload is RealtimePostgresChangesPayload) {
        onMessage(payload);
      }
    });
    client.addChannel(channel);
    channel.subscribe();
    return channel;
  }

  // Signaling: publish message to a signaling table
  Future<void> publishSignal(String tableName, Map<String, dynamic> payload) async {
    try {
      await client.from(tableName).insert(payload);
    } catch (e) {
      AppLogger.e('SignalPub', e.toString());
    }
  }

  // Other helper APIs (profiles/messages CRUD) should be added here for modularity
}
