Quero desenvolver um aplicativo mobile em Flutter baseado integralmente no protocolo de treinamento presente no PDF "Massive Arms and Shoulders".

IMPORTANTE:

- Antes de escrever código, analise todo o PDF disponível no projeto.
- O PDF é a fonte principal dos dados do aplicativo.
- Não invente exercícios, séries, repetições ou regras que não estejam no PDF.
- Não altere a estrutura do treino sem minha autorização.
- O aplicativo deve transformar o conteúdo do PDF em uma experiência de aplicativo de musculação moderna, intuitiva e funcional.
- O objetivo NÃO é simplesmente transformar cada página do PDF em uma tela. Quero um aplicativo real de acompanhamento de treino.
- Use Flutter com uma arquitetura limpa e escalável.
- O aplicativo deve funcionar inicialmente de forma local/offline, sem necessidade de backend.
- Prepare a arquitetura para que futuramente seja possível adicionar autenticação, sincronização em nuvem e banco de dados remoto.

==================================================

1. # TECNOLOGIA

Utilize:

- Flutter
- Dart
- Material 3
- Arquitetura organizada por features
- Gerenciamento de estado moderno e simples de manter
- Persistência local
- Navegação declarativa
- Componentes reutilizáveis
- Código null-safe
- Separação clara entre:
  - UI
  - estado
  - domínio
  - dados
  - modelos

Se o projeto ainda não possuir uma solução de gerenciamento de estado, escolha uma solução moderna e apropriada para Flutter e mantenha a implementação consistente em todo o projeto.

Para persistência local, escolha uma solução adequada para armazenar:

- histórico dos treinos
- cargas
- repetições
- RIR
- séries concluídas
- progresso
- configurações do usuário

================================================== 2. IDENTIDADE VISUAL
==================================================

A identidade visual deve ser inspirada no PDF.

Características principais:

- Tema escuro como padrão.
- Preto como cor predominante.
- Roxo/violeta como cor de destaque.
- Branco para textos principais.
- Cinza para informações secundárias.
- Cards com cantos arredondados.
- Visual moderno e premium.
- Aparência de aplicativo fitness profissional.
- Interface limpa, sem excesso de elementos.
- Alto contraste.
- Microinterações discretas.
- Animações suaves.
- Tipografia forte para títulos.
- Destaques em roxo para ações importantes.

Não copie literalmente o layout das páginas do PDF.

Use o PDF como referência de:

- conteúdo
- hierarquia
- identidade visual
- organização
- nomenclatura

Mas transforme isso em uma UI mobile moderna.

================================================== 3. ESTRUTURA PRINCIPAL DO APLICATIVO
==================================================

Crie uma navegação inferior com aproximadamente:

1. Início
2. Treinos
3. Progresso
4. Exercícios
5. Perfil

A navegação deve ser simples e intuitiva.

================================================== 4. TELA INÍCIO
==================================================

Criar uma Home/Dashboard.

Ela deve mostrar:

- Saudação ao usuário.
- Treino do dia.
- Dia da semana.
- Nome do treino.
- Quantidade de exercícios.
- Progresso do treino atual.
- Botão "Começar treino".
- Último treino realizado.
- Resumo de progresso.
- Atalhos para exercícios e histórico.

Exemplo:

"Bom dia, Wellysson"

"Treino de hoje"

"QUARTA — BÍCEPS, OMBRO E PEITO"

[Começar treino]

Também mostrar algo como:

"Seu último treino"

- exercício
- carga
- repetições
- evolução

Não crie informações falsas. Quando ainda não houver histórico, mostrar estado vazio apropriado.

================================================== 5. TELA DE TREINOS
==================================================

Criar uma tela mostrando a divisão semanal do PDF.

A divisão é:

SEGUNDA
Tríceps e Costas

TERÇA
Inferiores

QUARTA
Bíceps, Ombro e Peito

QUINTA
Day Off

SEXTA
Tríceps e Costas

SÁBADO
Bíceps, Ombro e Peito

DOMINGO
Abdomen e Panturrilha

Cada dia deve ser um card.

O usuário pode tocar no dia e abrir o treino.

Para quinta-feira, mostrar claramente:
"DAY OFF"

================================================== 6. DADOS DOS TREINOS
==================================================

Cadastrar os exercícios exatamente conforme o PDF.

SEGUNDA — TRÍCEPS E COSTAS

1. Tríceps Barra V de Costas
   Aquecimento: 2x10
   Preparatórias: 2x2-7
   Valendo: 2x8-10

2. Tríceps Polia Alta Caneleira
   Preparatórias: 1x2-7
   Valendo: 2x8-10

