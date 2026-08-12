import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/data/firebase/firebase_mappers.dart';
import 'package:massive_arms/data/firebase/legacy_workout_mapper.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/services/history_grouping.dart';

void main() {
  late List<dynamic> rawSessions;

  setUpAll(() {
    final file = File('test/fixtures/legacy_workout_history.json');
    expect(file.existsSync(), isTrue, reason: 'fixture ausente');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    rawSessions = json['sessions'] as List<dynamic>;
  });

  test('mapeia dayId legado para planId do protocolo', () {
    expect(FirebaseMappers.planIdFromDayId('segunda'), 'plan_monday');
    expect(FirebaseMappers.planIdFromDayId('sabado'), 'plan_saturday');
    expect(FirebaseMappers.dayIdFromPlanId('plan_friday'), 'sexta');
  });

  test('resolve exerciseId legado e por nome', () {
    expect(
      FirebaseMappers.resolveExerciseId('seg-1', null),
      'ex_triceps_barra_v',
    );
    expect(
      FirebaseMappers.resolveExerciseId(null, 'Scott Máquina'),
      'ex_scott_maquina',
    );
  });

  test('fixture legado vira WorkoutSession com séries tipadas', () {
    final sessions = LegacyWorkoutMapper.mapSessions(rawSessions);
    expect(sessions.length, rawSessions.length);

    final monday = sessions.firstWhere((s) => s.workoutPlanId == 'plan_monday');
    expect(monday.id, 'session-1782480000475');
    expect(monday.isFinished, isTrue);
    expect(monday.exercises, isNotEmpty);

    final firstEx = monday.exercises.first;
    expect(firstEx.exerciseId, 'ex_triceps_barra_v');
    expect(firstEx.sets.length, 6);
    expect(firstEx.sets.first.setType, SetType.warmup);
    expect(firstEx.sets.last.setType, SetType.working);
    expect(firstEx.sets.last.weight, 60);
  });

  test('sessões de sábado fragmentadas agrupam no mesmo dia', () {
    final sessions = LegacyWorkoutMapper.mapSessions(rawSessions);
    final saturday = sessions.where((s) => s.workoutPlanId == 'plan_saturday');
    expect(saturday.length, greaterThanOrEqualTo(2));

    final days = HistoryGrouping.groupFinishedSessions(saturday.toList());
    expect(days.length, 1);
    expect(days.first.sessionCount, saturday.length);
  });

  test('round-trip parcial para formato legado preserva dayId e cargas', () {
    final sessions = LegacyWorkoutMapper.mapSessions(rawSessions);
    final original = sessions.firstWhere((s) => s.workoutPlanId == 'plan_monday');
    final legacy = LegacyWorkoutMapper.toLegacySession(original);

    expect(legacy['dayId'], 'segunda');
    expect(legacy['id'], original.id);

    final remapped = LegacyWorkoutMapper.mapSession(legacy);
    expect(remapped, isNotNull);
    expect(remapped!.workoutPlanId, 'plan_monday');
    expect(remapped.exercises.first.exerciseId, 'ex_triceps_barra_v');
    expect(
      remapped.exercises.first.sets.where((s) => s.completed).length,
      original.exercises.first.sets.where((s) => s.completed).length,
    );
  });

  test('legacyCompletedSets conta séries no payload legado', () {
    final sessions = LegacyWorkoutMapper.mapSessions(rawSessions);
    final legacy = LegacyWorkoutMapper.toLegacySession(sessions.first);
    expect(
      LegacyWorkoutMapper.legacyCompletedSets(legacy),
      greaterThan(0),
    );
  });
}
