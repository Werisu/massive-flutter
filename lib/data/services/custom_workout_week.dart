import '../models/enums.dart';
import '../models/workout_plan.dart';

/// Semana montada pelo usuário. Os ids são estáveis (`custom_monday` etc.)
/// para o histórico continuar achando o dia depois de uma edição.
abstract final class CustomWorkoutWeek {
  static const prefix = 'custom_';

  static bool isId(String id) => id.startsWith(prefix);

  static String idFor(Weekday day) => '$prefix${day.name}';

  static bool hasTrainingDay(List<WorkoutPlan> plans) {
    return plans.any((plan) => !plan.isDayOff && plan.exercises.isNotEmpty);
  }

  static WorkoutPlan blankDay(Weekday day) {
    return WorkoutPlan(
      id: idFor(day),
      name: 'Treino',
      weekday: day,
      isDayOff: true,
      exercises: const [],
    );
  }

  static List<WorkoutPlan> blank() {
    return [for (final day in Weekday.values) blankDay(day)];
  }

  /// Garante os sete dias, reescreve o id e numera os exercícios de novo.
  /// Dia sem exercício vira folga. Exercícios de um dia de folga são mantidos
  /// para voltarem quando a folga for desmarcada.
  static List<WorkoutPlan> normalize(List<WorkoutPlan> stored) {
    final byDay = <Weekday, WorkoutPlan>{};
    for (final plan in stored) {
      final exercises = <WorkoutExercise>[];
      for (final slot in plan.exercises) {
        if (slot.exerciseId.isEmpty || slot.sets.isEmpty) continue;
        exercises.add(
          WorkoutExercise(
            id: slot.id,
            exerciseId: slot.exerciseId,
            order: exercises.length + 1,
            sets: slot.sets,
          ),
        );
      }
      final name = plan.name.trim().isEmpty ? 'Treino' : plan.name.trim();
      byDay[plan.weekday] = WorkoutPlan(
        id: idFor(plan.weekday),
        name: name,
        weekday: plan.weekday,
        isDayOff: plan.isDayOff || exercises.isEmpty,
        exercises: exercises,
      );
    }
    return [for (final day in Weekday.values) byDay[day] ?? blankDay(day)];
  }
}

/// Cache dos treinos personalizados, no mesmo estilo do catálogo de exercícios.
/// O repositório de preferências atualiza isso ao ler e ao salvar.
abstract final class CustomPlanCatalog {
  static List<WorkoutPlan> _plans = const [];

  static void set(List<WorkoutPlan> plans) {
    _plans = List<WorkoutPlan>.unmodifiable(
      plans.isEmpty
          ? const <WorkoutPlan>[]
          : CustomWorkoutWeek.normalize(plans),
    );
  }

  static void clear() {
    _plans = const [];
  }

  static List<WorkoutPlan> get plans => _plans;

  static WorkoutPlan? byId(String id) {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}
