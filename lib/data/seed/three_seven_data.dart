import '../models/enums.dart';
import '../models/workout_plan.dart';

/// Método 3/7: cinco mini-séries (3, 4, 5, 6 e 7) na mesma carga.
/// A pausa entre elas é curta; depois do 7 o descanso é o do próximo exercício.
abstract final class ThreeSevenData {
  static const planPrefix = 'm37_';
  static const miniReps = [3, 4, 5, 6, 7];
  static const intraRestSeconds = 15;
  static const blockRestSeconds = 180;

  static const loadCue = 'Carga única, cerca de 70%';
  static const loadNote = 'mesma carga';

  static bool isPlan(String id) => id.startsWith(planPrefix);

  static bool isBlock(List<SetPrescription> sets) {
    if (sets.length != miniReps.length) return false;
    for (var i = 0; i < miniReps.length; i++) {
      final set = sets[i];
      if (set.type != SetType.working) return false;
      if (set.repMin != miniReps[i] || set.repMax != miniReps[i]) return false;
    }
    return true;
  }

  static List<SetPrescription> block() {
    return [
      for (var i = 0; i < miniReps.length; i++)
        SetPrescription(
          type: SetType.working,
          repMin: miniReps[i],
          repMax: miniReps[i],
          note: loadNote,
          restSeconds: i == miniReps.length - 1
              ? blockRestSeconds
              : intraRestSeconds,
        ),
    ];
  }

  static WorkoutExercise _we({
    required String id,
    required String exerciseId,
    required int order,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      order: order,
      sets: block(),
      focus: loadCue,
      restSeconds: intraRestSeconds,
      restLabel: '15 seg',
    );
  }

  static const _intro =
      'Um bloco por exercício: 3, 4, 5, 6 e 7 reps na mesma carga, '
      'com 15 segundos entre as mini-séries. Depois do 7, 3 min até o próximo.';

  static WorkoutPlan _train({
    required Weekday day,
    required String name,
    required List<WorkoutExercise> exercises,
  }) {
    return WorkoutPlan(
      id: '$planPrefix${day.name}',
      name: name,
      weekday: day,
      summary: _intro,
      exercises: exercises,
    );
  }

  static WorkoutPlan _off(Weekday day) {
    return WorkoutPlan(
      id: '$planPrefix${day.name}',
      name: 'Day Off',
      weekday: day,
      isDayOff: true,
      exercises: const [],
    );
  }

  static final List<WorkoutPlan> plans = [
    _train(
      day: Weekday.monday,
      name: 'Peito e Costas',
      exercises: [
        _we(id: 'm37_mon_1', exerciseId: 'ex_supino_reto', order: 1),
        _we(id: 'm37_mon_2', exerciseId: 'ex_supino_inclinado', order: 2),
        _we(id: 'm37_mon_3', exerciseId: 'ex_remada_pronada', order: 3),
        _we(id: 'm37_mon_4', exerciseId: 'ex_puxada_pronada_media', order: 4),
        _we(id: 'm37_mon_5', exerciseId: 'ex_desenvolvimento', order: 5),
      ],
    ),
    _train(
      day: Weekday.tuesday,
      name: 'Pernas',
      exercises: [
        _we(id: 'm37_tue_1', exerciseId: 'ex_agachamento_smith_hack', order: 1),
        _we(id: 'm37_tue_2', exerciseId: 'ex_stiff_barra', order: 2),
        _we(id: 'm37_tue_3', exerciseId: 'ex_extensora_uni', order: 3),
        _we(id: 'm37_tue_4', exerciseId: 'ex_mesa_flexora', order: 4),
        _we(id: 'm37_tue_5', exerciseId: 'ex_pant_leg_press', order: 5),
      ],
    ),
    _off(Weekday.wednesday),
    _train(
      day: Weekday.thursday,
      name: 'Ombros e Costas',
      exercises: [
        _we(id: 'm37_thu_1', exerciseId: 'ex_paralela_crossover', order: 1),
        _we(id: 'm37_thu_2', exerciseId: 'ex_peck_deck', order: 2),
        _we(id: 'm37_thu_3', exerciseId: 'ex_remada_supinada', order: 3),
        _we(id: 'm37_thu_4', exerciseId: 'ex_puxada_super_aberta', order: 4),
        _we(id: 'm37_thu_5', exerciseId: 'ex_elev_lateral_tras', order: 5),
      ],
    ),
    _train(
      day: Weekday.friday,
      name: 'Braços',
      exercises: [
        _we(id: 'm37_fri_1', exerciseId: 'ex_rosca_banco_inclinado', order: 1),
        _we(id: 'm37_fri_2', exerciseId: 'ex_martelo', order: 2),
        _we(id: 'm37_fri_3', exerciseId: 'ex_rosca_polia_uni', order: 3),
        _we(id: 'm37_fri_4', exerciseId: 'ex_triceps_cabo', order: 4),
        _we(id: 'm37_fri_5', exerciseId: 'ex_frances_polia', order: 5),
        _we(id: 'm37_fri_6', exerciseId: 'ex_elev_lateral_peito', order: 6),
      ],
    ),
    _off(Weekday.saturday),
    _off(Weekday.sunday),
  ];
}
