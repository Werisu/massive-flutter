import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/utils/formatters.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/workout_session.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';
import 'package:massive_arms/data/services/history_grouping.dart';
import 'package:massive_arms/data/services/progress_analytics.dart';

void main() {
  test('saudação conforme horário', () {
    expect(greetingForNow(DateTime(2026, 1, 1, 9)), 'Bom dia');
    expect(greetingForNow(DateTime(2026, 1, 1, 15)), 'Boa tarde');
    expect(greetingForNow(DateTime(2026, 1, 1, 20)), 'Boa noite');
  });

  test('protocolo tem 7 planos semanais', () {
    expect(ProtocolData.plans.length, 7);
    expect(
      ProtocolData.planForWeekday(Weekday.thursday).isDayOff,
      isTrue,
    );
  });

  test('segunda tem 6 exercícios de tríceps e costas', () {
    final monday = ProtocolData.planForWeekday(Weekday.monday);
    expect(monday.name, 'Tríceps e Costas');
    expect(monday.exerciseCount, 6);
  });

  test('progressão de reps gera mensagem', () {
    final msg = progressionMessage(
      previousReps: 8,
      currentReps: 9,
      previousWeight: 30,
      currentWeight: 30,
      targetRepMax: 10,
    );
    expect(msg, contains('+1'));
  });

  test('agrupa sessões fragmentadas do mesmo dia', () {
    final day = DateTime(2026, 3, 24, 10);
    final sessions = [
      WorkoutSession(
        id: 'session-a',
        workoutPlanId: 'plan_saturday',
        startedAt: day,
        finishedAt: day.add(const Duration(minutes: 20)),
        exercises: [
          SessionExercise(
            workoutExerciseId: 'w1',
            exerciseId: 'ex_scott_maquina',
            order: 1,
            sets: const [
              SetRecord(
                id: 's1',
                exerciseId: 'ex_scott_maquina',
                setType: SetType.working,
                setNumber: 1,
                weight: 30,
                repetitions: 8,
                completed: true,
              ),
            ],
          ),
        ],
      ),
      WorkoutSession(
        id: 'session-b',
        workoutPlanId: 'plan_saturday',
        startedAt: day.add(const Duration(hours: 1)),
        finishedAt: day.add(const Duration(hours: 1, minutes: 15)),
        exercises: [
          SessionExercise(
            workoutExerciseId: 'w2',
            exerciseId: 'ex_supino_reto',
            order: 1,
            sets: const [
              SetRecord(
                id: 's2',
                exerciseId: 'ex_supino_reto',
                setType: SetType.working,
                setNumber: 1,
                weight: 60,
                repetitions: 8,
                completed: true,
              ),
            ],
          ),
        ],
      ),
    ];

    final days = HistoryGrouping.groupFinishedSessions(sessions);
    expect(days.length, 1);
    expect(days.first.sessionCount, 2);
    expect(days.first.exerciseCount, 2);
    expect(days.first.exercises.map((e) => e.exerciseId), containsAll([
      'ex_scott_maquina',
      'ex_supino_reto',
    ]));
  });

  test('analytics calcula volume e melhor marca', () {
    final at = DateTime(2026, 3, 24);
    final sessions = [
      WorkoutSession(
        id: 'session-c',
        workoutPlanId: 'plan_monday',
        startedAt: at,
        finishedAt: at.add(const Duration(minutes: 40)),
        exercises: [
          SessionExercise(
            workoutExerciseId: 'w1',
            exerciseId: 'ex_triceps_barra_v',
            order: 1,
            sets: [
              SetRecord(
                id: 's1',
                exerciseId: 'ex_triceps_barra_v',
                setType: SetType.working,
                setNumber: 1,
                weight: 40,
                repetitions: 8,
                completed: true,
                completedAt: at,
              ),
              SetRecord(
                id: 's2',
                exerciseId: 'ex_triceps_barra_v',
                setType: SetType.working,
                setNumber: 2,
                weight: 45,
                repetitions: 8,
                completed: true,
                completedAt: at,
              ),
            ],
          ),
        ],
      ),
    ];

    expect(ProgressAnalytics.totalVolume(sessions), 40 * 8 + 45 * 8);
    final best = ProgressAnalytics.bestMarks(sessions);
    expect(best.first.weight, 45);
    expect(best.first.reps, 8);
  });

  test('desfazer série limpa completedAt e mantém carga/reps', () {
    final at = DateTime(2026, 3, 24, 12);
    const original = SetRecord(
      id: 's1',
      exerciseId: 'ex_scott_maquina',
      setType: SetType.working,
      setNumber: 1,
      weight: 30,
      repetitions: 9,
      rir: 2,
      completed: true,
    );
    final completed = original.copyWith(completedAt: at);
    final undone = completed.copyWith(
      completed: false,
      clearCompletedAt: true,
    );

    expect(undone.completed, isFalse);
    expect(undone.completedAt, isNull);
    expect(undone.weight, 30);
    expect(undone.repetitions, 9);
    expect(undone.rir, 2);
  });

  test('chave de dia do histórico é estável', () {
    final a = HistoryGrouping.dayKey(DateTime(2026, 3, 24, 9), 'plan_monday');
    final b = HistoryGrouping.dayKey(DateTime(2026, 3, 24, 22), 'plan_monday');
    expect(a, b);
    expect(a, '2026-03-24_plan_monday');
  });
}
