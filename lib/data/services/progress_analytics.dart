import '../models/enums.dart';
import '../models/workout_session.dart';
import '../seed/protocol_data.dart';
import 'history_grouping.dart';

enum ProgressPeriod {
  days7,
  days30,
  days90,
  all;

  String get label {
    switch (this) {
      case ProgressPeriod.days7:
        return '7 dias';
      case ProgressPeriod.days30:
        return '30 dias';
      case ProgressPeriod.days90:
        return '90 dias';
      case ProgressPeriod.all:
        return 'Tudo';
    }
  }

  DateTime? get cutoff {
    final now = DateTime.now();
    switch (this) {
      case ProgressPeriod.days7:
        return now.subtract(const Duration(days: 7));
      case ProgressPeriod.days30:
        return now.subtract(const Duration(days: 30));
      case ProgressPeriod.days90:
        return now.subtract(const Duration(days: 90));
      case ProgressPeriod.all:
        return null;
    }
  }
}

class WorkingSetPoint {
  const WorkingSetPoint({
    required this.at,
    required this.weight,
    required this.reps,
    required this.exerciseId,
    this.rir,
  });

  final DateTime at;
  final double weight;
  final int reps;
  final String exerciseId;
  final int? rir;

  double get volume => weight * reps;
}

class ExerciseBestMark {
  const ExerciseBestMark({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.at,
  });

  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime at;

  double get score => weight * reps;
}

class WeeklyVolumeBucket {
  const WeeklyVolumeBucket({
    required this.weekStart,
    required this.volume,
    required this.sessions,
  });

  final DateTime weekStart;
  final double volume;
  final int sessions;
}

class ProgressionTip {
  const ProgressionTip({
    required this.exerciseId,
    required this.exerciseName,
    required this.message,
    this.detail,
  });

  final String exerciseId;
  final String exerciseName;
  final String message;
  final String? detail;
}

abstract final class ProgressAnalytics {
  static List<WorkoutSession> filterSessions(
    List<WorkoutSession> sessions,
    ProgressPeriod period,
  ) {
    final cutoff = period.cutoff;
    final finished = sessions.where((s) => s.isFinished);
    if (cutoff == null) return finished.toList();
    return finished.where((s) => s.startedAt.isAfter(cutoff)).toList();
  }

  static List<WorkingSetPoint> workingPoints(
    List<WorkoutSession> sessions, {
    String? exerciseId,
    ProgressPeriod period = ProgressPeriod.all,
  }) {
    final filtered = filterSessions(sessions, period);
    final points = <WorkingSetPoint>[];
    for (final session in filtered) {
      for (final ex in session.exercises) {
        if (exerciseId != null && ex.exerciseId != exerciseId) continue;
        for (final set in ex.sets) {
          if (!set.completed || set.setType != SetType.working) continue;
          if (set.weight == null || set.repetitions == null) continue;
          points.add(
            WorkingSetPoint(
              at: set.completedAt ?? session.finishedAt ?? session.startedAt,
              weight: set.weight!,
              reps: set.repetitions!,
              exerciseId: ex.exerciseId,
              rir: set.rir,
            ),
          );
        }
      }
    }
    points.sort((a, b) => a.at.compareTo(b.at));
    return points;
  }

  static double totalVolume(
    List<WorkoutSession> sessions, {
    ProgressPeriod period = ProgressPeriod.all,
  }) {
    return workingPoints(sessions, period: period)
        .fold(0.0, (sum, p) => sum + p.volume);
  }

  static int trainingDayCount(
    List<WorkoutSession> sessions, {
    ProgressPeriod period = ProgressPeriod.all,
  }) {
    return HistoryGrouping.groupFinishedSessions(
      filterSessions(sessions, period),
    ).length;
  }

