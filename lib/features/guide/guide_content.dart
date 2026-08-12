/// Educational content from the Massive Arms protocol (instruction.md).
/// Not medical advice.
class GuideTopic {
  const GuideTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.body,
  });

  final String id;
  final String title;
  final String icon;
  final String body;
}

abstract final class GuideContent {
  static const disclaimer =
      'Conteúdo educacional do protocolo Massive Arms and Shoulders. '
      'Não constitui aconselhamento médico. Avalie suplementação e saúde '
      'com profissional habilitado.';

  static const topics = <GuideTopic>[
    GuideTopic(
      id: 'weekly_split',
      title: 'Divisão semanal',
      icon: 'calendar',
      body:
          'A divisão do protocolo Massive Arms and Shoulders:\n\n'
          '• Segunda — Tríceps e Costas\n'
          '• Terça — Inferiores\n'
          '• Quarta — Bíceps, Ombro e Peito\n'
          '• Quinta — Day Off\n'
          '• Sexta — Tríceps e Costas\n'
          '• Sábado — Bíceps, Ombro e Peito\n'
          '• Domingo — Abdômen e Panturrilha\n\n'
          'A quinta-feira é descanso programado. '
          'Não invente treinos extras fora dessa estrutura sem orientação.',
    ),
    GuideTopic(
      id: 'set_types',
      title: 'Tipos de séries',
      icon: 'layers',
      body:
          'Cada exercício do protocolo pode ter três tipos de séries:\n\n'
          '• Aquecimento — em geral 10 reps, carga leve para preparar o padrão.\n'
          '• Preparatórias — faixa tipicamente 2–7 reps, aproximando a carga de trabalho.\n'
          '• Valendo — faixa 8–10 reps; são as séries que contam para progressão.\n\n'
          'A estrutura (quantas séries de cada tipo) já vem definida no PDF. '
          'Não altere arbitrariamente o número de séries.',
    ),
    GuideTopic(
      id: 'execution',
      title: 'Execução dos exercícios',
      icon: 'fitness_center',
      body:
          'Priorize amplitude completa e qualidade técnica antes de aumentar carga.\n\n'
          'O protocolo enfatiza tensão mecânica com boa execução. '
          'Não sacrifique a forma para carregar mais peso.\n\n'
          'Quando houver vídeo cadastrado no app, use-o como referência de execução.',
    ),
    GuideTopic(
      id: 'progression',
      title: 'Progressão de cargas',
      icon: 'trending_up',
      body:
          'Ordem de progressão do protocolo:\n\n'
          '1. Melhorar execução e amplitude.\n'
          '2. Fazer mais repetições com o mesmo peso.\n'
          '3. Aumentar o peso.\n'
          '4. Aumentar o número de séries semanais (só se o protocolo indicar).\n\n'
          'Não altere arbitrariamente o número de séries — a estrutura já está '
          'estabelecida no protocolo.\n\n'
          'Na faixa de 8–10 reps: ao atingir 10 com boa execução, considere '
          'um pequeno aumento de carga no próximo treino.\n\n'
          'O app pode sugerir essa progressão com base no seu histórico, '
          'sem mudar as séries sozinho.',
    ),
    GuideTopic(
      id: 'tension',
      title: 'Tensão mecânica',
      icon: 'bolt',
      body:
          'A tensão mecânica é o principal estímulo hipertrófico do protocolo.\n\n'
          'Mantenha controle do movimento e evite impulso excessivo, '
          'especialmente nas séries valendo.\n\n'
          'Amplitude completa + carga adequada + controle = mais tensão útil.',
    ),
    GuideTopic(
      id: 'rest',
      title: 'Intervalo de descanso',
      icon: 'timer',
      body:
          'Segundo o protocolo:\n\n'
          '• Séries de aquecimento/preparatórias: aproximadamente 1 minuto.\n'
          '• Séries valendo: 2–5 minutos, conforme exercício e intensidade.\n\n'
          'No app você pode ajustar, pausar, reiniciar ou pular o cronômetro. '
          'Em Android/iOS o fim do descanso pode disparar notificação mesmo '
          'fora da tela.',
    ),
    GuideTopic(
      id: 'rir',
      title: 'Repetições em reserva (RIR)',
      icon: 'tune',
      body:
          'RIR é a quantidade de repetições que faltariam para chegar à falha.\n\n'
          'Exemplo: falharia na 10ª, parou na 9ª → RIR = 1.\n\n'
          'Séries valendo:\n'
          '• Multiarticulares: 0–2 RIR (na última série pode chegar à falha).\n'
          '• Monoarticulares: pode explorar falha nas séries valendo.\n\n'
          'Registre o RIR após cada série valendo para acompanhar intensidade '
          'ao longo das semanas.',
    ),
    GuideTopic(
      id: 'logging',
      title: 'Como registrar o treino',
      icon: 'edit',
      body:
          'Durante a sessão:\n\n'
          '1. Informe carga, reps e RIR da série atual.\n'
          '2. Marque a série como concluída.\n'
          '3. Use o timer de descanso entre séries.\n'
          '4. Se errar, desfaça ou edite a série já marcada.\n\n'
          'O app pré-preenche carga/reps com base na última série relevante '
          'do mesmo exercício.\n\n'
          'Ao terminar, finalize o treino para salvar no histórico local '
          '(e sincronizar se estiver logado).',
    ),
    GuideTopic(
      id: 'shoes',
      title: 'Tênis de musculação',
      icon: 'sports',
      body:
          'O protocolo aborda o uso de calçado adequado para estabilidade '
          'nos exercícios de musculação.\n\n'
          'Prefira solado firme que permita base estável em agachamentos '
          'e movimentos em pé.',
    ),
    GuideTopic(
      id: 'cadence',
      title: 'Cadência de movimento',
      icon: 'speed',
      body:
          'Controle a fase excêntrica e a concêntrica.\n\n'
          'Evite acelerar demais o movimento nas séries valendo; '
          'a cadência controlada favorece tensão mecânica e reduz o uso '
          'de impulso.',
    ),
    GuideTopic(
      id: 'sleep',
      title: 'Sono',
      icon: 'bedtime',
      body:
          'O protocolo recomenda 7–9 horas de sono por noite.\n\n'
          'O sono é parte da recuperação. Nesta versão o app apresenta '
          'a orientação; registro avançado de sono pode ser adicionado no futuro.',
    ),
    GuideTopic(
      id: 'supplements',
      title: 'Suplementação',
      icon: 'science',
      body:
          'Informações mencionadas no protocolo (conteúdo educacional):\n\n'
          '• Creatina: 5 g/dia\n'
          '• Cafeína/pré-treino: 3–6 mg/kg\n'
          '• Whey protein: facilitador para atingir a ingestão diária de proteínas\n'
          '• Proteína: 1,6 a 2,2 g/kg\n\n'
          'Suplementação deve ser avaliada individualmente por profissional habilitado.\n\n'
          'O app não realiza prescrição.',
    ),
    GuideTopic(
      id: 'equipment',
      title: 'Equipamentos — Strap',
      icon: 'handshake',
      body:
          'O protocolo destaca o uso de strap nas séries valendo de costas '
          'e padrões de levantamento terra.\n\n'
          'Isso é uma orientação educativa do protocolo, não uma obrigação universal.',
    ),
  ];

  static GuideTopic? byId(String id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }
}
