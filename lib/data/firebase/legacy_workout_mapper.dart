import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/workout_session.dart';
import '../seed/protocol_data.dart';
import 'firebase_mappers.dart';

/// Converte o schema legado do Firestore (`workoutHistory.sessions`) → [WorkoutSession].
/// Extraído para permitir testes sem Firebase.
abstract final class LegacyWorkoutMapper {
  static final _uuid = const Uuid();

  static WorkoutSession? mapSession(Map<String, dynamic> json) {
    final dayId = json['dayId'] as String?;
    final planId = FirebaseMappers.planIdFromDayId(dayId);
    if (planId == null) return null;

    final startedMs = json['startedAt'];
    final completedMs = json['completedAt'];
    if (startedMs is! int) return null;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
    final finishedAt = completedMs is int
        ? DateTime.fromMillisecondsSinceEpoch(completedMs)
        : startedAt;

    final plan = ProtocolData.planById(planId);
    final legacyExercises = json['exercises'];
    if (legacyExercises is! List) {
      return WorkoutSession(
        id: json['id'] as String? ?? 'session-$startedMs',
        workoutPlanId: planId,
        startedAt: startedAt,
        finishedAt: finishedAt,
        exercises: const [],
      );
    }

    final sessionExercises = <SessionExercise>[];
    for (var i = 0; i < legacyExercises.length; i++) {
      final ex = legacyExercises[i];
      if (ex is! Map) continue;
      final map = Map<String, dynamic>.from(ex);
      final exerciseId = FirebaseMappers.resolveExerciseId(
        map['exerciseId'] as String?,
        map['exerciseName'] as String?,
      );

      final setsRaw = map['sets'];
      final sets = <SetRecord>[];
      if (setsRaw is List) {
        for (final s in setsRaw) {
          if (s is! Map) continue;
          final setMap = Map<String, dynamic>.from(s);
          final index = setMap['setIndex'] as int? ?? sets.length;
          final ts = setMap['timestamp'];
          sets.add(
            SetRecord(
              id: _uuid.v4(),
              exerciseId: exerciseId,
              setType: inferSetType(planId, exerciseId, index),
              setNumber: index + 1,
              weight: (setMap['weight'] as num?)?.toDouble(),
              repetitions: setMap['reps'] as int?,
              rir: setMap['rir'] as int?,
              completed: true,
              completedAt: ts is int
                  ? DateTime.fromMillisecondsSinceEpoch(ts)
                  : finishedAt,
            ),
          );
        }
      }

      sessionExercises.add(
        SessionExercise(
          workoutExerciseId: '$planId-$exerciseId-$i',
          exerciseId: exerciseId,
          order: i + 1,
          sets: sets,
        ),
      );
    }

    if (plan != null && sessionExercises.isNotEmpty) {
      sessionExercises.sort((a, b) {
        final ao = plan.exercises
            .where((e) => e.exerciseId == a.exerciseId)
            .map((e) => e.order)
            .firstOrNull;
        final bo = plan.exercises
            .where((e) => e.exerciseId == b.exerciseId)
            .map((e) => e.order)
            .firstOrNull;
        return (ao ?? a.order).compareTo(bo ?? b.order);
      });
    }

    return WorkoutSession(
      id: json['id'] as String? ?? 'session-$startedMs',
      workoutPlanId: planId,
      startedAt: startedAt,
      finishedAt: finishedAt,
      exercises: sessionExercises,
    );
  }

  static List<WorkoutSession> mapSessions(Iterable<dynamic> raw) {
    final sessions = <WorkoutSession>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final mapped = mapSession(Map<String, dynamic>.from(item));
      if (mapped != null) sessions.add(mapped);
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  static SetType inferSetType(String planId, String exerciseId, int setIndex) {
    final plan = ProtocolData.planById(planId);
    if (plan == null) return SetType.working;
    final we = plan.exercises.where((e) => e.exerciseId == exerciseId);
    if (we.isEmpty) return SetType.working;
    final sets = we.first.sets;
    if (setIndex >= 0 && setIndex < sets.length) {
      return sets[setIndex].type;
    }
    return SetType.working;
  }

  static Map<String, dynamic> toLegacySession(WorkoutSession session) {
    final plan = ProtocolData.planById(session.workoutPlanId);
    final dayId =
        FirebaseMappers.dayIdFromPlanId(session.workoutPlanId) ?? 'segunda';
    final dayName = plan != null
        ? FirebaseMappers.dayNameFromWeekday(plan.weekday)
        : dayId;

    return {
      'id': session.id,
      'dayId': dayId,
      'dayName': dayName,
      'startedAt': session.startedAt.millisecondsSinceEpoch,
      'completedAt':
          (session.finishedAt ?? session.startedAt).millisecondsSinceEpoch,
      'totalDuration': session.duration?.inSeconds ?? 0,
      'exercises': session.exercises.map((ex) {
        final name =
            ProtocolData.exerciseById(ex.exerciseId)?.name ?? ex.exerciseId;
        return {
          'exerciseId': legacyExerciseId(session.workoutPlanId, ex),
          'exerciseName': name,
          'completedAt': ex.sets
                  .where((s) => s.completedAt != null)
                  .map((s) => s.completedAt!.millisecondsSinceEpoch)
                  .lastOrNull ??
              (session.finishedAt ?? session.startedAt).millisecondsSinceEpoch,
          'sets': [
            for (var i = 0; i < ex.sets.length; i++)
              if (ex.sets[i].completed)
                {
                  'setIndex': i,
                  'weight': ex.sets[i].weight ?? 0,
                  'reps': ex.sets[i].repetitions ?? 0,
                  'timestamp': (ex.sets[i].completedAt ??
                          session.finishedAt ??
                          session.startedAt)
                      .millisecondsSinceEpoch,
                  if (ex.sets[i].rir != null) 'rir': ex.sets[i].rir,
                },
          ],
        };
      }).toList(),
    };
  }

  static String legacyExerciseId(String planId, SessionExercise ex) {
    for (final entry in FirebaseMappers.legacyExerciseToId.entries) {
      if (entry.value == ex.exerciseId) {
        final prefix = switch (planId) {
          'plan_monday' => 'seg',
          'plan_tuesday' => 'ter',
          'plan_wednesday' => 'qua',
          'plan_friday' => 'sex',
          'plan_saturday' => 'sab',
          'plan_sunday' => 'dom',
          _ => null,
        };
        if (prefix != null && entry.key.startsWith('$prefix-')) {
          return entry.key;
        }
      }
    }
    return ex.exerciseId;
  }

  static int legacyCompletedSets(Map<String, dynamic> legacy) {
    final exercises = legacy['exercises'];
    if (exercises is! List) return 0;
    var count = 0;
    for (final ex in exercises) {
      if (ex is! Map) continue;
      final sets = ex['sets'];
      if (sets is List) count += sets.length;
    }
    return count;
  }
}