  static List<ExerciseBestMark> bestMarks(
    List<WorkoutSession> sessions, {
    ProgressPeriod period = ProgressPeriod.all,
    int limit = 8,
  }) {
    final byExercise = <String, WorkingSetPoint>{};
    for (final p in workingPoints(sessions, period: period)) {
      final current = byExercise[p.exerciseId];
      if (current == null ||
          p.weight > current.weight ||
          (p.weight == current.weight && p.reps > current.reps)) {
        byExercise[p.exerciseId] = p;
      }
    }

    final marks = byExercise.values.map((p) {
      final name =
          ProtocolData.exerciseById(p.exerciseId)?.name ?? p.exerciseId;
      return ExerciseBestMark(
        exerciseId: p.exerciseId,
        exerciseName: name,
        weight: p.weight,
        reps: p.reps,
        at: p.at,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return marks.take(limit).toList();
  }

  static List<WeeklyVolumeBucket> weeklyVolume(
    List<WorkoutSession> sessions, {
    int weeks = 8,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (weeks - 1) * 7 + now.weekday - 1));

    final buckets = <DateTime, WeeklyVolumeBucket>{};
    for (var i = 0; i < weeks; i++) {
      final weekStart = start.add(Duration(days: i * 7));
      buckets[weekStart] = WeeklyVolumeBucket(
        weekStart: weekStart,
        volume: 0,
        sessions: 0,
      );
    }

    final days = HistoryGrouping.groupFinishedSessions(sessions);
    for (final day in days) {
      final weekStart = DateTime(day.date.year, day.date.month, day.date.day)
          .subtract(Duration(days: day.date.weekday - 1));
      final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final existing = buckets[key];
      if (existing == null) continue;
      buckets[key] = WeeklyVolumeBucket(
        weekStart: existing.weekStart,
        volume: existing.volume + day.volume,
        sessions: existing.sessions + 1,
      );
    }

    return buckets.values.toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  /// Sugestões baseadas nas duas últimas performances de séries valendo.
  static List<ProgressionTip> progressionTips(
    List<WorkoutSession> sessions, {
    int limit = 6,
  }) {
    final tips = <ProgressionTip>[];
    for (final exercise in ProtocolData.exercises) {
      final points = workingPoints(sessions, exerciseId: exercise.id);
      if (points.length < 2) continue;

      final prev = points[points.length - 2];
      final curr = points.last;
      final tip = _tipFor(exercise.id, exercise.name, prev, curr);
      if (tip != null) tips.add(tip);
    }

    // Prioriza dicas de aumento de carga / topo da faixa
    tips.sort((a, b) {
      final aScore = a.message.contains('aumento') ? 2 : 1;
      final bScore = b.message.contains('aumento') ? 2 : 1;
      return bScore.compareTo(aScore);
    });
    return tips.take(limit).toList();
  }

  static ProgressionTip? tipForExercise(
    List<WorkoutSession> sessions,
    String exerciseId,
  ) {
    final exercise = ProtocolData.exerciseById(exerciseId);
    if (exercise == null) return null;
    final points = workingPoints(sessions, exerciseId: exerciseId);
    if (points.length < 2) {
      if (points.isEmpty) return null;
      final last = points.last;
      if (last.reps >= 10) {
        return ProgressionTip(
          exerciseId: exerciseId,
          exerciseName: exercise.name,
          message:
              'Você atingiu o topo da faixa. Considere um pequeno aumento de carga no próximo treino.',
          detail: '${last.weight.round()} kg × ${last.reps} reps',
        );
      }
      return null;
    }
    return _tipFor(
      exerciseId,
      exercise.name,
      points[points.length - 2],
      points.last,
    );
  }

  static ExerciseBestMark? bestMarkForExercise(
    List<WorkoutSession> sessions,
    String exerciseId,
  ) {
    final points = workingPoints(sessions, exerciseId: exerciseId);
    if (points.isEmpty) return null;
    WorkingSetPoint best = points.first;
    for (final p in points.skip(1)) {
      if (p.volume > best.volume) best = p;
    }
    final name =
        ProtocolData.exerciseById(exerciseId)?.name ?? exerciseId;
    return ExerciseBestMark(
      exerciseId: exerciseId,
      exerciseName: name,
      weight: best.weight,
      reps: best.reps,
      at: best.at,
    );
  }

  static ProgressionTip? _tipFor(
    String id,
    String name,
    WorkingSetPoint prev,
    WorkingSetPoint curr,
  ) {
    const targetMax = 10;

    if (curr.weight > prev.weight) {
      return ProgressionTip(
        exerciseId: id,
        exerciseName: name,
        message: 'Carga aumentada',
        detail:
            '${prev.weight.round()}kg × ${prev.reps} → ${curr.weight.round()}kg × ${curr.reps}',
      );
    }

    if (curr.weight == prev.weight && curr.reps > prev.reps) {
      final atTop = curr.reps >= targetMax;
      return ProgressionTip(
        exerciseId: id,
        exerciseName: name,
        message: atTop
            ? 'Topo da faixa (8–10). Considere um pequeno aumento de carga.'
            : 'Boa evolução: +${curr.reps - prev.reps} rep com a mesma carga',
        detail: '${curr.weight.round()} kg · ${prev.reps} → ${curr.reps} reps',
      );
    }

    if (curr.weight == prev.weight && curr.reps >= targetMax) {
      return ProgressionTip(
        exerciseId: id,
        exerciseName: name,
        message:
            'Você atingiu o topo da faixa. Considere um pequeno aumento de carga no próximo treino.',
        detail: '${curr.weight.round()} kg × ${curr.reps} reps',
      );
    }

    return null;
  }
}
