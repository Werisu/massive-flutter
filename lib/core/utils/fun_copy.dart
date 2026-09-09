/// Textos com personalidade de academia — leves, sem atrapalhar o fluxo.
abstract final class FunCopy {
  static const taglines = [
    'Hora de encher a manga.',
    'O pump não se faz sozinho.',
    'Menos conversa, mais série.',
    'A barra não vai se levantar sozinha.',
    'Braço grande, desculpa pequena.',
    'O sofá pode esperar.',
    'Tríceps não cresce no WhatsApp.',
    'Hoje o ego sobe junto com a carga.',
    'Costas largas, desculpas estreitas.',
    'Se arde um pouco, está no caminho.',
  ];

  static const setCheers = [
    'Série no bolso.',
    'Boa. Próxima.',
    'Isso. Mantém o padrão.',
    'Mais uma pra conta.',
    'Limpa. Respira.',
    'Fechou. Segue o protocolo.',
  ];

  static const prCheers = [
    'PR! Alguém avisa o espelho.',
    'Recorde novo. Não disfarça o sorriso.',
    'Marca pessoal. Isso fica no mural.',
    'PR no bolso. O próximo já está com medo.',
  ];

  static const finishHeadlines = [
    'Treino carimbado.',
    'Missão cumprida.',
    'Mais um tijolo na muralha.',
    'Sessão limpa. Pode ir embora em paz.',
  ];

  static const restTips = [
    'Respira. A próxima série não vai fugir.',
    'Água, ombros baixos, mente na carga.',
    'Descanso também conta como treino.',
    'Não scrolla o celular — visualiza a série.',
  ];

  static const dayOffNotes = [
    'Day off oficial. Crescer também é deitar, comer e dormir de verdade.',
    'Hoje o treino é recuperação. O músculo agradece o sofá.',
    'Sem culpa no descanso. Amanhã a barra volta.',
  ];

  static const hiitDoneNotes = [
    'Cardio no ponto. Pulmão e ego alinhados.',
    'Tiros no bolso. Agora é recuperar de verdade.',
    'Fechou o cardio. A musculação que agradeça.',
  ];

  static String pick(List<String> items, DateTime now, [int salt = 0]) {
    if (items.isEmpty) return '';
    final seed = now.year * 1000 + now.month * 40 + now.day + now.hour + salt;
    return items[seed.abs() % items.length];
  }

  static String tagline([DateTime? now]) => pick(taglines, now ?? DateTime.now());

  static String setCheer({
    required bool isWorking,
    DateTime? now,
  }) {
    if (!isWorking) return 'Aquecimento ok. Aquecendo o motor.';
    return pick(setCheers, now ?? DateTime.now(), 3);
  }

  static String prCheer([DateTime? now]) =>
      pick(prCheers, now ?? DateTime.now(), 7);

  static String finishHeadline({int prCount = 0, DateTime? now}) {
    if (prCount > 0) {
      return prCount == 1
          ? 'Treino carimbado — e ainda veio PR.'
          : 'Treino carimbado — $prCount PRs no mural.';
    }
    return pick(finishHeadlines, now ?? DateTime.now(), 11);
  }

  static String restTip([DateTime? now]) =>
      pick(restTips, now ?? DateTime.now(), 5);

  static String dayOffNote([DateTime? now]) =>
      pick(dayOffNotes, now ?? DateTime.now(), 2);

  static String hiitDoneNote([DateTime? now]) =>
      pick(hiitDoneNotes, now ?? DateTime.now(), 13);

  static String streakLabel(int days) {
    if (days <= 0) return '';
    if (days == 1) return '1 dia no ritmo';
    return '$days dias no ritmo';
  }

  static const emptyHistoryTitle = 'O mural ainda está em branco';
  static const emptyHistorySubtitle =
      'Finalize um treino (ou entre com Google no Perfil) e a história começa.';

  static const emptyProgressTitle = 'O gráfico está com fome';
  static const emptyProgressSubtitle =
      'Complete treinos para ver volume, recordes e o ego em forma de linha.';

  static const firstWorkoutTitle = 'O primeiro treino é o mais gostoso';
  static const firstWorkoutSubtitle =
      'Comece agora ou entre com Google no Perfil para trazer o histórico da nuvem.';
}
