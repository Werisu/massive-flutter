import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/utils/formatters.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';

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
}
