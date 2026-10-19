import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/providers/app_providers.dart';
import 'package:massive_arms/core/theme/app_theme.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/user_preferences.dart';
import 'package:massive_arms/data/models/workout_plan.dart';
import 'package:massive_arms/data/repositories/preferences_repository.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';
import 'package:massive_arms/data/services/custom_workout_week.dart';
import 'package:massive_arms/data/services/exercise_catalog.dart';
import 'package:massive_arms/features/workouts/custom_workout_editor_screen.dart';
import 'package:massive_arms/features/workouts/training_split_selector.dart';

void main() {
  setUp(CustomPlanCatalog.clear);
  tearDown(() {
    CustomPlanCatalog.clear();
    ExerciseCatalog.setCustom(const []);
  });

  test('semana em branco tem sete folgas e ids estáveis', () {
    final week = CustomWorkoutWeek.blank();
    expect(week.map((plan) => plan.weekday), Weekday.values);
    expect(week.every((plan) => plan.isDayOff), isTrue);
    expect(week.first.id, 'custom_monday');
    expect(week.last.id, 'custom_sunday');
    expect(CustomWorkoutWeek.hasTrainingDay(week), isFalse);
  });

  test('normalizar completa dias faltantes e guarda exercício de folga', () {
    final week = CustomWorkoutWeek.normalize([
      WorkoutPlan(
        id: 'qualquer',
        name: '  Peito  ',
        weekday: Weekday.monday,
        exercises: [
          WorkoutExercise(
            id: 'slot_a',
            exerciseId: 'ex_supino_reto',
            order: 4,
            sets: const [
              SetPrescription(type: SetType.working, repMin: 6, repMax: 10),
              SetPrescription(type: SetType.working, repMin: 6, repMax: 10),
            ],
          ),
        ],
      ),
      const WorkoutPlan(
        id: 'off',
        name: 'Pernas',
        weekday: Weekday.friday,
        isDayOff: true,
        exercises: [
          WorkoutExercise(
            id: 'slot_b',
            exerciseId: 'ex_stiff_barra',
            order: 1,
            sets: [
              SetPrescription(type: SetType.working, repMin: 8, repMax: 12),
            ],
          ),
        ],
      ),
    ]);

    expect(week, hasLength(7));
    expect(week.first.id, 'custom_monday');
    expect(week.first.name, 'Peito');
    expect(week.first.isDayOff, isFalse);
    expect(week.first.exercises.single.order, 1);

    final friday = week[Weekday.friday.index];
    expect(friday.isDayOff, isTrue);
    expect(friday.name, 'Pernas');
    expect(friday.exercises.single.exerciseId, 'ex_stiff_barra');
    expect(CustomWorkoutWeek.hasTrainingDay(week), isTrue);

    expect(
      ProtocolData.planFor(TrainingSplit.protocol, Weekday.monday).name,
      'Tríceps e Costas',
    );
  });

  test(
    'lista personalizada sobrevive ao JSON e o protocolo continua o padrão',
    () {
      const prefs = UserPreferences(userName: 'Atleta');
      expect(prefs.trainingSplit, TrainingSplit.protocol);
      expect(prefs.customPlans, isEmpty);

      final saved = prefs.copyWith(
        trainingSplit: TrainingSplit.custom,
        customPlans: [
          WorkoutPlan(
            id: 'custom_monday',
            name: 'Peito',
            weekday: Weekday.monday,
            exercises: [
              WorkoutExercise(
                id: 'slot_1',
                exerciseId: 'ex_stiff_barra',
                order: 1,
                sets: const [
                  SetPrescription(type: SetType.working, repMin: 8, repMax: 12),
                ],
              ),
            ],
          ),
        ],
      );

      final decoded = UserPreferences.fromJson(saved.toJson());
      expect(decoded.trainingSplit, TrainingSplit.custom);
      expect(decoded.customPlans.single.name, 'Peito');
      expect(decoded.customPlans.single.exercises.single.sets.single.repMin, 8);

      final broken = UserPreferences.fromJson({
        'userName': 'Atleta',
        'customPlans': [
          {'id': 'ruim'},
          saved.customPlans.single.toJson(),
        ],
      });
      expect(broken.customPlans, hasLength(1));
      expect(broken.trainingSplit, TrainingSplit.protocol);
    },
  );

  test('o catálogo resolve o treino personalizado sem mexer no protocolo', () {
    CustomPlanCatalog.set([
      WorkoutPlan(
        id: 'ignorado',
        name: 'Costas',
        weekday: Weekday.wednesday,
        exercises: [
          WorkoutExercise(
            id: 'slot_c',
            exerciseId: 'ex_remada_pronada',
            order: 1,
            sets: const [
              SetPrescription(type: SetType.working, repMin: 8, repMax: 12),
            ],
          ),
        ],
      ),
    ]);

    expect(ProtocolData.planById('custom_wednesday')?.name, 'Costas');
    expect(ProtocolData.planById('plan_monday')?.name, 'Tríceps e Costas');
    expect(
      ProtocolData.planFor(
        TrainingSplit.custom,
        Weekday.wednesday,
      ).exerciseCount,
      1,
    );
    expect(
      ProtocolData.planFor(TrainingSplit.custom, Weekday.monday).isDayOff,
      isTrue,
    );
    expect(
      ProtocolData.setsSummary(
        'ex_remada_pronada',
        split: TrainingSplit.custom,
      ),
      'Valendo 1x8-12',
    );
    expect(ProtocolData.plans.length, 7);
  });

  testWidgets('o seletor mostra Meus treinos na largura de um celular', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            PreferencesRepository.memory(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: TrainingSplitSelector(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Meus treinos'), findsOneWidget);
    expect(find.text('Protocolo'), findsOneWidget);
  });

  testWidgets('cria a lista da semana com um exercício e salva', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          PreferencesRepository.memory(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomWorkoutEditorScreen(),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('SEGUNDA'), findsOneWidget);
    expect(find.text('DOMINGO'), findsOneWidget);
    expect(find.text('Salvar lista'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Peito');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Adicionar exercício').first);
    await tester.tap(find.text('Adicionar exercício').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Stiff');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stiff Barra'));
    await tester.pumpAndSettle();

    expect(find.text('Stiff Barra'), findsOneWidget);
    expect(find.text('3x8-12 valendo · Pernas'), findsOneWidget);

    await tester.tap(find.text('Salvar lista'));
    await tester.pumpAndSettle();

    final prefs = container.read(preferencesProvider);
    expect(prefs.trainingSplit, TrainingSplit.custom);
    expect(prefs.customPlans, hasLength(7));

    final monday = prefs.customPlans.first;
    expect(monday.id, 'custom_monday');
    expect(monday.name, 'Peito');
    expect(monday.isDayOff, isFalse);
    expect(monday.exercises.single.exerciseId, 'ex_stiff_barra');
    expect(monday.exercises.single.sets, hasLength(3));
    expect(monday.exercises.single.sets.first.type, SetType.working);
    expect(monday.exercises.single.sets.first.repMin, 8);
    expect(monday.exercises.single.sets.first.repMax, 12);
    expect(prefs.customPlans[1].isDayOff, isTrue);
    expect(ProtocolData.planById('custom_monday')?.name, 'Peito');
    expect(
      find.text('Lista salva. Ela vale nos treinos de hoje.'),
      findsOneWidget,
    );
  });
}
