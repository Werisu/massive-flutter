import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import 'exercise_media.dart';
import 'exercise_substitutions.dart';

/// Protocol data from "Massive Arms and Shoulders" as documented in instruction.md.
/// Do not invent exercises or alter set/rep structure.
abstract final class ProtocolData {
  static Exercise _withMedia(Exercise e) {
    final video = ExerciseMedia.videoUrlFor(e.id);
    final thumb = ExerciseMedia.thumbnailUrlFor(e.id);
    if (video == null && thumb == null) return e;
    return Exercise(
      id: e.id,
      name: e.name,
      muscleGroup: e.muscleGroup,
      description: e.description,
      videoUrl: video ?? e.videoUrl,
      thumbnailUrl: thumb ?? e.thumbnailUrl,
      instructions: e.instructions,
    );
  }

  /// Exercícios do protocolo + variações disponíveis para substituição.
  static List<Exercise> get catalog =>
      [...exercises, ...ExerciseSubstitutions.alternatives]
          .map(_withMedia)
          .toList(growable: false);
  static List<SetPrescription> _expand({
    int warmupSets = 0,
    int warmupReps = 10,
    int prepSets = 0,
    int prepRepMin = 2,
    int prepRepMax = 7,
    int workingSets = 0,
    int workingRepMin = 8,
    int workingRepMax = 10,
  }) {
    final sets = <SetPrescription>[];
    for (var i = 0; i < warmupSets; i++) {
      sets.add(SetPrescription(
        type: SetType.warmup,
        repMin: warmupReps,
        repMax: warmupReps,
      ));
    }
    for (var i = 0; i < prepSets; i++) {
      sets.add(SetPrescription(
        type: SetType.preparation,
        repMin: prepRepMin,
        repMax: prepRepMax,
      ));
    }
    for (var i = 0; i < workingSets; i++) {
      sets.add(SetPrescription(
        type: SetType.working,
        repMin: workingRepMin,
        repMax: workingRepMax,
      ));
    }
    return sets;
  }

  static WorkoutExercise _we({
    required String id,
    required String exerciseId,
    required int order,
    required List<SetPrescription> sets,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      order: order,
      sets: sets,
    );
  }

