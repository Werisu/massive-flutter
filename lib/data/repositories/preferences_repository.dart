import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
import '../models/user_preferences.dart';
import '../services/custom_workout_week.dart';
import '../services/exercise_catalog.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(Hive.box<String>(HiveBoxes.preferences));
});

class PreferencesRepository {
  PreferencesRepository(Box<String> box) : this._(box.get, box.put);

  PreferencesRepository._(this._read, this._write);

  /// Repositório em memória, para testes que não precisam do Hive.
  PreferencesRepository.memory() : _stored = null {
    _read = (_) => _stored;
    _write = (_, value) async {
      _stored = value;
    };
  }

  late final String? Function(dynamic key) _read;
  late final Future<void> Function(dynamic key, String value) _write;
  String? _stored;
  static const _key = 'user_prefs';

  UserPreferences get() {
    final raw = _read(_key);
    final prefs = raw == null
        ? const UserPreferences(userName: 'Wellysson')
        : UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    ExerciseCatalog.setCustom(prefs.customExercises);
    CustomPlanCatalog.set(prefs.customPlans);
    return prefs;
  }

  Future<void> save(UserPreferences prefs) async {
    ExerciseCatalog.setCustom(prefs.customExercises);
    CustomPlanCatalog.set(prefs.customPlans);
    await _write(_key, jsonEncode(prefs.toJson()));
  }
}
