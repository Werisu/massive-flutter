import 'enums.dart';

/// A planned set prescription from the protocol (not a logged set).
class SetPrescription {
  const SetPrescription({
    required this.type,
    required this.repMin,
    required this.repMax,
    this.setCount = 1,
  });

  final SetType type;
  final int repMin;
  final int repMax;
  final int setCount;

  String get repsLabel {
    if (repMin == repMax) return '$repMin';
    return '$repMin-$repMax';
  }

  String get summaryLabel => '${setCount}x$repsLabel';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'repMin': repMin,
        'repMax': repMax,
        'setCount': setCount,
      };

  factory SetPrescription.fromJson(Map<String, dynamic> json) =>
      SetPrescription(
        type: SetType.values.byName(json['type'] as String),
        repMin: json['repMin'] as int,
        repMax: json['repMax'] as int,
        setCount: json['setCount'] as int? ?? 1,
      );
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.order,
    required this.sets,
  });

  final String id;
  final String exerciseId;
  final int order;

  /// Expanded list of individual sets in order (warmup → prep → working).
  final List<SetPrescription> sets;

  int get totalSets => sets.length;

  int get workingSetsCount =>
      sets.where((s) => s.type == SetType.working).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'order': order,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        order: json['order'] as int,
        sets: (json['sets'] as List)
            .map((e) => SetPrescription.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.weekday,
    required this.exercises,
    this.isDayOff = false,
  });

  final String id;
  final String name;
  final Weekday weekday;
  final List<WorkoutExercise> exercises;
  final bool isDayOff;

  int get exerciseCount => exercises.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weekday': weekday.name,
        'isDayOff': isDayOff,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        weekday: Weekday.values.byName(json['weekday'] as String),
        isDayOff: json['isDayOff'] as bool? ?? false,
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