  static final List<Exercise> exercises = [
    // Monday
    const Exercise(id: 'ex_triceps_barra_v', name: 'Tríceps Barra V de Costas', muscleGroup: MuscleGroup.triceps),
    const Exercise(id: 'ex_triceps_polia_caneleira', name: 'Tríceps Polia Alta Caneleira', muscleGroup: MuscleGroup.triceps),
    const Exercise(id: 'ex_posterior_45', name: 'Posterior 45 Graus', muscleGroup: MuscleGroup.back),
    const Exercise(id: 'ex_puxada_pronada_media', name: 'Puxada Pronada Polia Média', muscleGroup: MuscleGroup.back),
    const Exercise(id: 'ex_puxada_unilateral', name: 'Puxada Unilateral Variação', muscleGroup: MuscleGroup.back),
    const Exercise(id: 'ex_remada_pronada', name: 'Remada Pronada Máquina', muscleGroup: MuscleGroup.back),
    // Tuesday
    const Exercise(id: 'ex_pant_leg_press', name: 'Panturrilha Leg Press Horizontal', muscleGroup: MuscleGroup.calves),
    const Exercise(id: 'ex_mesa_flexora', name: 'Mesa ou Cadeira Flexora', muscleGroup: MuscleGroup.legs),
    const Exercise(id: 'ex_agachamento_smith_hack', name: 'Agachamento Smith ou Hack Squat', muscleGroup: MuscleGroup.legs),
    const Exercise(id: 'ex_stiff_barra', name: 'Stiff Barra', muscleGroup: MuscleGroup.legs),
    const Exercise(id: 'ex_extensora_uni', name: 'Extensora Unilateral', muscleGroup: MuscleGroup.legs),
    const Exercise(id: 'ex_adutora', name: 'Cadeira Adutora', muscleGroup: MuscleGroup.legs),
    // Wednesday
    const Exercise(id: 'ex_martelo', name: 'Martelo Bilateral-Unilateral', muscleGroup: MuscleGroup.biceps),
    const Exercise(id: 'ex_rosca_polia_uni', name: 'Rosca Polia Unilateral', muscleGroup: MuscleGroup.biceps),
    const Exercise(id: 'ex_elev_lateral_tras', name: 'Elevação Lateral por Trás do Corpo', muscleGroup: MuscleGroup.shoulders),
    const Exercise(id: 'ex_supino_inclinado', name: 'Supino Inclinado no Smith ou Halteres', muscleGroup: MuscleGroup.chest),
    const Exercise(id: 'ex_paralela_crossover', name: 'Paralela ou Cross Over Polia Alta', muscleGroup: MuscleGroup.chest),
    const Exercise(id: 'ex_peck_deck', name: 'Peck Deck Fly ou Crucifixo Polia', muscleGroup: MuscleGroup.chest),
    const Exercise(id: 'ex_extensao_punho', name: 'Extensão de Punho', muscleGroup: MuscleGroup.forearms),
    // Friday
    const Exercise(id: 'ex_triceps_cabo', name: 'Tríceps Cabo Bilateral ou Corda', muscleGroup: MuscleGroup.triceps),
    const Exercise(id: 'ex_frances_polia', name: 'Frances na Polia Unilateral', muscleGroup: MuscleGroup.triceps),
    const Exercise(id: 'ex_crucifixo_inverso', name: 'Crucifixo Inverso', muscleGroup: MuscleGroup.shoulders),
    const Exercise(id: 'ex_remada_supinada', name: 'Remada Supinada Máquina', muscleGroup: MuscleGroup.back),
    const Exercise(id: 'ex_puxada_super_aberta', name: 'Puxada Super Aberta e Pronada', muscleGroup: MuscleGroup.back),
    const Exercise(id: 'ex_kelso_shrug', name: 'Kelso Shrug ou Smith', muscleGroup: MuscleGroup.back),
    // Saturday
    const Exercise(id: 'ex_scott_maquina', name: 'Scott Máquina', muscleGroup: MuscleGroup.biceps),
    const Exercise(id: 'ex_rosca_banco_inclinado', name: 'Rosca Banco Inclinado Alternada', muscleGroup: MuscleGroup.biceps),
    const Exercise(id: 'ex_elev_lateral_peito', name: 'Elevação Lateral Peito Apoiado', muscleGroup: MuscleGroup.shoulders),
    const Exercise(id: 'ex_desenvolvimento', name: 'Desenvolvimento Smith ou com Halteres', muscleGroup: MuscleGroup.shoulders),
    const Exercise(id: 'ex_supino_reto', name: 'Supino Reto no Smith ou com Halteres', muscleGroup: MuscleGroup.chest),
    const Exercise(id: 'ex_flexao_punho', name: 'Flexão Punho', muscleGroup: MuscleGroup.forearms),
    // Sunday
    const Exercise(id: 'ex_abdominal_polia', name: 'Abdominal Polia de Costas', muscleGroup: MuscleGroup.abs),
    const Exercise(id: 'ex_abdominal_romano', name: 'Abdominal no Banco Romano', muscleGroup: MuscleGroup.abs),
  ];

  static Exercise? exerciseById(String id) {
    for (final e in exercises) {
      if (e.id == id) return _withMedia(e);
    }
    for (final e in ExerciseSubstitutions.alternatives) {
      if (e.id == id) return _withMedia(e);
    }
    return null;
  }

  static WorkoutExercise? slotById(String workoutExerciseId) {
    for (final plan in plans) {
      for (final we in plan.exercises) {
        if (we.id == workoutExerciseId) return we;
      }
    }
    return null;
  }

  /// Substitutos sugeridos primeiro, depois o mesmo grupo muscular.
  static List<Exercise> substitutesFor({
    required String protocolExerciseId,
    required String currentExerciseId,
  }) {
    final protocol = exerciseById(protocolExerciseId);
    if (protocol == null) return const [];

    final seen = <String>{currentExerciseId};
    final ordered = <Exercise>[];

    void add(Exercise? exercise) {
      if (exercise == null) return;
      if (!seen.add(exercise.id)) return;
      ordered.add(exercise);
    }

    for (final id in ExerciseSubstitutions
            .suggestedByExerciseId[protocolExerciseId] ??
        const <String>[]) {
      add(exerciseById(id));
    }

    for (final exercise in catalog) {
      if (exercise.muscleGroup == protocol.muscleGroup) add(exercise);
    }

    return ordered;
  }

