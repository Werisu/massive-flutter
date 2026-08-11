import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
import '../models/user_preferences.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(Hive.box<String>(HiveBoxes.preferences));
});

class PreferencesRepository {
  PreferencesRepository(this._box);

  final Box<String> _box;
  static const _key = 'user_prefs';

  UserPreferences get() {
    final raw = _box.get(_key);
    if (raw == null) return const UserPreferences(userName: 'Wellysson');
    return UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(UserPreferences prefs) async {
    await _box.put(_key, jsonEncode(prefs.toJson()));
  }
}
