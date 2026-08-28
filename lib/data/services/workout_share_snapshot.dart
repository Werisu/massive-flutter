import '../../core/utils/formatters.dart';
import '../models/enums.dart';
import '../models/workout_session.dart';
import 'exercise_catalog.dart';
import 'history_grouping.dart';

class WorkoutShareSet {
  const WorkoutShareSet({
    required this.weight,
    required this.reps,
    this.rir,
    this.isPr = false,
  });

  final double weight;
  final int reps;
  final int? rir;
  final bool isPr;

  String get loadLabel {
    final w = weight == weight.roundToDouble()
        ? '${weight.toInt()}'
        : weight.toStringAsFixed(1);
    return '$w×$reps';
  }
}

enum ShareProgressKind { none, weightUp, repsUp }

class WorkoutShareExercise {
  const WorkoutShareExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.progressKind = ShareProgressKind.none,
    this.progressLabel,
  });

  final String exerciseId;
  final String name;
  final List<WorkoutShareSet> sets;
  final ShareProgressKind progressKind;
  final String? progressLabel;

  bool get hasPr => sets.any((s) => s.isPr);
}

class WorkoutShareSnapshot {
  const WorkoutShareSnapshot({
    required this.athleteName,
    required this.workoutTitle,
    required this.date,
    required this.volumeKg,
    required this.workingSetCount,
    required this.exerciseCount,
    required this.trainingDayNumber,
    required this.exercises,
    this.duration,
    this.hiitCompleted = false,
  });

  final String athleteName;
  final String workoutTitle;
  final DateTime date;
  final Duration? duration;
  final double volumeKg;
  final int workingSetCount;
  final int exerciseCount;
  final int trainingDayNumber;
  final bool hiitCompleted;
  final List<WorkoutShareExercise> exercises;

  int get prCount => exercises.where((e) => e.hasPr).length;