  /// Primeira ocorrência do exercício em um plano (prescrição do protocolo).
  static WorkoutExercise? firstPrescription(String exerciseId) {
    for (final plan in plans) {
      for (final we in plan.exercises) {
        if (we.exerciseId == exerciseId) return we;
      }
    }
    return null;
  }

  /// Resumo textual das séries (Aquecimento / Preparatórias / Valendo).
  static String? setsSummary(String exerciseId) {
    final we = firstPrescription(exerciseId);
    if (we == null) return null;
    final warmup = we.sets.where((s) => s.type == SetType.warmup).length;
    final prep = we.sets.where((s) => s.type == SetType.preparation).length;
    final working = we.sets.where((s) => s.type == SetType.working).length;
    final parts = <String>[];
    if (warmup > 0) parts.add('Aquecimento ${warmup}x10');
    if (prep > 0) parts.add('Preparatórias ${prep}x2-7');
    if (working > 0) parts.add('Valendo ${working}x8-10');
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static final List<WorkoutPlan> plans = [
    // SEGUNDA — Tríceps e Costas
    WorkoutPlan(
      id: 'plan_monday',
      name: 'Tríceps e Costas',
      weekday: Weekday.monday,
      exercises: [
        _we(id: 'mon_1', exerciseId: 'ex_triceps_barra_v', order: 1, sets: _expand(warmupSets: 2, prepSets: 2, workingSets: 2)),
        _we(id: 'mon_2', exerciseId: 'ex_triceps_polia_caneleira', order: 2, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'mon_3', exerciseId: 'ex_posterior_45', order: 3, sets: _expand(warmupSets: 1, prepSets: 1, workingSets: 2)),
        _we(id: 'mon_4', exerciseId: 'ex_puxada_pronada_media', order: 4, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'mon_5', exerciseId: 'ex_puxada_unilateral', order: 5, sets: _expand(prepSets: 1, workingSets: 3)),
        _we(id: 'mon_6', exerciseId: 'ex_remada_pronada', order: 6, sets: _expand(prepSets: 1, workingSets: 2)),
      ],
    ),
    // TERÇA — Inferiores
    WorkoutPlan(
      id: 'plan_tuesday',
      name: 'Inferiores',
      weekday: Weekday.tuesday,
      exercises: [
        _we(id: 'tue_1', exerciseId: 'ex_pant_leg_press', order: 1, sets: _expand(warmupSets: 1, prepSets: 2, workingSets: 2)),
        _we(id: 'tue_2', exerciseId: 'ex_mesa_flexora', order: 2, sets: _expand(warmupSets: 2, prepSets: 2, workingSets: 2)),
        _we(id: 'tue_3', exerciseId: 'ex_agachamento_smith_hack', order: 3, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'tue_4', exerciseId: 'ex_stiff_barra', order: 4, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'tue_5', exerciseId: 'ex_extensora_uni', order: 5, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'tue_6', exerciseId: 'ex_adutora', order: 6, sets: _expand(prepSets: 1, workingSets: 2)),
      ],
    ),
    // QUARTA — Bíceps, Ombro e Peito
    // Martelo: Aquecimento 2x10, Preparatórias 1-2x2-7 → preservamos ambiguidade usando 2 prep (topo da faixa 1-2)
    // Elevação lateral: Prep 1-2 → 2; Valendo 3x8-10
    WorkoutPlan(
      id: 'plan_wednesday',
      name: 'Bíceps, Ombro e Peito',
      weekday: Weekday.wednesday,
      exercises: [
        _we(id: 'wed_1', exerciseId: 'ex_martelo', order: 1, sets: _expand(warmupSets: 2, prepSets: 2, workingSets: 2)),
        _we(id: 'wed_2', exerciseId: 'ex_rosca_polia_uni', order: 2, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'wed_3', exerciseId: 'ex_elev_lateral_tras', order: 3, sets: _expand(warmupSets: 1, prepSets: 2, workingSets: 3)),
        _we(id: 'wed_4', exerciseId: 'ex_supino_inclinado', order: 4, sets: _expand(warmupSets: 1, prepSets: 2, workingSets: 2)),
        _we(id: 'wed_5', exerciseId: 'ex_paralela_crossover', order: 5, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'wed_6', exerciseId: 'ex_peck_deck', order: 6, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'wed_7', exerciseId: 'ex_extensao_punho', order: 7, sets: _expand(prepSets: 1, workingSets: 2)),
      ],
    ),
    // QUINTA — Day Off
    const WorkoutPlan(
      id: 'plan_thursday',
      name: 'Day Off',
      weekday: Weekday.thursday,
      isDayOff: true,
      exercises: [],
    ),
    // SEXTA — Tríceps e Costas
    WorkoutPlan(
      id: 'plan_friday',
      name: 'Tríceps e Costas',
      weekday: Weekday.friday,
      exercises: [
        _we(id: 'fri_1', exerciseId: 'ex_triceps_cabo', order: 1, sets: _expand(warmupSets: 2, prepSets: 2, workingSets: 2)),
        _we(id: 'fri_2', exerciseId: 'ex_frances_polia', order: 2, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'fri_3', exerciseId: 'ex_crucifixo_inverso', order: 3, sets: _expand(warmupSets: 1, prepSets: 2, workingSets: 2)),
        _we(id: 'fri_4', exerciseId: 'ex_remada_supinada', order: 4, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'fri_5', exerciseId: 'ex_puxada_super_aberta', order: 5, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'fri_6', exerciseId: 'ex_kelso_shrug', order: 6, sets: _expand(prepSets: 1, workingSets: 2)),
      ],
    ),
    // SÁBADO — Bíceps, Ombro e Peito
    WorkoutPlan(
      id: 'plan_saturday',
      name: 'Bíceps, Ombro e Peito',
      weekday: Weekday.saturday,
      exercises: [
        _we(id: 'sat_1', exerciseId: 'ex_scott_maquina', order: 1, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'sat_2', exerciseId: 'ex_rosca_banco_inclinado', order: 2, sets: _expand(prepSets: 1, workingSets: 2)),
        _we(id: 'sat_3', exerciseId: 'ex_elev_lateral_peito', order: 3, sets: _expand(warmupSets: 1, prepSets: 2, workingSets: 3)),
        _we(id: 'sat_4', exerciseId: 'ex_desenvolvimento', order: 4, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'sat_5', exerciseId: 'ex_supino_reto', order: 5, sets: _expand(prepSets: 2, workingSets: 2)),
        _we(id: 'sat_6', exerciseId: 'ex_flexao_punho', order: 6, sets: _expand(prepSets: 1, workingSets: 3)),
      ],
    ),
    // DOMINGO — Abdômen e Panturrilha
    WorkoutPlan(
      id: 'plan_sunday',
      name: 'Abdômen e Panturrilha',
      weekday: Weekday.sunday,
      exercises: [
        _we(id: 'sun_1', exerciseId: 'ex_abdominal_polia', order: 1, sets: _expand(workingSets: 2)),
        _we(id: 'sun_2', exerciseId: 'ex_abdominal_romano', order: 2, sets: _expand(workingSets: 2)),
        _we(id: 'sun_3', exerciseId: 'ex_pant_leg_press', order: 3, sets: _expand(warmupSets: 1, prepSets: 2, workingSets: 2)),
      ],
    ),
  ];

  static WorkoutPlan planForWeekday(Weekday day) {
    return plans.firstWhere((p) => p.weekday == day);
  }

  static WorkoutPlan? planById(String id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Workout plans that include a given exercise.
  static List<WorkoutPlan> plansContainingExercise(String exerciseId) {
    return plans
        .where((p) => p.exercises.any((e) => e.exerciseId == exerciseId))
        .toList();
  }
}
