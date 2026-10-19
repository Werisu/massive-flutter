import '../models/enums.dart';
import '../models/workout_plan.dart';

/// Full body 3x por semana. Os compostos vêm antes dos braços.
/// Segunda, quarta e sexta repetem a mesma seleção; os outros dias são folga.
abstract final class FullBodyData {
  static List<SetPrescription> _working({
    required int sets,
    required int repMin,
    required int repMax,
  }) {
    return [
      for (var i = 0; i < sets; i++)
        SetPrescription(type: SetType.working, repMin: repMin, repMax: repMax),
    ];
  }

  static WorkoutExercise _we({
    required String id,
    required String exerciseId,
    required int order,
    required int repMin,
    required int repMax,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      order: order,
      sets: _working(sets: 3, repMin: repMin, repMax: repMax),
    );
  }

  /// Mesmos slots nos três dias, para a troca de exercício valer na semana inteira.
  static final List<WorkoutExercise> session = [
    _we(
      id: 'fb_1',
      exerciseId: 'ex_agachamento_smith_hack',
      order: 1,
      repMin: 6,
      repMax: 10,
    ),
    _we(
      id: 'fb_2',
      exerciseId: 'ex_stiff_barra',
      order: 2,
      repMin: 6,
      repMax: 10,
    ),
    _we(
      id: 'fb_3',
      exerciseId: 'ex_supino_reto',
      order: 3,
      repMin: 6,
      repMax: 10,
    ),
    _we(
      id: 'fb_4',
      exerciseId: 'ex_remada_pronada',
      order: 4,
      repMin: 6,
      repMax: 10,
    ),
    _we(
      id: 'fb_5',
      exerciseId: 'ex_puxada_pronada_media',
      order: 5,
      repMin: 6,
      repMax: 10,
    ),
    _we(
      id: 'fb_6',
      exerciseId: 'ex_desenvolvimento',
      order: 6,
      repMin: 6,
      repMax: 10,
    ),
    _we(
      id: 'fb_7',
      exerciseId: 'ex_rosca_banco_inclinado',
      order: 7,
      repMin: 8,
      repMax: 12,
    ),
    _we(
      id: 'fb_8',
      exerciseId: 'ex_triceps_cabo',
      order: 8,
      repMin: 8,
      repMax: 12,
    ),
  ];

  static WorkoutPlan _train(Weekday day) {
    return WorkoutPlan(
      id: 'fb_${day.name}',
      name: 'Full Body',
      weekday: day,
      exercises: session,
    );
  }

  static WorkoutPlan _off(Weekday day) {
    return WorkoutPlan(
      id: 'fb_${day.name}',
      name: 'Day Off',
      weekday: day,
      isDayOff: true,
      exercises: const [],
    );
  }

  static final List<WorkoutPlan> plans = [
    _train(Weekday.monday),
    _off(Weekday.tuesday),
    _train(Weekday.wednesday),
    _off(Weekday.thursday),
    _train(Weekday.friday),
    _off(Weekday.saturday),
    _off(Weekday.sunday),
  ];

  static bool isPlan(String id) => id.startsWith('fb_');
}