3. Posterior 45 Graus
   Aquecimento: 1x10
   Preparatórias: 1x2-7
   Valendo: 2x8-10

4. Puxada Pronada Polia Média
   Preparatórias: 2x2-7
   Valendo: 2x8-10

5. Puxada Unilateral Variação
   Preparatórias: 1x2-7
   Valendo: 3x8-10

6. Remada Pronada Máquina
   Preparatórias: 1x2-7
   Valendo: 2x8-10

TERÇA — INFERIORES

1. Panturrilha Leg Press Horizontal
   Aquecimento: 1x10
   Preparatórias: 2x2-7
   Valendo: 2x8-10

2. Mesa ou Cadeira Flexora
   Aquecimento: 2x10
   Preparatórias: 2x2-7
   Valendo: 2x8-10

3. Agachamento Smith ou Hack Squat
   Preparatórias: 2x2-7
   Valendo: 2x8-10

4. Stiff Barra
   Preparatórias: 2x2-7
   Valendo: 2x8-10

5. Extensora Unilateral
   Preparatórias: 1x2-7
   Valendo: 2x8-10

6. Cadeira Adutora
   Preparatórias: 1x2-7
   Valendo: 2x8-10

QUARTA — BÍCEPS, OMBRO E PEITO

1. Martelo Bilateral-Unilateral
   Aquecimento: 2x10
   Preparatórias: 1-2x2-7
   Valendo: 2x8-10

2. Rosca Polia Unilateral
   Preparatórias: 1-2x2-7
   Valendo: 2x8-10

3. Elevação Lateral por Trás do Corpo
   Aquecimento: 1x10
   Preparatórias: 1-2x2-7
   Valendo: 3x8-10

4. Supino Inclinado no Smith ou Halteres
   Aquecimento: 1x10
   Preparatórias: 2x2-7
   Valendo: 2x8-10

5. Paralela ou Cross Over Polia Alta
   Preparatórias: 1x2-7
   Valendo: 2x8-10

6. Peck Deck Fly ou Crucifixo Polia
   Preparatórias: 1x2-7
   Valendo: 2x8-10

7. Extensão de Punho
   Preparatórias: 1x2-7
   Valendo: 2x8-10

SEXTA — TRÍCEPS E COSTAS

1. Tríceps Cabo Bilateral ou Corda
   Aquecimento: 2x10
   Preparatórias: 2x2-7
   Valendo: 2x8-10

2. Frances na Polia Unilateral
   Preparatórias: 1x2-7
   Valendo: 2x8-10

3. Crucifixo Inverso
   Aquecimento: 1x10
   Preparatórias: 1-2x2-7
   Valendo: 2x8-10

4. Remada Supinada Máquina
   Preparatórias: 1x2-7
   Valendo: 2x8-10

5. Puxada Super Aberta e Pronada
   Preparatórias: 1x2-7
   Valendo: 2x8-10

6. Kelso Shrug ou Smith
   Preparatórias: 1x2-7
   Valendo: 2x8-10

SÁBADO — BÍCEPS, OMBRO E PEITO

1. Scott Máquina
   Preparatórias: 2x2-7
   Valendo: 2x8-10

2. Rosca Banco Inclinado Alternada
   Preparatórias: 1x2-7
   Valendo: 2x8-10

3. Elevação Lateral Peito Apoiado
   Aquecimento: 1x10
   Preparatórias: 2x2-7
   Valendo: 3x8-10

4. Desenvolvimento Smith ou com Halteres
   Preparatórias: 2x2-7
   Valendo: 2x8-10

5. Supino Reto no Smith ou com Halteres
   Preparatórias: 2x2-7
   Valendo: 2x8-10

6. Flexão Punho
   Preparatórias: 1x2-7
   Valendo: 3x8-10

DOMINGO — ABDOMEN E PANTURRILHA

1. Abdominal Polia de Costas
   Valendo: 2x8-10

2. Abdominal no Banco Romano
   Valendo: 2x8-10

3. Panturrilha Leg Press Horizontal
   Aquecimento: 1x10
   Preparatórias: 2x2-7
   Valendo: 2x8-10

================================================== 7. TELA DE EXECUÇÃO DO TREINO
==================================================

Essa é uma das telas mais importantes do aplicativo.

Quando o usuário iniciar um treino, mostrar:

- Nome do treino
- Progresso geral
- Exercício atual
- Número do exercício
- Lista de séries
- Tipo da série
- Repetições alvo
- Campo para carga
- Campo para repetições realizadas
- Campo para RIR
- Checkbox/botão para marcar série concluída
- Cronômetro de descanso
- Botão para vídeo de execução

