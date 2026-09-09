import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/utils/fun_copy.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/workout_session.dart';
import 'package:massive_arms/data/services/workout_streak.dart';

WorkoutSession _finishedOn(DateTime day) {
  return WorkoutSession(
    id: 's-${day.toIso8601String()}',
    workoutPlanId: 'plan_monday',
    startedAt: day,
    finishedAt: day.add(const Duration(minutes: 40)),
    exercises: const [],
  );
}

void main() {
  final mon = DateTime(2026, 9, 7, 10);
  final tue = DateTime(2026, 9, 8, 10);
  final wed = DateTime(2026, 9, 9, 10);
  final thu = DateTime(2026, 9, 10, 10);
  final fri = DateTime(2026, 9, 11, 10);

  test('copy rotativa é determinística no mesmo horário', () {
    final a = DateTime(2026, 9, 9, 8);
    expect(FunCopy.tagline(a), FunCopy.tagline(a));
    expect(FunCopy.tagline(a), isNotEmpty);
    expect(
      FunCopy.prCheer(a),
      anyOf(contains('PR'), contains('Recorde'), contains('Marca')),
    );
  });

  test('headline de finish destaca PRs', () {
    expect(FunCopy.finishHeadline(prCount: 0, now: wed), isNotEmpty);
    expect(FunCopy.finishHeadline(prCount: 1), contains('PR'));
    expect(FunCopy.finishHeadline(prCount: 3), contains('3 PRs'));
  });

  test('label da sequência', () {
    expect(FunCopy.streakLabel(0), '');
    expect(FunCopy.streakLabel(1), '1 dia no ritmo');
    expect(FunCopy.streakLabel(4), '4 dias no ritmo');
  });

  test('sequência conta dias consecutivos de treino', () {
    final sessions = [_finishedOn(mon), _finishedOn(tue), _finishedOn(wed)];
    expect(WorkoutStreak.current(sessions, now: wed), 3);
  });

  test('day off do protocolo não quebra a sequência', () {
    expect(Weekday.fromDateTime(thu), Weekday.thursday);
    final sessions = [_finishedOn(mon), _finishedOn(tue), _finishedOn(wed)];
    expect(WorkoutStreak.current(sessions, now: thu), 3);
  });

  test('pular um dia de treino zera a sequência', () {
    final sessions = [_finishedOn(mon), _finishedOn(wed)];
    expect(WorkoutStreak.current(sessions, now: wed), 1);
  });

  test('day off no meio ainda conta a sequência até o último treino', () {
    final sessions = [_finishedOn(wed)];
    expect(WorkoutStreak.current(sessions, now: fri), 1);
  });

  test('sem treinos a sequência é zero', () {
    expect(WorkoutStreak.current(const [], now: wed), 0);
  });
}
