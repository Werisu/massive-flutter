import 'package:hive_flutter/hive_flutter.dart';

abstract final class HiveBoxes {
  static const sessions = 'sessions';
  static const preferences = 'preferences';
  static const activeSession = 'active_session';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(sessions),
      Hive.openBox<String>(preferences),
      Hive.openBox<String>(activeSession),
    ]);
  }
}