Exemplo:

SUPINO INCLINADO
Smith ou Halteres

Série 1
Preparatória
2-7 reps
Carga: [ ]
Reps: [ ]
RIR: [ ]

Série 2
Valendo
8-10 reps
Carga: [ ]
Reps: [ ]
RIR: [ ]

[ CONCLUIR SÉRIE ]

Após concluir uma série:

- iniciar opção de descanso
- mostrar cronômetro
- permitir pular o descanso
- permitir ajustar o tempo

================================================== 8. REGISTRO DE CARGAS
==================================================

Uma das funcionalidades mais importantes.

O usuário deve conseguir registrar:

- carga utilizada
- repetições realizadas
- RIR
- série
- observação opcional

O aplicativo deve salvar esses dados localmente.

No próximo treino, mostrar automaticamente o desempenho anterior.

Exemplo:

Último treino:
30 kg × 8 reps

Novo treino:
Carga: 30 kg
Meta: 8-10 reps

Se o usuário fizer 10 reps, mostrar indicação visual de que atingiu o topo da faixa.

================================================== 9. PROGRESSÃO DE CARGA
==================================================

O PDF explica a progressão desta maneira:

1. Melhorar execução e amplitude.
2. Fazer mais repetições com o mesmo peso.
3. Aumentar o peso.
4. Aumentar o número de séries semanais.

Porém, o PDF também orienta a não alterar arbitrariamente o número de séries porque isso já está estabelecido no protocolo.

Implemente isso no aplicativo como orientação.

Para exercícios com faixa de 8-10:

Exemplo:

Semana anterior:
30 kg × 8

Atual:
30 kg × 9

Mostrar:
"Boa evolução: +1 repetição"

Quando atingir 10 reps com boa execução:
"Você atingiu o topo da faixa."

O aplicativo pode sugerir:
"Considere um pequeno aumento de carga no próximo treino."

Não altere automaticamente a carga.

================================================== 10. RIR — REPETIÇÕES EM RESERVA
==================================================

Criar suporte para RIR.

O PDF explica RIR como a quantidade de repetições que faltariam para chegar à falha.

Exemplo:

Falharia na 10ª repetição.
Parou na 9ª.
RIR = 1.

Adicionar seletor:

RIR:
0
1
2
3
4+

Também exibir uma explicação curta quando o usuário tocar no campo.

Para as séries valendo:

Multiarticulares:
0-2 RIR
Na última série pode chegar à falha.

Monoarticulares:
Pode explorar falha nas séries valendo.

Não transforme isso em recomendação médica. Apenas apresente o protocolo do PDF.

================================================== 11. DESCANSO
==================================================

Implementar cronômetro de descanso.

Segundo o PDF:

Séries de aquecimento/preparatórias:
aproximadamente 1 minuto.

Séries valendo:
2-5 minutos, dependendo do exercício e intensidade.

Permitir:

- iniciar cronômetro
- pausar
- reiniciar
- pular
- ajustar duração

================================================== 12. VÍDEOS DOS EXERCÍCIOS
==================================================

O PDF possui uma coluna "Vídeo do exercício" para cada exercício.

A arquitetura deve suportar:

Exercise

- id
- name
- description
- videoUrl
- thumbnailUrl
- muscleGroup
- instructions

Inicialmente, caso não exista URL de vídeo disponível no PDF/projeto:

- não inventar URLs.
- mostrar botão "Vídeo indisponível" ou esconder o botão.

Criar a arquitetura para futuramente cadastrar URLs.

Ao clicar no vídeo:
abrir uma tela/modal de reprodução.

================================================== 13. TELA DE EXERCÍCIOS
==================================================

Criar uma biblioteca de exercícios.

Permitir pesquisar por nome.

Filtros:

- Bíceps
- Tríceps
- Ombros
- Peito
- Costas
- Pernas
- Abdômen
- Panturrilha
- Antebraço

Cada exercício deve possuir:

- nome
- grupo muscular
- treinos em que aparece
- faixa de repetições
- séries
- vídeo, quando disponível
- histórico do usuário

================================================== 14. TELA DE PROGRESSO
==================================================

Criar dashboard de progresso.

Mostrar:

- evolução de carga
- evolução de repetições
- histórico por exercício
- melhores marcas
- frequência de treino
- treinos concluídos
- volume registrado

Criar gráficos simples e legíveis.

Exemplo:

SUPINO RETO

30 kg
8 reps

↓

30 kg
9 reps

↓

