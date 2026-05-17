import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static final HiveService instance = HiveService._internal();
  HiveService._internal();

  static const String messagesBoxName = 'cached_messages';
  static const String profileBoxName = 'user_profile';

  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    await Hive.openBox(messagesBoxName);
    await Hive.openBox(profileBoxName);
  }

  Box get messagesBox => Hive.box(messagesBoxName);
  Box get profileBox => Hive.box(profileBoxName);

  Future<void> cacheMessage(String roomId, Map<String, dynamic> messageData) async {
    final List<dynamic> roomMessages = messagesBox.get(roomId, defaultValue: []);
    final List<Map<String, dynamic>> updated = List<Map<String, dynamic>>.from(roomMessages);
    
    // Avoid duplicates
    if (!updated.any((m) => m['id'] == messageData['id'])) {
      updated.add(messageData);
      await messagesBox.put(roomId, updated);
    }
  }

  List<Map<String, dynamic>> getCachedMessages(String roomId) {
    final List<dynamic> raw = messagesBox.get(roomId, defaultValue: []);
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> clearChatCache(String roomId) async {
    await messagesBox.delete(roomId);
  }

  Future<void> saveSession(Map<String, dynamic> data) async => await profileBox.put('session', data);
  Map<String, dynamic>? getSession() => profileBox.get('session') != null ? Map<String, dynamic>.from(profileBox.get('session')) : null;
  Future<void> clearSession() async => await profileBox.delete('session');

  Future<void> setProfileCompleted(bool completed) async => await profileBox.put('profile_completed', completed);
  bool isProfileCompleted() => profileBox.get('profile_completed', defaultValue: false);
}
