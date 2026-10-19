import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/data/firebase/firebase_mappers.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/seed/full_body_data.dart';
import 'package:massive_arms/data/seed/protocol_data.dart';

void main() {
  test('full body treina segunda, quarta e sexta', () {
    expect(FullBodyData.plans.length, 7);
    expect(FullBodyData.session.length, 8);

    for (final day in [Weekday.monday, Weekday.wednesday, Weekday.friday]) {
      final plan = ProtocolData.planFor(TrainingSplit.fullBody, day);
      expect(plan.name, 'Full Body');
      expect(plan.isDayOff, isFalse);
      expect(plan.exerciseCount, 8);
      expect(plan.exercises.first.exerciseId, 'ex_agachamento_smith_hack');
      expect(plan.exercises[6].exerciseId, 'ex_rosca_banco_inclinado');
      expect(plan.exercises.last.exerciseId, 'ex_triceps_cabo');
    }

    expect(
      ProtocolData.planFor(TrainingSplit.fullBody, Weekday.tuesday).isDayOff,
      isTrue,
    );
    expect(
      ProtocolData.planFor(TrainingSplit.fullBody, Weekday.thursday).isDayOff,
      isTrue,
    );
  });

  test('compostos em 6-10 e braços em 8-12, três séries valendo', () {
    final squat = FullBodyData.session.first;
    expect(squat.sets.length, 3);
    expect(squat.sets.every((s) => s.type == SetType.working), isTrue);
    expect(squat.sets.first.repMin, 6);
    expect(squat.sets.first.repMax, 10);

    final curl = FullBodyData.session[6];
    expect(curl.sets.first.repMin, 8);
    expect(curl.sets.first.repMax, 12);

    expect(
      ProtocolData.setsSummary(
        'ex_agachamento_smith_hack',
        split: TrainingSplit.fullBody,
      ),
      'Valendo 3x6-10',
    );
    expect(
      ProtocolData.setsSummary(
        'ex_triceps_cabo',
        split: TrainingSplit.fullBody,
      ),
      'Valendo 3x8-12',
    );
  });

  test('histórico resolve o plano full body e o protocolo', () {
    expect(ProtocolData.planById('fb_monday')?.name, 'Full Body');
    expect(ProtocolData.planById('plan_monday')?.name, 'Tríceps e Costas');
    expect(FirebaseMappers.planIdFromDayId('fb_quarta'), 'fb_wednesday');
    expect(FirebaseMappers.dayIdFromPlanId('fb_friday'), 'fb_sexta');
    expect(FirebaseMappers.planIdFromDayId('segunda'), 'plan_monday');
  });

  test('trocar a divisão não altera o protocolo', () {
    expect(ProtocolData.plans.length, 7);
    expect(
      ProtocolData.planFor(TrainingSplit.protocol, Weekday.monday).name,
      'Tríceps e Costas',
    );
    expect(
      ProtocolData.plansContainingExercise(
        'ex_martelo',
        split: TrainingSplit.fullBody,
      ),
      isEmpty,
    );
  });
}
