import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/theme/app_theme.dart';
import 'package:massive_arms/data/firebase/firebase_mappers.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/workout_plan.dart';
import 'package:massive_arms/data/repositories/preferences_repository.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';
import 'package:massive_arms/data/seed/three_seven_data.dart';
import 'package:massive_arms/features/workouts/training_split_selector.dart';
import 'package:massive_arms/features/workouts/workout_detail_screen.dart';

void main() {
  test('a semana 3/7 treina quatro dias e cada exercício é um bloco', () {
    expect(ThreeSevenData.plans, hasLength(7));

    final monday = ProtocolData.planFor(
      TrainingSplit.threeSeven,
      Weekday.monday,
    );
    expect(monday.name, 'Peito e Costas');
    expect(monday.exerciseCount, 5);
    expect(monday.exercises.first.exerciseId, 'ex_supino_reto');
    expect(ThreeSevenData.isBlock(monday.exercises.first.sets), isTrue);
    expect(
      monday.exercises.first.sets.map((set) => set.repMin),
      [3, 4, 5, 6, 7],
    );
    expect(
      monday.exercises.first.sets.every((set) => set.note == 'mesma carga'),
      isTrue,
    );
    expect(monday.exercises.first.sets[3].restSeconds, 15);
    expect(monday.exercises.first.sets.last.restSeconds, 180);
    expect(monday.exercises.map((slot) => slot.sets.length), everyElement(5));

    expect(
      ProtocolData.planFor(TrainingSplit.threeSeven, Weekday.tuesday).name,
      'Pernas',
    );
    expect(
      ProtocolData.planFor(
        TrainingSplit.threeSeven,
        Weekday.wednesday,
      ).isDayOff,
      isTrue,
    );
    expect(
      ProtocolData.planFor(TrainingSplit.threeSeven, Weekday.thursday).name,
      'Ombros e Costas',
    );
    final friday = ProtocolData.planFor(
      TrainingSplit.threeSeven,
      Weekday.friday,
    );
    expect(friday.name, 'Braços');
    expect(friday.exerciseCount, 6);
    expect(friday.exercises.last.exerciseId, 'ex_elev_lateral_peito');
    expect(
      ProtocolData.planFor(TrainingSplit.threeSeven, Weekday.saturday).isDayOff,
      isTrue,
    );
    expect(
      ProtocolData.planFor(TrainingSplit.threeSeven, Weekday.sunday).isDayOff,
      isTrue,
    );
  });

  test('o resumo mostra a sequência e o protocolo original segue igual', () {
    expect(
      ProtocolData.setsSummary(
        'ex_supino_reto',
        split: TrainingSplit.threeSeven,
      ),
      'Valendo 3+4+5+6+7 (mesma carga)',
    );
    expect(
      ProtocolData.planFor(TrainingSplit.protocol, Weekday.monday).name,
      'Tríceps e Costas',
    );
    expect(
      ProtocolData.setsSummary(
        'ex_triceps_cabo',
        split: TrainingSplit.protocol,
      ),
      isNot('Valendo 3+4+5+6+7 (mesma carga)'),
    );
    expect(ProtocolData.planById('m37_friday')?.name, 'Braços');
    expect(FirebaseMappers.planIdFromDayId('m37_sexta'), 'm37_friday');
    expect(FirebaseMappers.dayIdFromPlanId('m37_tuesday'), 'm37_terca');
    expect(
      prescriptionGroupLabel(ThreeSevenData.block()),
      '3+4+5+6+7 reps · mesma carga',
    );
  });

  test('a pausa de cada mini-série sobrevive ao json', () {
    final original = ProtocolData.planFor(
      TrainingSplit.threeSeven,
      Weekday.monday,
    );
    final restored = WorkoutPlan.fromJson(original.toJson());
    expect(restored.exercises.first.restLabel, '15 seg');
    expect(restored.exercises.first.sets.first.restSeconds, 15);
    expect(restored.exercises.first.sets.last.restSeconds, 180);
    expect(restored.exercises.first.sets.last.repMin, 7);
  });

  testWidgets('a página do 3/7 mostra a sequência e a pausa curta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
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
          home: const WorkoutDetailScreen(planId: 'm37_monday'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Supino Reto no Smith ou com Halteres'), findsOneWidget);
    expect(find.text('Valendo: 3+4+5+6+7 · mesma carga'), findsWidgets);
    expect(find.text('Pausa entre as mini-séries: 15 seg'), findsWidgets);
    expect(find.text('Carga única, cerca de 70%'), findsWidgets);
    expect(find.text('Bora treinar'), findsOneWidget);
  });

  testWidgets('o seletor oferece a modalidade 3/7', (tester) async {
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
    await tester.tap(find.text('3/7'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('15 segundos'), findsOneWidget);
  });
}