  String get dateLabel {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String get fileStem {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'massive-arms-$y-$m-$d';
  }

  String get shareCaption {
    final stats = <String>[
      formatVolumeKg(volumeKg),
      if (duration != null) formatDurationShort(duration!),
      '$exerciseCount ${exerciseCount == 1 ? 'exercício' : 'exercícios'}',
    ];
    final lines = <String>[
      '$workoutTitle · $dateLabel',
      stats.join(' · '),
    ];
    if (prCount > 0) {
      lines.add('$prCount ${prCount == 1 ? 'recorde pessoal' : 'recordes pessoais'}');
    }
    if (hiitCompleted) lines.add('HIIT concluído');
    lines.add('');
    lines.add('Treino com Massive Arms');
    lines.add('Dev: Wellysson N Rocha');
    return lines.join('\n');
  }

  /// Monta o card a partir do dia unificado e do histórico (PRs / progressão).
  static WorkoutShareSnapshot fromDay({
    required WorkoutDaySummary day,
    required List<WorkoutSession> allFinishedSessions,
    required String athleteName,
    bool hiitCompleted = false,
  }) {
    final historical = <String, _ExerciseHistory>{};
    for (final session in allFinishedSessions) {
      if (!session.isFinished) continue;
      if (!_isBeforeDay(session.startedAt, day.date)) continue;
      for (final ex in session.exercises) {
        final bucket = historical.putIfAbsent(
          ex.exerciseId,
          _ExerciseHistory.new,
        );
        for (final set in ex.sets) {
          if (!_isWorking(set)) continue;
          bucket.add(set, session.startedAt);
        }
      }
    }

    final shareExercises = <WorkoutShareExercise>[];
    var volume = 0.0;
    var workingSets = 0;

    for (final ex in day.exercises) {
      final completedWorking = ex.sets.where(_isWorking).toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      if (completedWorking.isEmpty) continue;

      final history = historical[ex.exerciseId];
      final shareSets = [
        for (final set in completedWorking)
          WorkoutShareSet(
            weight: set.weight!,
            reps: set.repetitions!,
            rir: set.rir,
            isPr: history != null && history.isPersonalRecord(set),
          ),
      ];

      for (final set in completedWorking) {
        volume += set.weight! * set.repetitions!;
        workingSets++;
      }

      final progress = _progressAgainst(history, completedWorking);

      shareExercises.add(
        WorkoutShareExercise(
          exerciseId: ex.exerciseId,
          name: ExerciseCatalog.nameOf(ex.exerciseId),
          sets: shareSets,
          progressKind: progress.$1,
          progressLabel: progress.$2,
        ),
      );
    }

    final daysUpToHere = HistoryGrouping.groupFinishedSessions(
      allFinishedSessions.where((s) {
        if (!s.isFinished) return false;
        return !_isAfterDay(s.startedAt, day.date);
      }).toList(),
    );

    return WorkoutShareSnapshot(
      athleteName: athleteName.trim().isEmpty ? 'Atleta' : athleteName.trim(),
      workoutTitle: day.title,
      date: day.date,
      duration: day.totalDuration,
      volumeKg: volume,
      workingSetCount: workingSets,
      exerciseCount: shareExercises.length,
      trainingDayNumber: daysUpToHere.length,
      hiitCompleted: hiitCompleted,
      exercises: shareExercises,
    );
  }
}

bool _isWorking(SetRecord set) =>
    set.completed &&
    set.setType == SetType.working &&
    set.weight != null &&
    set.repetitions != null;

bool _isBeforeDay(DateTime at, DateTime day) {
  final a = DateTime(at.year, at.month, at.day);
  final b = DateTime(day.year, day.month, day.day);
  return a.isBefore(b);
}

bool _isAfterDay(DateTime at, DateTime day) {
  final a = DateTime(at.year, at.month, at.day);
  final b = DateTime(day.year, day.month, day.day);
  return a.isAfter(b);
}

(ShareProgressKind, String?) _progressAgainst(
  _ExerciseHistory? history,
  List<SetRecord> today,
) {
  if (history == null || history.lastBest == null) {
    return (ShareProgressKind.none, null);
  }
  final prev = history.lastBest!;
  WorkoutShareSet? bestToday;
  for (final set in today) {
    final candidate = WorkoutShareSet(
      weight: set.weight!,
      reps: set.repetitions!,
    );
    if (bestToday == null ||
        candidate.weight > bestToday.weight ||
        (candidate.weight == bestToday.weight &&
            candidate.reps > bestToday.reps)) {
      bestToday = candidate;
    }
  }
  if (bestToday == null) return (ShareProgressKind.none, null);

  if (bestToday.weight > prev.weight) {
    final delta = bestToday.weight - prev.weight;
    final label = delta == delta.roundToDouble()
        ? 'Carga +${delta.toInt()} kg'
        : 'Carga +${delta.toStringAsFixed(1)} kg';
    return (ShareProgressKind.weightUp, label);
  }
  if (bestToday.weight == prev.weight && bestToday.reps > prev.reps) {
    final extra = bestToday.reps - prev.reps;
    return (
      ShareProgressKind.repsUp,
      '+$extra ${extra == 1 ? 'rep' : 'reps'}',
    );
  }
  return (ShareProgressKind.none, null);
}

class _ExerciseHistory {
  _BestMark? bestEver;
  _BestMark? lastBest;
  DateTime? lastDay;

  void add(SetRecord set, DateTime at) {
    final mark = _BestMark(weight: set.weight!, reps: set.repetitions!);
    if (bestEver == null || mark.beats(bestEver!)) {
      bestEver = mark;
    }

    final day = DateTime(at.year, at.month, at.day);
    if (lastDay == null || day.isAfter(lastDay!)) {
      lastDay = day;
      lastBest = mark;
    } else if (day == lastDay && (lastBest == null || mark.beats(lastBest!))) {
      lastBest = mark;
    }
  }

  bool isPersonalRecord(SetRecord set) {
    final ever = bestEver;
    if (ever == null) return false;
    return _BestMark(weight: set.weight!, reps: set.repetitions!).beats(ever);
  }
}

class _BestMark {
  const _BestMark({required this.weight, required this.reps});

  final double weight;
  final int reps;

  bool beats(_BestMark other) {
    if (weight > other.weight) return true;
    if (weight == other.weight && reps > other.reps) return true;
    return false;
  }
}
