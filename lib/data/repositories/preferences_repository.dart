import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
import '../models/user_preferences.dart';
import '../services/exercise_catalog.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(Hive.box<String>(HiveBoxes.preferences));
});

class PreferencesRepository {
  PreferencesRepository(this._box);

  final Box<String> _box;
  static const _key = 'user_prefs';

  UserPreferences get() {
    final raw = _box.get(_key);
    final prefs = raw == null
        ? const UserPreferences(userName: 'Wellysson')
        : UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    ExerciseCatalog.setCustom(prefs.customExercises);
    return prefs;
  }

  Future<void> save(UserPreferences prefs) async {
    ExerciseCatalog.setCustom(prefs.customExercises);
    await _box.put(_key, jsonEncode(prefs.toJson()));
  }
}
