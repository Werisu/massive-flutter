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
      id: 'execution',
      title: 'Execução dos exercícios',
      icon: 'fitness_center',
      body:
          'Priorize amplitude completa e qualidade técnica antes de aumentar carga.\n\n'
          'O protocolo enfatiza tensão mecânica com boa execução. '
          'Não sacrifique a forma para carregar mais peso.',
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
          '4. Aumentar o número de séries semanais.\n\n'
          'Não altere arbitrariamente o número de séries — a estrutura já está '
          'estabelecida no protocolo.\n\n'
          'Na faixa de 8–10 reps: ao atingir 10 com boa execução, considere '
          'um pequeno aumento de carga no próximo treino.',
    ),
    GuideTopic(
      id: 'tension',
      title: 'Tensão mecânica',
      icon: 'bolt',
      body:
          'A tensão mecânica é o principal estímulo hipertrófico do protocolo.\n\n'
          'Mantenha controle do movimento e evite impulso excessivo, '
          'especialmente nas séries valendo.',
    ),
    GuideTopic(
      id: 'rest',
      title: 'Intervalo de descanso',
      icon: 'timer',
      body:
          'Segundo o protocolo:\n\n'
          '• Séries de aquecimento/preparatórias: aproximadamente 1 minuto.\n'
          '• Séries valendo: 2–5 minutos, conforme exercício e intensidade.\n\n'
          'No app você pode ajustar, pausar ou pular o cronômetro.',
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
          '• Monoarticulares: pode explorar falha nas séries valendo.',
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
          'a cadência controlada favorece tensão mecânica.',
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
