import '../models/enums.dart';
import '../models/hiit_protocol.dart';

/// Cardio complementar ao protocolo Massive Arms — não altera séries do PDF.
///
/// Esteira **sem inclinação**: o estímulo vem só da velocidade.
/// Nos dias em que as pernas precisam render, caminhada rápida (sem correr).
/// HIIT de corrida só na quinta e no sábado.
abstract final class HiitData {
  static const briskWalkId = 'brisk_walk_15';
  static const hiitShortId = 'hiit_short_15';
  static const hiitQualityId = 'hiit_quality_22';
  static const easyWalkId = 'easy_walk_10';

  /// Id antigo — ainda abre a caminhada rápida.
  static const inclineWalkId = briskWalkId;

  static HiitProtocol get briskWalk => _briskWalk;
  static HiitProtocol get inclineWalk => _briskWalk;
  static HiitProtocol get hiitShort => _hiitShort;
  static HiitProtocol get hiitQuality => _hiitQuality;
  static HiitProtocol get easyWalk => _easyWalk;

  static final List<HiitProtocol> all = [
    _briskWalk,
    _hiitShort,
    _hiitQuality,
    _easyWalk,
  ];

  static HiitProtocol? byId(String id) {
    if (id == 'incline_walk_15') return _briskWalk;
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Prescrição do dia: protege terça (pernas) e reserva HIIT de qualidade
  /// para a quinta (Day Off) + um HIIT curto no sábado.
  static HiitProtocol forWeekday(Weekday day) {
    switch (day) {
      case Weekday.thursday:
        return _hiitQuality;
      case Weekday.saturday:
        return _hiitShort;
      case Weekday.sunday:
        return _easyWalk;
      case Weekday.monday:
      case Weekday.tuesday:
      case Weekday.wednesday:
      case Weekday.friday:
        return _briskWalk;
    }
  }
}

const _briskWalk = HiitProtocol(
  id: HiitData.briskWalkId,
  name: 'Caminhada rápida',
  mode: HiitMode.briskWalk,
  rationale:
      'Pós-musculação neste dia a prioridade é recuperar as pernas. '
      'Sem inclinação na esteira, o gasto vem de caminhar rápido — '
      'sem o impacto de correr.',
  cue:
      'Passada ampla e braços ativos. Se começar a trotar, baixe um pouco '
      'a velocidade. Bike ou elíptico valem com o mesmo tempo.',
  segments: [
    HiitSegment(
      duration: Duration(minutes: 2),
      speedMinKmh: 5.5,
      speedMaxKmh: 6,
      kind: HiitSegmentKind.warmup,
      label: 'Entrar no ritmo',
    ),
    HiitSegment(
      duration: Duration(minutes: 11),
      speedMinKmh: 6.5,
      speedMaxKmh: 7.5,
      kind: HiitSegmentKind.steady,
      label: 'Caminhada rápida',
    ),
    HiitSegment(
      duration: Duration(minutes: 2),
      speedMinKmh: 5,
      speedMaxKmh: 5.5,
      kind: HiitSegmentKind.cooldown,
      label: 'Desacelerar',
    ),
  ],
);

const _easyWalk = HiitProtocol(
  id: HiitData.easyWalkId,
  name: 'Caminhada leve',
  mode: HiitMode.easyWalk,
  isOptional: true,
  rationale:
      'Domingo já tem abdômen e panturrilha. Cardio é opcional e deve '
      'ser fácil — recuperação antes da semana.',
  cue: 'Se estiver fatigado, pule. Consistência na musculação vale mais.',
  segments: [
    HiitSegment(
      duration: Duration(minutes: 1),
      speedMinKmh: 5,
      speedMaxKmh: 5.5,
      kind: HiitSegmentKind.warmup,
      label: 'Começar leve',
    ),
    HiitSegment(
      duration: Duration(minutes: 8),
      speedMinKmh: 5.5,
      speedMaxKmh: 6,
      kind: HiitSegmentKind.steady,
      label: 'Caminhada fácil',
    ),
    HiitSegment(
      duration: Duration(minutes: 1),
      speedMinKmh: 5,
      speedMaxKmh: 5.5,
      kind: HiitSegmentKind.cooldown,
      label: 'Encerrar',
    ),
  ],
);

final _hiitShort = HiitProtocol(
  id: HiitData.hiitShortId,
  name: 'HIIT curto',
  mode: HiitMode.hiitShort,
  rationale:
      'Sábado está longe da terça de pernas e as pernas já descansaram '
      'desde a quinta. 15 min de intervalos curtos cabem depois da musculação '
      'sem virar um segundo treino pesado.',
  cue:
      'O trecho forte precisa ser intenso para o seu condicionamento, '
      'não um sprint máximo. Só mude a velocidade. Se as pernas pesarem, '
      'troque pela caminhada rápida. Bike vale com a mesma cadência 30s/60s.',
  segments: [
    const HiitSegment(
      duration: Duration(minutes: 2),
      speedMinKmh: 5.5,
      speedMaxKmh: 6.5,
      kind: HiitSegmentKind.warmup,
      label: 'Aquecimento',
    ),
    ..._workRecoverRounds(rounds: 6, lastRecover: false),
    const HiitSegment(
      duration: Duration(minutes: 5),
      speedMinKmh: 5,
      speedMaxKmh: 5.5,
      kind: HiitSegmentKind.cooldown,
      label: 'Desacelerar',
    ),
  ],
);

final _hiitQuality = HiitProtocol(
  id: HiitData.hiitQualityId,
  name: 'HIIT de qualidade',
  mode: HiitMode.hiitQuality,
  rationale:
      'Quinta é Day Off da musculação: pernas frescas e o único momento '
      'da semana em que o HIIT rende de verdade. Este é o bloco principal.',
  cue:
      'Aqui sim vale intensidade alta nos 30 s. Conforme ficar fácil, '
      'suba só a velocidade — não alongue o tempo. '
      'Se estiver muito cansado da semana, faça a caminhada rápida.',
  segments: [
    const HiitSegment(
      duration: Duration(minutes: 5),
      speedMinKmh: 5.5,
      speedMaxKmh: 6.5,
      kind: HiitSegmentKind.warmup,
      label: 'Aquecimento',
    ),
    ..._workRecoverRounds(rounds: 8, lastRecover: false),
    const HiitSegment(
      duration: Duration(minutes: 6),
      speedMinKmh: 5,
      speedMaxKmh: 5.5,
      kind: HiitSegmentKind.cooldown,
      label: 'Desacelerar',
    ),
  ],
);

/// [rounds] corridas de 30 s + recuperações de 60 s entre elas.
List<HiitSegment> _workRecoverRounds({
  required int rounds,
  required bool lastRecover,
}) {
  final segments = <HiitSegment>[];
  for (var i = 0; i < rounds; i++) {
    final last = i == rounds - 1;
    segments.add(
      HiitSegment(
        duration: const Duration(seconds: 30),
        speedMinKmh: 9,
        speedMaxKmh: 11,
        kind: HiitSegmentKind.work,
        label: last
            ? 'Última corrida ($rounds/$rounds)'
            : 'Corrida ${i + 1}/$rounds',
      ),
    );
    if (!last || lastRecover) {
      segments.add(
        const HiitSegment(
          duration: Duration(seconds: 60),
          speedMinKmh: 5.5,
          speedMaxKmh: 6.5,
          kind: HiitSegmentKind.recover,
          label: 'Recuperação (caminhar)',
        ),
      );
    }
  }
  return segments;
}