30 kg
10 reps

O objetivo é mostrar claramente a evolução ao longo dos treinos.

================================================== 15. HISTÓRICO
==================================================

O usuário deve conseguir visualizar treinos anteriores.

Exemplo:

11/08/2026
Quarta — Bíceps, Ombro e Peito
6/7 exercícios concluídos

Ao abrir:

- exercícios
- séries
- cargas
- repetições
- RIR
- duração do treino

================================================== 16. INFORMAÇÕES DO PROTOCOLO
==================================================

Criar uma seção "Guia" ou "Conheça o protocolo".

Ela deve apresentar de maneira resumida o conteúdo educativo do PDF:

- Execução dos exercícios
- Progressão de cargas
- Tensão mecânica
- Intervalo de descanso
- Repetições em reserva
- Tênis de musculação
- Cadência de movimento
- Sono
- Suplementação
- Equipamentos

IMPORTANTE:

Não transformar as informações em aconselhamento médico.

Apresentar como conteúdo educacional pertencente ao protocolo.

================================================== 17. SUPLEMENTAÇÃO
==================================================

O PDF menciona:

- Creatina: 5 g/dia
- Cafeína/pré-treino: 3-6 mg/kg
- Whey protein como facilitador para atingir a ingestão diária de proteínas
- recomendação de proteína de 1,6 a 2,2 g/kg

Essas informações devem aparecer somente como conteúdo do protocolo.

Não criar sistema de prescrição.

Adicionar aviso de que suplementação deve ser avaliada individualmente por profissional habilitado quando apropriado.

================================================== 18. SONO
==================================================

O PDF recomenda:

7-9 horas de sono por noite.

Criar uma seção informativa.

Opcionalmente preparar arquitetura para futuramente registrar:

- horas dormidas
- qualidade do sono

Mas não é necessário implementar rastreamento avançado nesta primeira versão.

================================================== 19. EQUIPAMENTO — STRAP
==================================================

O PDF destaca o uso de strap nas séries valendo de costas e padrões de levantamento terra.

Criar isso como uma informação educativa dentro do guia.

Não transformar em obrigação universal.

================================================== 20. MODELOS DE DADOS
==================================================

Criar modelos bem estruturados.

Sugestão:

WorkoutPlan

- id
- name
- weekday
- exercises

WorkoutExercise

- id
- exerciseId
- order
- warmupSets
- preparationSets
- workingSets
- targetRepMin
- targetRepMax

Exercise

- id
- name
- muscleGroup
- videoUrl
- description

WorkoutSession

- id
- workoutPlanId
- startedAt
- finishedAt
- exercises

SetRecord

- id
- exerciseId
- setType
- setNumber
- weight
- repetitions
- rir
- completedAt
- notes

Não crie estruturas excessivamente complexas sem necessidade.

================================================== 21. BANCO LOCAL
==================================================

Escolha uma solução local apropriada.

O aplicativo deve continuar funcionando sem internet.

Persistir:

- treinos
- histórico
- cargas
- repetições
- RIR
- preferências
- progresso

================================================== 22. ESTADOS DA INTERFACE
==================================================

Todas as telas devem considerar:

- loading
- vazio
- erro
- sucesso
- primeiro uso

Não deixar telas quebradas quando não houver dados.

Exemplo:

Se não houver histórico:

"Ainda não há treinos registrados."

[Começar primeiro treino]

================================================== 23. EXPERIÊNCIA DO USUÁRIO
==================================================

Quero uma experiência semelhante à de aplicativos modernos de fitness.

Prioridades:

1. Registrar uma série deve ser extremamente rápido.
2. O usuário não deve precisar navegar por várias telas.
3. Mostrar a carga anterior de maneira muito clara.
4. Facilitar a comparação entre treino atual e anterior.
5. Ter botões grandes o suficiente para uso durante o treino.
6. Evitar excesso de texto durante a execução.
7. O conteúdo educativo deve ficar separado da execução do treino.

================================================== 24. RESPONSIVIDADE
==================================================

O aplicativo deve funcionar bem em:

- celulares pequenos
- celulares grandes
- Android
- iOS

Não assumir tamanho fixo de tela.

Utilizar SafeArea.

Evitar overflow.

================================================== 25. ACESSIBILIDADE
==================================================

Adicionar:

- contraste adequado
- textos legíveis
- áreas de toque adequadas
- suporte básico a escalonamento de fonte
- labels semânticos
- feedback visual para ações

================================================== 26. ARQUITETURA DE PASTAS
==================================================

Organize o projeto de maneira profissional.

Sugestão:

