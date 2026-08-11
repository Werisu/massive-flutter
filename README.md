# Massive Arms

Aplicativo Flutter de acompanhamento do protocolo **Massive Arms and Shoulders**.

## Funcionalidades

- Divisão semanal completa do protocolo
- Execução de treino com carga, reps e RIR
- Cronômetro de descanso
- Histórico e progresso offline (Hive)
- Biblioteca de exercícios
- Guia educacional do protocolo

## Como rodar

```bash
flutter pub get
flutter run
```

## Análise

```bash
flutter analyze
flutter test
```

## Arquitetura

```
lib/
  core/       # tema, routing, widgets, providers
  data/       # models, seed do protocolo, Hive, repositories
  features/   # home, workouts, session, exercises, progress, history, guide, profile
```

Offline-first. Pronto para evoluir com autenticação e sync remoto no futuro.
