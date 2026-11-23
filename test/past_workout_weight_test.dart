import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:massive_arms/core/theme/app_theme.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/repositories/preferences_repository.dart';
import 'package:massive_arms/data/repositories/session_repository.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';
import 'package:massive_arms/data/seed/three_seven_data.dart';
import 'package:massive_arms/features/workout_session/workout_session_screen.dart';

void main() {
  late Directory dir;
  late Box<String> sessions;
  late Box<String> active;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('massive_past_weight_');
    Hive.init(dir.path);
    sessions = await Hive.openBox<String>('past_weight_sessions');
    active = await Hive.openBox<String>('past_weight_active');
  });

  tearDown(() async {
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> openSession(
    WidgetTester tester,
    SessionRepository saved,
    String planId,
  ) async {
    final plan = ProtocolData.planById(planId);
    await tester.runAsync(() => saved.startSession(plan!));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            PreferencesRepository.memory(),
          ),
          sessionRepositoryProvider.overrideWithValue(saved),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: WorkoutSessionScreen(planId: planId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('o 3/7 salva a carga e mostra no treino seguinte', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final plan = ProtocolData.planFor(
      TrainingSplit.threeSeven,
      Weekday.monday,
    );
    final slot = plan.exercises.first;
    final repo = SessionRepository(sessionsBox: sessions, activeBox: active);
    await tester.runAsync(() async {
      var session = await repo.startSession(plan);
      for (var i = 0; i < ThreeSevenData.miniReps.length; i++) {
        session = await repo.completeSet(
          session: session,
          workoutExerciseId: slot.id,
          setIndex: i,
          weight: 42.5,
          repetitions: ThreeSevenData.miniReps[i],
          rir: 1,
        );
      }
      await repo.finishSession(session);
    });

    final reloaded = SessionRepository(sessionsBox: sessions, activeBox: active);
    final saved = reloaded.getLastWorkingSet(slot.exerciseId);
    expect(saved?.weight, 42.5);
    expect(saved?.repetitions, 7);

    await openSession(tester, reloaded, plan.id);

    expect(tester.takeException(), isNull);
    expect(find.text('42.5 kg × 7 reps'), findsOneWidget);
    expect(find.textContaining('Último treino: 42.5 kg'), findsOneWidget);

    final weight = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Carga (kg)'),
    );
    final reps = tester.widget<TextField>(find.widgetWithText(TextField, 'Reps'));
    expect(weight.controller?.text, '42.5');
    expect(reps.controller?.text, '3');
  });

  testWidgets('o protocolo mostra a carga salva da última série valendo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final plan = ProtocolData.planFor(TrainingSplit.protocol, Weekday.monday);
    final slot = plan.exercises.first;
    final workingIndex = slot.sets.indexWhere(
      (set) => set.type == SetType.working,
    );
    final repo = SessionRepository(sessionsBox: sessions, activeBox: active);
    await tester.runAsync(() async {
      var session = await repo.startSession(plan);
      session = await repo.completeSet(
        session: session,
        workoutExerciseId: slot.id,
        setIndex: workingIndex,
        weight: 60,
        repetitions: 10,
        rir: 0,
      );
      await repo.finishSession(session);
    });

    final reloaded = SessionRepository(sessionsBox: sessions, activeBox: active);
    expect(reloaded.getLastWorkingSet(slot.exerciseId)?.weight, 60);

    await openSession(tester, reloaded, plan.id);

    expect(tester.takeException(), isNull);
    expect(find.text('60 kg × 10 reps'), findsOneWidget);
    expect(find.textContaining('Último treino: 60 kg'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Carga (kg)'))
          .controller
          ?.text,
      '60',
    );
  });
}
