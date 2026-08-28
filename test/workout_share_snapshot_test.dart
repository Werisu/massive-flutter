import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/theme/app_theme.dart';
import 'package:massive_arms/core/utils/formatters.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/workout_session.dart';
import 'package:massive_arms/data/services/history_grouping.dart';
import 'package:massive_arms/data/services/workout_share_snapshot.dart';
import 'package:massive_arms/features/share/workout_share_card.dart';

WorkoutSession _session({
  required String id,
  required DateTime at,
  required String exerciseId,
  required double weight,
  required int reps,
  Duration duration = const Duration(minutes: 40),
  String planId = 'plan_monday',
}) {
  return WorkoutSession(
    id: id,
    workoutPlanId: planId,
    startedAt: at,
    finishedAt: at.add(duration),
    exercises: [
      SessionExercise(
        workoutExerciseId: 'w-$id',
        exerciseId: exerciseId,
        order: 1,
        sets: [
          SetRecord(
            id: 'wu-$id',
            exerciseId: exerciseId,
            setType: SetType.warmup,
            setNumber: 1,
            weight: 20,
            repetitions: 10,
            completed: true,
          ),
          SetRecord(
            id: 'wk-$id',
            exerciseId: exerciseId,
            setType: SetType.working,
            setNumber: 1,
            weight: weight,
            repetitions: reps,
            completed: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  test('formata duração curta e volume com milhar', () {
    expect(formatDurationShort(const Duration(minutes: 48)), '48 min');
    expect(formatDurationShort(const Duration(hours: 1, minutes: 5)), '1h 5min');
    expect(formatVolumeKg(12480), '12.480 kg');
    expect(formatVolumeKg(480), '480 kg');
  });

  test('snapshot marca PR e aumento de carga vs histórico', () {
    final prev = _session(
      id: 'prev',
      at: DateTime(2026, 3, 17, 10),
      exerciseId: 'ex_triceps_barra_v',
      weight: 50,
      reps: 8,
    );
    final today = _session(
      id: 'today',
      at: DateTime(2026, 3, 24, 10),
      exerciseId: 'ex_triceps_barra_v',
      weight: 55,
      reps: 8,
    );
    final days = HistoryGrouping.groupFinishedSessions([prev, today]);
    final day = days.firstWhere((d) => d.date.day == 24);

    final snapshot = WorkoutShareSnapshot.fromDay(
      day: day,
      allFinishedSessions: [prev, today],
      athleteName: 'Wellysson',
      hiitCompleted: true,
    );

    expect(snapshot.athleteName, 'Wellysson');
    expect(snapshot.trainingDayNumber, 2);
    expect(snapshot.hiitCompleted, isTrue);
    expect(snapshot.workingSetCount, 1);
    expect(snapshot.volumeKg, 55 * 8);
    expect(snapshot.exercises, hasLength(1));

    final exercise = snapshot.exercises.single;
    expect(exercise.name, 'Tríceps Barra V de Costas');
    expect(exercise.hasPr, isTrue);
    expect(exercise.sets.single.isPr, isTrue);
    expect(exercise.progressKind, ShareProgressKind.weightUp);
    expect(exercise.progressLabel, 'Carga +5 kg');
    expect(snapshot.shareCaption, contains('recorde pessoal'));
    expect(snapshot.shareCaption, contains('HIIT concluído'));
    expect(snapshot.shareCaption, contains('Dev: Wellysson N Rocha'));
    expect(snapshot.fileStem, 'massive-arms-2026-03-24');
  });

  test('snapshot marca evolução de reps sem PR de carga', () {
    final prev = _session(
      id: 'prev',
      at: DateTime(2026, 3, 17, 10),
      exerciseId: 'ex_triceps_barra_v',
      weight: 50,
      reps: 8,
    );
    final today = _session(
      id: 'today',
      at: DateTime(2026, 3, 24, 10),
      exerciseId: 'ex_triceps_barra_v',
      weight: 50,
      reps: 10,
    );
    final day = HistoryGrouping.groupFinishedSessions([prev, today]).firstWhere(
      (d) => d.date.day == 24,
    );

    final snapshot = WorkoutShareSnapshot.fromDay(
      day: day,
      allFinishedSessions: [prev, today],
      athleteName: 'Atleta',
    );

    final exercise = snapshot.exercises.single;
    expect(exercise.hasPr, isTrue);
    expect(exercise.progressKind, ShareProgressKind.repsUp);
    expect(exercise.progressLabel, '+2 reps');
  });

  test('primeiro treino não marca PR e ignora aquecimento no volume', () {
    final today = _session(
      id: 'today',
      at: DateTime(2026, 3, 24, 10),
      exerciseId: 'ex_triceps_barra_v',
      weight: 40,
      reps: 8,
    );
    final day = HistoryGrouping.groupFinishedSessions([today]).single;
    final snapshot = WorkoutShareSnapshot.fromDay(
      day: day,
      allFinishedSessions: [today],
      athleteName: 'Atleta',
    );

    expect(snapshot.exercises.single.hasPr, isFalse);
    expect(snapshot.volumeKg, 40 * 8);
    expect(snapshot.trainingDayNumber, 1);
    expect(snapshot.exercises.single.progressKind, ShareProgressKind.none);
  });

  testWidgets('card mostra branding, stats e PR', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = WorkoutShareSnapshot(
      athleteName: 'Wellysson',
      workoutTitle: 'Segunda — Tríceps e Costas',
      date: DateTime(2026, 3, 24),
      duration: Duration(minutes: 48),
      volumeKg: 12480,
      workingSetCount: 12,
      exerciseCount: 1,
      trainingDayNumber: 12,
      hiitCompleted: true,
      exercises: [
        WorkoutShareExercise(
          exerciseId: 'ex_triceps_barra_v',
          name: 'Tríceps Barra V de Costas',
          progressKind: ShareProgressKind.weightUp,
          progressLabel: 'Carga +5 kg',
          sets: [
            WorkoutShareSet(weight: 55, reps: 8, isPr: true),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(child: WorkoutShareCard(snapshot: snapshot)),
        ),
      ),
    );

    expect(find.text('MASSIVE ARMS'), findsOneWidget);
    expect(find.text('WELLYSSON'), findsOneWidget);
    expect(find.text('Segunda — Tríceps e Costas'), findsOneWidget);
    expect(find.text('PR'), findsWidgets);
    expect(find.text('HIIT ✓'), findsOneWidget);
    expect(find.text('55×8'), findsOneWidget);
    expect(find.textContaining('Carga +5 kg'), findsOneWidget);
    expect(find.textContaining('Wellysson N Rocha'), findsOneWidget);
  });
}
