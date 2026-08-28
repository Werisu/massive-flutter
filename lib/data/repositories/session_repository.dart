import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../local/hive_boxes.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../seed/protocol_data.dart';
import '../services/exercise_catalog.dart';

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

  /// Histórico agrupado por dia de treino (mais recente primeiro).
  List<ExerciseDayLog> getExerciseDayHistory(String exerciseId) {
    final logs = <ExerciseDayLog>[];
    for (final session in getFinishedSessions()) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseId != exerciseId) continue;
        final working = exercise.sets
            .where((s) => s.completed && s.setType == SetType.working)
            .toList();
        if (working.isEmpty) continue;

        final date = working
                .map((s) => s.completedAt)
                .whereType<DateTime>()
                .fold<DateTime?>(
                  null,
                  (best, d) => best == null || d.isAfter(best) ? d : best,
                ) ??
            session.finishedAt ??
            session.startedAt;

        logs.add(
          ExerciseDayLog(
            date: DateTime(date.year, date.month, date.day),
            sessionId: session.id,
            workoutPlanId: session.workoutPlanId,
            sets: working,
          ),
        );
      }
    }

    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  Future<WorkoutSession> startSession(
    WorkoutPlan plan, {
    Map<String, String> substitutions = const {},
    List<Exercise> customExercises = const [],
  }) async {
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
        final resolved = _resolvedExerciseId(
          we,
          substitutions,
          customExercises,
        );
        final substituted = resolved != we.exerciseId;
        return SessionExercise(
          workoutExerciseId: we.id,
          exerciseId: resolved,
          originalExerciseId: substituted ? we.exerciseId : null,
          order: we.order,
          sets: [
            for (var i = 0; i < we.sets.length; i++)
              SetRecord(
                id: _uuid.v4(),
                exerciseId: resolved,
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
    required String workoutExerciseId,
    required int setIndex,
    required double? weight,
    required int? repetitions,
    required int? rir,
    String? notes,
  }) async {
    final exercises = session.exercises.map((ex) {
      if (ex.workoutExerciseId != workoutExerciseId) return ex;
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

  /// Marca série como não concluída (desfazer), preservando carga/reps digitadas.
  Future<WorkoutSession> uncompleteSet({
    required WorkoutSession session,
    required String workoutExerciseId,
    required int setIndex,
  }) async {
    final exercises = session.exercises.map((ex) {
      if (ex.workoutExerciseId != workoutExerciseId) return ex;
      final sets = [...ex.sets];
      final current = sets[setIndex];
      sets[setIndex] = current.copyWith(
        completed: false,
        clearCompletedAt: true,
      );
      return ex.copyWith(sets: sets);
    }).toList();

    final updated = session.copyWith(exercises: exercises);
    await _save(updated);
    return updated;
  }

  /// Atualiza valores de uma série já concluída.
  Future<WorkoutSession> editSet({
    required WorkoutSession session,
    required String workoutExerciseId,
    required int setIndex,
    required double? weight,
    required int? repetitions,
    required int? rir,
  }) async {
    final exercises = session.exercises.map((ex) {
      if (ex.workoutExerciseId != workoutExerciseId) return ex;
      final sets = [...ex.sets];
      final current = sets[setIndex];
      sets[setIndex] = current.copyWith(
        weight: weight,
        repetitions: repetitions,
        rir: rir,
        completed: true,
        completedAt: current.completedAt ?? DateTime.now(),
        clearWeight: weight == null,
        clearReps: repetitions == null,
        clearRir: rir == null,
      );
      return ex.copyWith(sets: sets);
    }).toList();

    final updated = session.copyWith(exercises: exercises);
    await _save(updated);
    return updated;
  }

  Future<WorkoutSession> replaceExercise({
    required WorkoutSession session,
    required String workoutExerciseId,
    required String newExerciseId,
    required String protocolExerciseId,
  }) async {
    final updated = session.replaceExercise(
      workoutExerciseId: workoutExerciseId,
      newExerciseId: newExerciseId,
      protocolExerciseId: protocolExerciseId,
    );
    await _save(updated);
    return updated;
  }

  Future<WorkoutSession> finishSession(WorkoutSession session) async {
    final updated = session.copyWith(finishedAt: DateTime.now());
    await _save(updated);
    await _activeBox.delete('id');
    return updated;
  }

  /// Importa sessões remotas com merge seguro (não apaga progresso local melhor).
  Future<int> mergeRemoteSessions(List<WorkoutSession> remote) async {
    var imported = 0;
    final activeId = getActiveSession()?.id;

    for (final session in remote) {
      final existingRaw = _sessionsBox.get(session.id);
      if (existingRaw == null) {
        await _save(session);
        imported++;
        continue;
      }

      final local = WorkoutSession.fromJson(
        jsonDecode(existingRaw) as Map<String, dynamic>,
      );

      // Não sobrescreve treino ativo em andamento.
      if (!local.isFinished && local.id == activeId) continue;

      final shouldReplace = _remoteIsPreferable(local: local, remote: session);
      if (shouldReplace) {
        await _save(session);
        imported++;
      }
    }
    return imported;
  }

  bool _remoteIsPreferable({
    required WorkoutSession local,
    required WorkoutSession remote,
  }) {
    if (remote.completedSets > local.completedSets) return true;
    if (remote.completedSets < local.completedSets) return false;

    final localDone = local.finishedAt;
    final remoteDone = remote.finishedAt;
    if (localDone == null && remoteDone != null) return true;
    if (localDone != null && remoteDone != null) {
      return remoteDone.isAfter(localDone);
    }
    return false;
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

  String _resolvedExerciseId(
    WorkoutExercise we,
    Map<String, String> substitutions,
    List<Exercise> customExercises,
  ) {
    final replacement = substitutions[we.id];
    if (replacement == null || replacement.isEmpty) return we.exerciseId;
    ExerciseCatalog.setCustom(customExercises);
    if (ExerciseCatalog.byId(replacement) == null) return we.exerciseId;
    return replacement;
  }
}

/// Um dia com séries valendo registradas para um exercício.
class ExerciseDayLog {
  const ExerciseDayLog({
    required this.date,
    required this.sessionId,
    required this.workoutPlanId,
    required this.sets,
  });

  final DateTime date;
  final String sessionId;
  final String workoutPlanId;
  final List<SetRecord> sets;

  double get volume {
    var v = 0.0;
    for (final s in sets) {
      if (s.weight != null && s.repetitions != null) {
        v += s.weight! * s.repetitions!;
      }
    }
    return v;
  }

  SetRecord? get bestSet {
    SetRecord? best;
    var bestScore = -1.0;
    for (final s in sets) {
      if (s.weight == null || s.repetitions == null) continue;
      final score = s.weight! * s.repetitions!;
      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }
    return best;
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
