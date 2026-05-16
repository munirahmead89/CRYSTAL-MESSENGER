import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'hive_service.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static Future<void> init() async {
    try {
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || anonKey.isEmpty) throw Exception('Missing Supabase credentials');

      await Supabase.initialize(url: url, anonKey: anonKey);

      auth.onAuthStateChange.listen((state) async {
        try {
          if (state.event == AuthChangeEvent.signedIn && state.session != null) {
            await HiveService.instance.saveSession({
              'user_id': state.session!.user.id,
              'email': state.session!.user.email,
            });
          } else if (state.event == AuthChangeEvent.signedOut) {
            await HiveService.instance.clearSession();
          }
        } catch (e) {
          debugPrint('[SupabaseService] Auth state change error: $e');
        }
      });
    } catch (e) {
      debugPrint('[SupabaseService] Initialization error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = auth.currentUser;
      if (user == null) return null;
      return await client.from('profiles').select().eq('id', user.id).single();
    } catch (e) {
      debugPrint('[SupabaseService] Get profile error: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    try {
      return client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId)
          .order('created_at');
    } catch (e) {
      debugPrint('[SupabaseService] Message stream error: $e');
      return const Stream.empty();
    }
  }

  static Future<void> sendMessage({required String roomId, required String content}) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await client.from('messages').insert({
        'room_id': roomId,
        'sender_id': user.id,
        'text_content': content,
      });
    } catch (e) {
      debugPrint('[SupabaseService] Send message error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final user = auth.currentUser;
      if (user == null) return [];
      // Simplified room fetching
      return await client.from('rooms').select();
    } catch (e) {
      debugPrint('[SupabaseService] Get rooms error: $e');
      return [];
    }
  }
}
