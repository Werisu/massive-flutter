import 'enums.dart';

/// A planned set prescription from the protocol (not a logged set).
class SetPrescription {
  const SetPrescription({
    required this.type,
    required this.repMin,
    required this.repMax,
    this.setCount = 1,
    this.note,
    this.repsUnit = 'reps',
    this.restSeconds,
  });

  final SetType type;
  final int repMin;
  final int repMax;
  final int setCount;

  /// Carga, RPE ou cue da etapa. Ausente no protocolo original.
  final String? note;

  /// `reps` na musculação. `seg` quando a série é medida em segundos.
  final String repsUnit;

  /// Descanso depois desta série. Ausente quando vale a regra do exercício.
  final int? restSeconds;

  String get repsLabel {
    if (repMin == repMax) return '$repMin';
    return '$repMin-$repMax';
  }

  String get summaryLabel => '${setCount}x$repsLabel';

  /// Faixa com unidade e, quando houver, a orientação da etapa.
  String get doseLabel {
    final unit = repsUnit == 'seg' ? 'seg' : 'reps';
    if (note == null || note!.isEmpty) return '$repsLabel $unit';
    return '$repsLabel $unit · $note';
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'repMin': repMin,
    'repMax': repMax,
    'setCount': setCount,
    if (note != null) 'note': note,
    if (repsUnit != 'reps') 'repsUnit': repsUnit,
    if (restSeconds != null) 'restSeconds': restSeconds,
  };

  factory SetPrescription.fromJson(Map<String, dynamic> json) =>
      SetPrescription(
        type: SetType.values.byName(json['type'] as String),
        repMin: json['repMin'] as int,
        repMax: json['repMax'] as int,
        setCount: json['setCount'] as int? ?? 1,
        note: json['note'] as String?,
        repsUnit: json['repsUnit'] as String? ?? 'reps',
        restSeconds: json['restSeconds'] as int?,
      );
}

/// Rótulo de séries do mesmo tipo.
/// Reps iguais ficam "3x 8-10 reps". Reps diferentes ficam "3+4+5+6+7 reps".
String prescriptionGroupLabel(List<SetPrescription> sets) {
  if (sets.isEmpty) return '';
  final first = sets.first;
  final same = sets.every(
    (set) =>
        set.repMin == first.repMin &&
        set.repMax == first.repMax &&
        set.repsUnit == first.repsUnit &&
        set.note == first.note,
  );
  if (same) return '${sets.length}x ${first.doseLabel}';
  final sequence = sets.map((set) => set.repsLabel).join('+');
  final unit = first.repsUnit == 'seg' ? 'seg' : 'reps';
  final sharedNote =
      first.note != null &&
      first.note!.isNotEmpty &&
      sets.every((set) => set.note == first.note);
  final cue = sharedNote ? ' · ${first.note}' : '';
  return '$sequence $unit$cue';
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.order,
    required this.sets,
    this.focus,
    this.restSeconds,
    this.restLabel,
  });

  final String id;
  final String exerciseId;
  final int order;

  /// Expanded list of individual sets in order (warmup → prep → working).
  final List<SetPrescription> sets;

  /// Objetivo curto do slot, usado na divisão diferenciada.
  final String? focus;

  /// Descanso das séries valendo. O protocolo segue a preferência global.
  final int? restSeconds;

  /// Texto do descanso como está na prescrição ("90 seg", "2 a 3 min").
  final String? restLabel;

  int get totalSets => sets.length;

  int get workingSetsCount =>
      sets.where((s) => s.type == SetType.working).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'order': order,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (focus != null) 'focus': focus,
    if (restSeconds != null) 'restSeconds': restSeconds,
    if (restLabel != null) 'restLabel': restLabel,
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        order: json['order'] as int,
        sets: (json['sets'] as List)
            .map((e) => SetPrescription.fromJson(e as Map<String, dynamic>))
            .toList(),
        focus: json['focus'] as String?,
        restSeconds: json['restSeconds'] as int?,
        restLabel: json['restLabel'] as String?,
      );
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.weekday,
    required this.exercises,
    this.isDayOff = false,
    this.summary,
  });

  final String id;
  final String name;
  final Weekday weekday;
  final List<WorkoutExercise> exercises;
  final bool isDayOff;

  /// Frase curta do dia. O protocolo original não usa.
  final String? summary;

  int get exerciseCount => exercises.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weekday': weekday.name,
    'isDayOff': isDayOff,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    if (summary != null) 'summary': summary,
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    weekday: Weekday.values.byName(json['weekday'] as String),
    isDayOff: json['isDayOff'] as bool? ?? false,
    exercises: (json['exercises'] as List)
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
    summary: json['summary'] as String?,
  );
}
