import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDB {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('messages');
    await Hive.openBox('profiles');
  }

  static Box get messages => Hive.box('messages');
  static Box get profiles => Hive.box('profiles');
}
