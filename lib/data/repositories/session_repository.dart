import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../local/hive_boxes.dart';
import '../models/enums.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../seed/protocol_data.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    sessionsBox: Hive.box<String>(HiveBoxes.sessions),
    activeBox: Hive.box<String>(HiveBoxes.activeSession),
  );
});

class SessionRepository {
  SessionRepository({
    required this._sessionsBox,
    required this._activeBox,
  });

  final Box<String> _sessionsBox;
  final Box<String> _activeBox;
  final _uuid = const Uuid();

  List<WorkoutSession> getAllSessions() {
    final sessions = _sessionsBox.values
        .map((raw) => WorkoutSession.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ))
        .toList();
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  List<WorkoutSession> getFinishedSessions() {
    return getAllSessions().where((s) => s.isFinished).toList();
  }

  WorkoutSession? getById(String id) {
    final raw = _sessionsBox.get(id);
    if (raw == null) return null;
    return WorkoutSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  WorkoutSession? getActiveSession() {
    final id = _activeBox.get('id');
    if (id == null) return null;
    return getById(id);
  }

  WorkoutSession? getLastFinishedSession() {
    final finished = getFinishedSessions();
    if (finished.isEmpty) return null;
    return finished.first;
  }

  /// Last completed set for an exercise across finished sessions.
  SetRecord? getLastWorkingSet(String exerciseId) {
    return getLastSetOfType(exerciseId, SetType.working) ??
        _lastAnyCompletedSet(exerciseId);
  }

  /// Última série concluída do tipo indicado (mais recente primeiro).
  SetRecord? getLastSetOfType(String exerciseId, SetType type) {
    for (final session in getFinishedSessions()) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseId != exerciseId) continue;
        final matches = exercise.sets
            .where((s) => s.completed && s.setType == type)
            .toList();
        if (matches.isNotEmpty) return matches.last;
      }
    }
    return null;
  }

  SetRecord? _lastAnyCompletedSet(String exerciseId) {
    for (final session in getFinishedSessions()) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseId != exerciseId) continue;
        final any = exercise.sets.where((s) => s.completed).toList();
        if (any.isNotEmpty) return any.last;
      }
    }
    return null;
  }

  /// Sugestão de pré-preenchimento: sessão atual → mesmo tipo histórico → valendo.
  PrefillSuggestion? suggestPrefill({
    required String exerciseId,
    required SetType setType,
    required List<SetRecord> currentSets,
    required int currentSetIndex,
  }) {
    SetRecord? fromSession;
    for (var i = currentSetIndex - 1; i >= 0; i--) {
      final s = currentSets[i];
      if (!s.completed) continue;
      if (s.weight == null && s.repetitions == null) continue;
      fromSession = s;
      if (s.setType == setType) break;
    }

    final lastSameType = getLastSetOfType(exerciseId, setType);
    final lastWorking = getLastSetOfType(exerciseId, SetType.working);

    final source = fromSession ?? lastSameType ?? lastWorking;
    if (source == null) return null;

    final fromHistory = fromSession == null;
    return PrefillSuggestion(
      weight: source.weight,
      repetitions: source.repetitions,
      rir: source.rir,
      fromHistory: fromHistory,
      sourceType: source.setType,
    );
  }

  /// History of completed working sets for charts (oldest → newest).
  List<SetRecord> getExerciseWorkingHistory(String exerciseId) {
    final records = <SetRecord>[];
    for (final session in getFinishedSessions().reversed) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseId != exerciseId) continue;
        for (final set in exercise.sets) {
          if (set.completed && set.setType == SetType.working) {
            records.add(set);
          }
        }
      }
    }
    return records;
  }

  Future<WorkoutSession> startSession(WorkoutPlan plan) async {
    final existing = getActiveSession();
    if (existing != null && !existing.isFinished) {
      if (existing.workoutPlanId == plan.id) {
        return existing;
      }
      await discardActiveSession();
    }

    final session = WorkoutSession(
      id: _uuid.v4(),
      workoutPlanId: plan.id,
      startedAt: DateTime.now(),
      exercises: plan.exercises.map((we) {
        return SessionExercise(
          workoutExerciseId: we.id,
          exerciseId: we.exerciseId,
          order: we.order,
          sets: [
            for (var i = 0; i < we.sets.length; i++)
              SetRecord(
                id: _uuid.v4(),
                exerciseId: we.exerciseId,
                setType: we.sets[i].type,
                setNumber: i + 1,
              ),
          ],
        );
      }).toList(),
    );

    await _save(session);
    await _activeBox.put('id', session.id);
    return session;
  }

  Future<void> updateSession(WorkoutSession session) async {
    await _save(session);
  }

  Future<WorkoutSession> completeSet({
    required WorkoutSession session,
    required String exerciseId,
    required int setIndex,
    required double? weight,
    required int? repetitions,
    required int? rir,
    String? notes,
  }) async {
    final exercises = session.exercises.map((ex) {
      if (ex.exerciseId != exerciseId) return ex;
      final sets = [...ex.sets];
      final current = sets[setIndex];
      sets[setIndex] = current.copyWith(
        weight: weight,
        repetitions: repetitions,
        rir: rir,
        notes: notes,
        completed: true,
        completedAt: DateTime.now(),
      );
      return ex.copyWith(sets: sets);
    }).toList();

    final updated = session.copyWith(exercises: exercises);
    await _save(updated);
    return updated;
  }

  Future<WorkoutSession> finishSession(WorkoutSession session) async {
    final updated = session.copyWith(finishedAt: DateTime.now());
    await _save(updated);
    await _activeBox.delete('id');
    return updated;
  }

  /// Importa sessões remotas sem sobrescrever locais com mesmo id.
  Future<int> mergeRemoteSessions(List<WorkoutSession> remote) async {
    var imported = 0;
    for (final session in remote) {
      final existing = _sessionsBox.get(session.id);
      if (existing == null) {
        await _save(session);
        imported++;
      }
    }
    return imported;
  }

  Future<void> discardActiveSession() async {
    final active = getActiveSession();
    if (active != null && !active.isFinished) {
      await _sessionsBox.delete(active.id);
    }
    await _activeBox.delete('id');
  }

  Future<void> _save(WorkoutSession session) async {
    await _sessionsBox.put(session.id, jsonEncode(session.toJson()));
  }

  int get completedWorkoutCount => getFinishedSessions().length;

  double get totalVolume {
    var volume = 0.0;
    for (final session in getFinishedSessions()) {
      for (final ex in session.exercises) {
        for (final set in ex.sets) {
          if (set.completed && set.weight != null && set.repetitions != null) {
            volume += set.weight! * set.repetitions!;
          }
        }
      }
    }
    return volume;
  }

  WorkoutPlan? planForSession(WorkoutSession session) {
    return ProtocolData.planById(session.workoutPlanId);
  }
}

class PrefillSuggestion {
  const PrefillSuggestion({
    this.weight,
    this.repetitions,
    this.rir,
    required this.fromHistory,
    required this.sourceType,
  });

  final double? weight;
  final int? repetitions;
  final int? rir;
  final bool fromHistory;
  final SetType sourceType;
}
