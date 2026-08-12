# Melhorias recomendadas — Massive Arms

Lista priorizada de melhorias para o app Flutter, com base no protocolo, na sincronização Firebase e na experiência de treino.

---

## 1. Experiência do treino (prioridade alta)

- [x] Pré-preencher carga/reps da **última série valendo** do mesmo exercício
- Timer de descanso em **notificação** (continua se sair da tela)
- “Desfazer série” e editar série já concluída
- [x] Agrupar o histórico por **dia de treino completo**, não só por sessão fragmentada do app antigo

---

## 2. Sincronização / conta

- [x] Tela clara de status: logado, último sync, quantos treinos importados
- [x] Sync automático ao abrir o app (quando já estiver logado)
- Resolver conflito local vs nuvem (hoje o merge é simples)
- Login Google estável no Android (SHA-1 do keystore de release)

---

## 3. Progresso de verdade

- [x] Gráfico por exercício com filtro de período
- [x] “Melhor marca” (carga × reps) e volume semanal
- [x] Sugestão de progressão do protocolo (8→9→10→aumentar carga), sem mudar séries sozinho

---

## 4. Dados do protocolo

- Biblioteca de exercícios com histórico no detalhe
- Guia do PDF mais completo (se o PDF estiver no projeto)
- URLs de vídeo quando existirem (sem inventar)

---

## 5. Qualidade / produto

- Splash + empty states melhores
- Testes de sync e de mapeamento do histórico legado
- iOS (`GoogleService-Info.plist`) se for lançar também no iPhone
- Migrar Kotlin “built-in” (Flutter já avisou no build Android)

---

## Ordem sugerida de implementação

1. ~~Sync automático + feedback claro do histórico importado~~ ✅
2. ~~Pré-preenchimento de carga/reps no treino~~ ✅
3. ~~Histórico unificado e progresso por exercício~~ ✅

### Pacotes implementados

**Pacote 1+2**
1. Sync automático ao abrir (se logado; re-sync a cada 15 min se stale)
2. Pré-preenchimento de carga/reps/RIR
3. Status de sync na Home/Perfil

**Pacote 3**
1. Histórico agrupado por dia + plano (`N registros unidos`)
2. Progresso com filtro 7/30/90/tudo, volume semanal, melhores marcas
3. Sugestões de progressão do protocolo (orientação, sem alterar séries)

### Próximo pacote sugerido

1. Desfazer/editar série + timer de descanso em notificação
2. Conflito local vs nuvem + SHA-1 release Android
3. Splash/empty states, testes extras, iOS
