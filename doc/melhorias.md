# Melhorias recomendadas — Massive Arms

Lista priorizada de melhorias para o app Flutter, com base no protocolo, na sincronização Firebase e na experiência de treino.

---

## 1. Experiência do treino (prioridade alta)

- [x] Pré-preencher carga/reps da **última série valendo** do mesmo exercício
- [x] Timer de descanso em **notificação** (continua se sair da tela)
- [x] “Desfazer série” e editar série já concluída
- [x] Agrupar o histórico por **dia de treino completo**, não só por sessão fragmentada do app antigo

---

## 2. Sincronização / conta

- [x] Tela clara de status: logado, último sync, quantos treinos importados
- [x] Sync automático ao abrir o app (quando já estiver logado)
- [x] Resolver conflito local vs nuvem (merge por progresso / data; não sobrescreve treino ativo)
- [x] Doc SHA-1 release Android (`doc/android-sha1.md`) — cadastrar fingerprints no Firebase

---

## 3. Progresso de verdade

- [x] Gráfico por exercício com filtro de período
- [x] “Melhor marca” (carga × reps) e volume semanal
- [x] Sugestão de progressão do protocolo (8→9→10→aumentar carga), sem mudar séries sozinho

---

## 4. Dados do protocolo

- [x] Biblioteca de exercícios com histórico no detalhe
- [x] Guia do PDF mais completo (divisão, tipos de série, registro)
- [x] URLs de vídeo quando existirem (sem inventar) — cadastro em `exercise_media.dart`

---

## 5. Qualidade / produto

- [x] Splash + empty states melhores
- [x] Testes de agrupamento / progressão / desfazer / sync legado
- [x] iOS preparado (`GoogleService-Info.plist` template + `doc/ios-firebase.md`) — falta registrar app no Console
- [x] Kotlin: DSL `compilerOptions` + `doc/android-kotlin.md` (built-in bloqueado por plugins Firebase)

---

## Ordem sugerida de implementação

1. ~~Sync automático + feedback claro do histórico importado~~ ✅
2. ~~Pré-preenchimento de carga/reps no treino~~ ✅
3. ~~Histórico unificado e progresso por exercício~~ ✅
4. ~~Desfazer/editar série + timer com notificação + merge seguro + splash~~ ✅
5. ~~Biblioteca de exercícios + guia + vídeos (arquitetura)~~ ✅
6. ~~iOS template + fixtures de sync + Kotlin built-in~~ ✅

### Pacotes implementados

**Pacote 1+2** — sync automático, pré-preenchimento, status  
**Pacote 3** — histórico agrupado + progresso  
**Pacote 4** — desfazer/editar, timer notificação, merge seguro, splash  
**Pacote 5** — biblioteca de exercícios + guia + vídeo (URL opcional)  

**Pacote 6**
1. `LegacyWorkoutMapper` + testes com `test/fixtures/legacy_workout_history.json`
2. iOS: plist template, URL scheme Google Sign-In, `doc/ios-firebase.md`
3. Android: DSL `kotlin.compilerOptions` + doc de migração built-in (`doc/android-kotlin.md`)

### Próximo pacote sugerido

1. Registrar app iOS no Firebase e trocar `GOOGLE_APP_ID` real
2. Ativar `android.builtInKotlin=true` quando plugins Firebase migrarem
3. Cadastrar URLs reais de vídeo quando disponíveis no PDF/projeto
4. (Opcional) player embutido de vídeo / `android.newDsl=true`
