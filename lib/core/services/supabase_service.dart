import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'hive_service.dart';
import '../models/models.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static Future<void> init() async {
    try {
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || anonKey.isEmpty) throw Exception('Missing Supabase credentials');

      await Supabase.initialize(url: url, anonKey: anonKey);

      // Listen to auth state changes to cache session status.
      auth.onAuthStateChange.listen((state) async {
        try {
          if (state.event == AuthChangeEvent.signedIn && state.session != null) {
            await HiveService.instance.saveSession({
              'user_id': state.session!.user.id,
              'email': state.session!.user.email,
            });
            // Try fetching profile to check completeness.
            final profile = await getCurrentProfile();
            if (profile != null && (profile['full_name'] != null || profile['username'] != null)) {
              await HiveService.instance.setProfileCompleted(true);
            } else {
              await HiveService.instance.setProfileCompleted(false);
            }
          } else if (state.event == AuthChangeEvent.signedOut) {
            await HiveService.instance.clearSession();
            await HiveService.instance.setProfileCompleted(false);
          }
        } catch (e) {
          debugPrint('[SupabaseService] Auth state change error: $e');
        }
      });
    } catch (e) {
      debugPrint('[SupabaseService] Initialization error: $e');
      rethrow;
    }
  }

  // Google OAuth Login
  static Future<void> signInWithGoogle() async {
    try {
      await auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.crystalmessenger://login-callback',
      );
    } catch (e) {
      debugPrint('[SupabaseService] Google Sign-In error: $e');
      rethrow;
    }
  }

  // Profiles
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

  static Future<void> updateProfile({
    required String fullName,
    required String username,
    required String status,
    String? avatarUrl,
    String? phone,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        'id': user.id,
        'full_name': fullName,
        'username': username,
        'status': status,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client.from('profiles').upsert(data);
      await HiveService.instance.setProfileCompleted(true);
    } catch (e) {
      debugPrint('[SupabaseService] Update profile error: $e');
      rethrow;
    }
  }

  // Supabase Storage Media Upload
  static Future<String?> uploadMedia(File file, String path, {String bucket = 'media'}) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExtension = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final fullPath = '$path/$fileName';

      await client.storage.from(bucket).uploadBinary(
        fullPath,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExtension', cacheControl: '3600'),
      );

      final String publicUrl = client.storage.from(bucket).getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] Media upload error: $e');
      return null;
    }
  }

  // Local Contact Syncing: Matches device phone numbers to registered profiles
  static Future<List<UserModel>> syncContacts(List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty) return [];
      
      // Query profiles whose phone matches one of the phoneNumbers list
      final response = await client
          .from('profiles')
          .select()
          .inFilter('phone', phoneNumbers);

      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Sync contacts error: $e');
      return [];
    }
  }

  // Real-time Messages
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

  static Future<void> sendMessage({
    required String roomId,
    String? content,
    String? mediaUrl,
    MessageType type = MessageType.text,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await client.from('messages').insert({
        'room_id': roomId,
        'sender_id': user.id,
        'text_content': content,
        'media_url': mediaUrl,
        'type': type.name,
        'is_delivered': true,
        'is_read': false,
      });

      // Update room last message
      await client.from('rooms').update({
        'last_message': content ?? '[Media]',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);
    } catch (e) {
      debugPrint('[SupabaseService] Send message error: $e');
      rethrow;
    }
  }

  // Mark message as read
  static Future<void> markRoomMessagesAsRead(String roomId) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Mark messages read error: $e');
    }
  }

  // Get or Create Direct Chat Room
  static Future<RoomModel> getOrCreateDirectRoom(String otherUserId) async {
    try {
      final myUser = auth.currentUser;
      if (myUser == null) throw Exception('User not authenticated');

      // Call RPC to see if room exists
      final rpcResult = await client.rpc('get_direct_room', params: {
        'user1': myUser.id,
        'user2': otherUserId,
      });

      if (rpcResult != null) {
        return RoomModel.fromJson(rpcResult);
      }

      // If room does not exist, create one
      final newRoom = await client.from('rooms').insert({
        'type': RoomType.direct.name,
        'created_by': myUser.id,
      }).select().single();

      final roomId = newRoom['id'];

      // Add participants
      await client.from('participants').insert([
        {'room_id': roomId, 'user_id': myUser.id, 'role': 'admin'},
        {'room_id': roomId, 'user_id': otherUserId, 'role': 'member'},
      ]);

      return RoomModel.fromJson(newRoom);
    } catch (e) {
      debugPrint('[SupabaseService] getOrCreateDirectRoom error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final user = auth.currentUser;
      if (user == null) return [];
      
      // Fetch rooms where the current user is a participant
      final response = await client
          .from('rooms')
          .select('*, participants!inner(*)')
          .eq('participants.user_id', user.id)
          .order('updated_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('[SupabaseService] Get rooms error: $e');
      return [];
    }
  }

  // Real-time Typing Indicators
  static Future<void> setTypingStatus(String roomId, bool isTyping) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      await client.from('typing_indicators').upsert({
        'room_id': roomId,
        'user_id': user.id,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] Set typing error: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getTypingStream(String roomId) {
    return client
        .from('typing_indicators')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('room_id', roomId);
  }

  // 1-on-1 Audio/Video Call Session Signaling (WebRTC)
  static Future<CallSessionModel> createCallSession({
    required String receiverId,
    required CallType type,
    required Map<String, dynamic> sdpOffer,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final session = await client.from('call_sessions').insert({
        'caller_id': user.id,
        'receiver_id': receiverId,
        'type': type.name,
        'status': CallStatus.dialing.name,
        'sdp_offer': sdpOffer,
        'ice_candidates_caller': [],
        'ice_candidates_receiver': [],
      }).select().single();

      return CallSessionModel.fromJson(session);
    } catch (e) {
      debugPrint('[SupabaseService] Create call session error: $e');
      rethrow;
    }
  }

  static Future<void> answerCall(String sessionId, Map<String, dynamic> sdpAnswer) async {
    try {
      await client.from('call_sessions').update({
        'sdp_answer': sdpAnswer,
        'status': CallStatus.connected.name,
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('[SupabaseService] Answer call error: $e');
      rethrow;
    }
  }

  static Future<void> updateCallStatus(String sessionId, CallStatus status) async {
    try {
      await client.from('call_sessions').update({
        'status': status.name,
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('[SupabaseService] Update call status error: $e');
    }
  }

  static Future<void> addIceCandidate(String sessionId, Map<String, dynamic> candidate, bool isCaller) async {
    try {
      final session = await client.from('call_sessions').select().eq('id', sessionId).single();
      final String arrayField = isCaller ? 'ice_candidates_caller' : 'ice_candidates_receiver';
      final List<dynamic> currentCandidates = List.from(session[arrayField] ?? []);
      currentCandidates.add(candidate);

      await client.from('call_sessions').update({
        arrayField: currentCandidates,
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('[SupabaseService] Add ICE candidate error: $e');
    }
  }

  static Stream<Map<String, dynamic>> streamCallSession(String sessionId) {
    return client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  static Stream<List<Map<String, dynamic>>> streamIncomingCalls() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .map((list) => list.where((c) => c['status'] == CallStatus.dialing.name).toList());
  }
}
