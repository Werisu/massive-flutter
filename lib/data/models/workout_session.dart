import 'enums.dart';

class SetRecord {
  const SetRecord({
    required this.id,
    required this.exerciseId,
    required this.setType,
    required this.setNumber,
    this.weight,
    this.repetitions,
    this.rir,
    this.completedAt,
    this.notes,
    this.completed = false,
  });

  final String id;
  final String exerciseId;
  final SetType setType;
  final int setNumber;
  final double? weight;
  final int? repetitions;
  final int? rir;
  final DateTime? completedAt;
  final String? notes;
  final bool completed;

  SetRecord copyWith({
    String? id,
    String? exerciseId,
    SetType? setType,
    int? setNumber,
    double? weight,
    int? repetitions,
    int? rir,
    DateTime? completedAt,
    String? notes,
    bool? completed,
    bool clearWeight = false,
    bool clearReps = false,
    bool clearRir = false,
    bool clearCompletedAt = false,
  }) {
    return SetRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      setType: setType ?? this.setType,
      setNumber: setNumber ?? this.setNumber,
      weight: clearWeight ? null : (weight ?? this.weight),
      repetitions: clearReps ? null : (repetitions ?? this.repetitions),
      rir: clearRir ? null : (rir ?? this.rir),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'setType': setType.name,
        'setNumber': setNumber,
        'weight': weight,
        'repetitions': repetitions,
        'rir': rir,
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
        'completed': completed,
      };

  factory SetRecord.fromJson(Map<String, dynamic> json) => SetRecord(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        setType: SetType.values.byName(json['setType'] as String),
        setNumber: json['setNumber'] as int,
        weight: (json['weight'] as num?)?.toDouble(),
        repetitions: json['repetitions'] as int?,
        rir: json['rir'] as int?,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        notes: json['notes'] as String?,
        completed: json['completed'] as bool? ?? false,
      );
}

class SessionExercise {
  const SessionExercise({
    required this.workoutExerciseId,
    required this.exerciseId,
    required this.order,
    required this.sets,
  });

  final String workoutExerciseId;
  final String exerciseId;
  final int order;
  final List<SetRecord> sets;

  bool get isCompleted =>
      sets.isNotEmpty && sets.every((s) => s.completed);

  int get completedSets => sets.where((s) => s.completed).length;

  SessionExercise copyWith({
    String? workoutExerciseId,
    String? exerciseId,
    int? order,
    List<SetRecord>? sets,
  }) {
    return SessionExercise(
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toJson() => {
        'workoutExerciseId': workoutExerciseId,
        'exerciseId': exerciseId,
        'order': order,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory SessionExercise.fromJson(Map<String, dynamic> json) =>
      SessionExercise(
        workoutExerciseId: json['workoutExerciseId'] as String,
        exerciseId: json['exerciseId'] as String,
        order: json['order'] as int,
        sets: (json['sets'] as List)
            .map((e) => SetRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.workoutPlanId,
    required this.startedAt,
    this.finishedAt,
    required this.exercises,
    this.notes,
  });

  final String id;
  final String workoutPlanId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<SessionExercise> exercises;
  final String? notes;

  bool get isFinished => finishedAt != null;

  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get completedSets =>
      exercises.fold(0, (sum, e) => sum + e.completedSets);

  int get completedExercises =>
      exercises.where((e) => e.isCompleted).length;

  double get progress =>
      totalSets == 0 ? 0 : completedSets / totalSets;

  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  WorkoutSession copyWith({
    String? id,
    String? workoutPlanId,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<SessionExercise>? exercises,
    String? notes,
    bool clearFinishedAt = false,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutPlanId': workoutPlanId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'notes': notes,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      WorkoutSession(
        id: json['id'] as String,
        workoutPlanId: json['workoutPlanId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'] as String)
            : null,
        exercises: (json['exercises'] as List)
            .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
      );
}
