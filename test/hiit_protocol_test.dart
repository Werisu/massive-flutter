import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/data/models/enums.dart';
import 'package:massive_arms/data/models/hiit_protocol.dart';
import 'package:massive_arms/data/seed/hiit_data.dart';

void main() {
  test('nenhum dia prescreve cardio em modo hipertrofia', () {
    for (final day in Weekday.values) {
      expect(HiitData.forWeekday(day), isNull);
    }
  });

  test('HIIT de qualidade tem 8 tiros de 30 s', () {
    final protocol = HiitData.hiitQuality;
    expect(protocol.mode, HiitMode.hiitQuality);
    expect(protocol.workRounds, 8);
    expect(protocol.totalDuration, const Duration(minutes: 22));
    expect(
      protocol.segments.where((s) => s.kind == HiitSegmentKind.work).every(
            (s) => s.duration == const Duration(seconds: 30),
          ),
      isTrue,
    );
  });

  test('HIIT curto tem 15 min com 6 tiros', () {
    final protocol = HiitData.hiitShort;
    expect(protocol.mode, HiitMode.hiitShort);
    expect(protocol.workRounds, 6);
    expect(protocol.totalDuration, const Duration(minutes: 15));
  });

  test('caminhada rápida e leve existem mas não são prescritas', () {
    expect(HiitData.briskWalk.mode, HiitMode.briskWalk);
    expect(HiitData.briskWalk.totalDuration, const Duration(minutes: 15));
    expect(HiitData.easyWalk.isOptional, isTrue);
    expect(HiitData.easyWalk.totalDuration, const Duration(minutes: 10));
  });

  test('HIIT curto não tem recuperação depois da última corrida', () {
    final segments = HiitData.hiitShort.segments;
    expect(segments.last.kind, HiitSegmentKind.cooldown);
    expect(segments[segments.length - 2].kind, HiitSegmentKind.work);
  });

  test('lookup por id funciona', () {
    expect(HiitData.byId(HiitData.hiitQualityId)?.name, 'HIIT de qualidade');
    expect(HiitData.byId('inexistente'), isNull);
    expect(HiitData.byId('incline_walk_15')?.mode, HiitMode.briskWalk);
  });

  test('protocolos da esteira não usam inclinação', () {
    for (final protocol in HiitData.all) {
      expect(
        protocol.segments.every((s) => !s.hasIncline),
        isTrue,
        reason: protocol.id,
      );
    }
  });
}