lib/
core/
theme/
routing/
constants/
utils/
widgets/

features/
home/
workouts/
workout_session/
exercises/
progress/
history/
guide/
profile/

data/
models/
repositories/
local/

main.dart

Adapte se houver uma estrutura melhor, mas mantenha separação clara de responsabilidades.

================================================== 27. TEMA
==================================================

Criar um ThemeData centralizado.

Exemplo conceitual:

primaryColor: roxo
background: preto/cinza muito escuro
surface: cinza escuro
textPrimary: branco
textSecondary: cinza claro
accent: roxo

Não espalhar valores de cor pelo projeto.

Criar constantes para:

- cores
- espaçamentos
- bordas
- tamanhos
- duração das animações

================================================== 28. COMPONENTES REUTILIZÁVEIS
==================================================

Criar componentes como:

- WorkoutCard
- ExerciseCard
- SetCard
- WeightInput
- RepsInput
- RirSelector
- RestTimer
- ProgressCard
- SectionHeader
- PrimaryButton
- SecondaryButton
- EmptyState
- ProgressChart

Evitar duplicação de código.

================================================== 29. PRIMEIRO LANÇAMENTO
==================================================

Nesta primeira versão NÃO implementar:

- login
- pagamento
- assinatura
- backend
- rede social
- chat
- integração com smartwatch

Concentre-se em:

1. Treinos
2. Execução
3. Registro de séries
4. Histórico
5. Progressão
6. Exercícios
7. Conteúdo educativo
8. Persistência local

================================================== 30. IMPORTANTE SOBRE O PDF
==================================================

O PDF é a fonte de verdade para o protocolo.

Ele contém:

- divisão semanal
- exercícios
- séries
- repetições
- recomendações de execução
- progressão de cargas
- tensão mecânica
- descanso
- RIR
- cadência
- sono
- suplementação
- equipamentos

Não invente informações que não estejam disponíveis.

Quando existir uma informação ambígua no PDF, preserve a ambiguidade no aplicativo.

Exemplo:

"Smith ou Halteres"

não deve ser transformado em apenas "Smith".

Da mesma forma:

"Paralela ou Cross Over Polia Alta"

deve permanecer como opção.

================================================== 31. DESENVOLVIMENTO
==================================================

Antes de implementar:

1. Inspecione a estrutura atual do projeto.
2. Analise o pubspec.yaml.
3. Verifique quais dependências já existem.
4. Analise o PDF.
5. Crie um plano de implementação.
6. Identifique o que já existe e o que precisa ser criado.

Depois:

1. Configure a arquitetura.
2. Configure o tema.
3. Crie os modelos.
4. Cadastre os dados dos treinos.
5. Crie persistência local.
6. Crie navegação.
7. Desenvolva as telas.
8. Desenvolva a execução do treino.
9. Desenvolva histórico.
10. Desenvolva progresso.
11. Desenvolva guia.
12. Execute testes/análise.
13. Corrija erros.
14. Rode flutter analyze.
15. Rode testes disponíveis.

================================================== 32. REGRAS IMPORTANTES PARA O CURSOR
==================================================

Não faça uma implementação gigante e desorganizada em um único arquivo.

Não coloque toda a lógica no main.dart.

Não use valores mágicos espalhados pelo código.

Não duplique widgets.

Não invente dados.

Não remova funcionalidades existentes sem verificar primeiro.

Não altere dependências sem necessidade.

Sempre priorize código simples, legível e sustentável.

Quando precisar tomar uma decisão de arquitetura, escolha a alternativa mais simples que permita crescimento futuro.

Depois de cada etapa importante, valide o projeto.

Se houver erro de compilação, corrija antes de continuar.

================================================== 33. RESULTADO ESPERADO
==================================================

Quero terminar com um aplicativo Flutter funcional de acompanhamento de musculação baseado no protocolo "Massive Arms and Shoulders".

O usuário deve conseguir:

- abrir o aplicativo
- visualizar o treino do dia
- escolher qualquer dia da semana
- visualizar os exercícios
- iniciar o treino
- registrar séries
- informar carga
- informar repetições
- informar RIR
- visualizar carga/repetições anteriores
- controlar descanso
- finalizar o treino
- consultar histórico
- visualizar progresso
- consultar exercícios
- acessar os ensinamentos do protocolo

A experiência deve parecer um aplicativo fitness profissional, e não um PDF convertido para aplicativo.

COMECE AGORA.

Primeiro analise o projeto existente e o PDF.

Depois me apresente um plano curto de implementação.

Em seguida, implemente a primeira etapa sem esperar uma nova confirmação.
