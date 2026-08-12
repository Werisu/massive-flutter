import 'package:collection/collection.dart';

import '../models/workout_session.dart';
import '../seed/protocol_data.dart';

/// Um dia de treino lógico (pode unificar várias sessões fragmentadas).
class WorkoutDaySummary {
  const WorkoutDaySummary({
    required this.id,
    required this.date,
    required this.workoutPlanId,
    required this.sessions,
    required this.exercises,
  });

  /// Chave estável: `yyyy-MM-dd_planId`
  final String id;
  final DateTime date;
  final String workoutPlanId;
  final List<WorkoutSession> sessions;
  final List<SessionExercise> exercises;

  int get sessionCount => sessions.length;
  int get exerciseCount => exercises.length;
  int get completedExercises =>
      exercises.where((e) => e.isCompleted || e.completedSets > 0).length;

  Duration? get totalDuration {
    Duration sum = Duration.zero;
    var any = false;
    for (final s in sessions) {
      final d = s.duration;
      if (d != null) {
        sum += d;
        any = true;
      }
    }
    return any ? sum : null;
  }

  double get volume {
    var v = 0.0;
    for (final ex in exercises) {
      for (final set in ex.sets) {
        if (set.completed && set.weight != null && set.repetitions != null) {
          v += set.weight! * set.repetitions!;
        }
      }
    }
    return v;
  }

  String get title {
    final plan = ProtocolData.planById(workoutPlanId);
    if (plan == null) return 'Treino';
    return '${plan.weekday.labelPt} — ${plan.name}';
  }
}

/// Agrupa sessões finalizadas por dia civil + plano de treino.
abstract final class HistoryGrouping {
  static String dayKey(DateTime date, String planId) {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-${day}_$planId';
  }

  static List<WorkoutDaySummary> groupFinishedSessions(
    List<WorkoutSession> sessions,
  ) {
    final finished = sessions.where((s) => s.isFinished).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final map = <String, List<WorkoutSession>>{};
    for (final s in finished) {
      final key = dayKey(s.startedAt, s.workoutPlanId);
      map.putIfAbsent(key, () => []).add(s);
    }

    final days = <WorkoutDaySummary>[];
    for (final entry in map.entries) {
      final group = entry.value
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      final first = group.first;
      final date = DateTime(
        first.startedAt.year,
        first.startedAt.month,
        first.startedAt.day,
      );
      days.add(
        WorkoutDaySummary(
          id: entry.key,
          date: date,
          workoutPlanId: first.workoutPlanId,
          sessions: List.unmodifiable(group),
          exercises: _mergeExercises(group),
        ),
      );
    }

    days.sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  static WorkoutDaySummary? findById(
    List<WorkoutSession> sessions,
    String dayId,
  ) {
    for (final day in groupFinishedSessions(sessions)) {
      if (day.id == dayId) return day;
    }
    return null;
  }

  /// Une exercícios de várias sessões do mesmo dia.
  /// Se o mesmo exerciseId aparecer mais de uma vez, fica a versão com mais séries concluídas.
  static List<SessionExercise> _mergeExercises(List<WorkoutSession> group) {
    final byId = <String, SessionExercise>{};
    final order = <String>[];

    for (final session in group) {
      for (final ex in session.exercises) {
        final existing = byId[ex.exerciseId];
        if (existing == null) {
          byId[ex.exerciseId] = ex;
          order.add(ex.exerciseId);
          continue;
        }
        if (ex.completedSets > existing.completedSets ||
            (ex.completedSets == existing.completedSets &&
                ex.sets.length > existing.sets.length)) {
          byId[ex.exerciseId] = ex;
        }
      }
    }

    // Ordena pela ordem do plano quando possível
    final plan = ProtocolData.planById(group.first.workoutPlanId);
    if (plan != null) {
      order.sort((a, b) {
        final ao = plan.exercises
            .where((e) => e.exerciseId == a)
            .map((e) => e.order)
            .firstOrNull;
        final bo = plan.exercises
            .where((e) => e.exerciseId == b)
            .map((e) => e.order)
            .firstOrNull;
        return (ao ?? 999).compareTo(bo ?? 999);
      });
    }

    return [
      for (var i = 0; i < order.length; i++)
        byId[order[i]]!.copyWith(order: i + 1),
    ];
  }
}
