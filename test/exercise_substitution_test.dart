import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/exercise.dart';
import 'package:massive_arms/data/models/user_preferences.dart';
import 'package:massive_arms/data/models/workout_session.dart';
import 'package:massive_arms/data/seed/exercise_substitutions.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';
import 'package:massive_arms/data/services/exercise_catalog.dart';

void main() {
  test('catálogo inclui martelo na polia como variação', () {
    expect(
      ProtocolData.exerciseById('alt_martelo_polia')?.name,
      'Martelo na Polia',
    );
    expect(ExerciseSubstitutions.isAlternative('alt_martelo_polia'), isTrue);
    expect(ExerciseSubstitutions.isAlternative('ex_martelo'), isFalse);
  });

  test('plano semanal não muda ao cadastrar variações', () {
    final wednesday = ProtocolData.planById('plan_wednesday')!;
    expect(wednesday.exercises.first.exerciseId, 'ex_martelo');
    expect(
      wednesday.exercises.any((e) => e.exerciseId == 'alt_martelo_polia'),
      isFalse,
    );
  });

  test('martelo sugere martelo na polia primeiro', () {
    final candidates = ProtocolData.substitutesFor(
      protocolExerciseId: 'ex_martelo',
      currentExerciseId: 'ex_martelo',
    );
    expect(candidates, isNotEmpty);
    expect(candidates.first.id, 'alt_martelo_polia');
    expect(candidates.every((e) => e.id != 'ex_martelo'), isTrue);
    expect(
      candidates.every((e) => e.muscleGroup == MuscleGroup.biceps),
      isTrue,
    );
  });

  test('substituir exercício troca o movimento e zera as séries', () {
    final startedAt = DateTime(2026, 8, 27, 18);
    final session = WorkoutSession(
      id: 's1',
      workoutPlanId: 'plan_wednesday',
      startedAt: startedAt,
      exercises: [
        SessionExercise(
          workoutExerciseId: 'wed_1',
          exerciseId: 'ex_martelo',
          order: 1,
          sets: const [
            SetRecord(
              id: 'set-1',
              exerciseId: 'ex_martelo',
              setType: SetType.warmup,
              setNumber: 1,
              weight: 12,
              repetitions: 10,
              completed: true,
            ),
            SetRecord(
              id: 'set-2',
              exerciseId: 'ex_martelo',
              setType: SetType.working,
              setNumber: 2,
            ),
          ],
        ),
      ],
    );

    final replaced = session.replaceExercise(
      workoutExerciseId: 'wed_1',
      newExerciseId: 'alt_martelo_polia',
      protocolExerciseId: 'ex_martelo',
    );
    final exercise = replaced.exercises.single;

    expect(exercise.exerciseId, 'alt_martelo_polia');
    expect(exercise.originalExerciseId, 'ex_martelo');
    expect(exercise.isSubstituted, isTrue);
    expect(exercise.sets.every((s) => s.exerciseId == 'alt_martelo_polia'), isTrue);
    expect(exercise.sets.every((s) => !s.completed), isTrue);
    expect(exercise.sets.every((s) => s.weight == null), isTrue);
    expect(exercise.sets.first.id, 'set-1');

    final reverted = replaced.replaceExercise(
      workoutExerciseId: 'wed_1',
      newExerciseId: 'ex_martelo',
      protocolExerciseId: 'ex_martelo',
    );
    expect(reverted.exercises.single.isSubstituted, isFalse);
    expect(reverted.exercises.single.originalExerciseId, isNull);
    expect(reverted.exercises.single.exerciseId, 'ex_martelo');
  });

  test('substituição persiste no JSON da sessão e das preferências', () {
    final session = WorkoutSession(
      id: 's1',
      workoutPlanId: 'plan_wednesday',
      startedAt: DateTime(2026, 8, 27),
      exercises: const [
        SessionExercise(
          workoutExerciseId: 'wed_1',
          exerciseId: 'alt_martelo_polia',
          originalExerciseId: 'ex_martelo',
          order: 1,
          sets: [],
        ),
      ],
    );
    final restored = WorkoutSession.fromJson(session.toJson());
    expect(restored.exercises.single.isSubstituted, isTrue);
    expect(restored.exercises.single.originalExerciseId, 'ex_martelo');

    const prefs = UserPreferences(
      exerciseSubstitutions: {'wed_1': 'alt_martelo_polia'},
    );
    final encoded = UserPreferences.fromJson(prefs.toJson());
    expect(encoded.exerciseSubstitutions['wed_1'], 'alt_martelo_polia');

    final legacy = UserPreferences.fromJson({'userName': 'Wellysson'});
    expect(legacy.exerciseSubstitutions, isEmpty);
    expect(legacy.customExercises, isEmpty);
  });

  test('exercício criado pelo usuário entra no catálogo e nas sugestões', () {
    const custom = Exercise(
      id: 'custom_test',
      name: 'Martelo na Polia Sentado',
      muscleGroup: MuscleGroup.biceps,
    );
    ExerciseCatalog.setCustom([custom]);

    expect(ExerciseCatalog.byId('custom_test')?.name, custom.name);
    expect(ExerciseCatalog.isCustom('custom_test'), isTrue);
    expect(ExerciseCatalog.findByName('martelo na polia sentado')?.id, custom.id);

    final candidates = ProtocolData.substitutesFor(
      protocolExerciseId: 'ex_martelo',
      currentExerciseId: 'ex_martelo',
      extra: [custom],
    );
    expect(candidates.any((e) => e.id == 'custom_test'), isTrue);

    const prefs = UserPreferences(customExercises: [custom]);
    final encoded = UserPreferences.fromJson(prefs.toJson());
    expect(encoded.customExercises.single.id, 'custom_test');
    expect(encoded.customExercises.single.name, custom.name);

    ExerciseCatalog.setCustom(const []);
  });
}
