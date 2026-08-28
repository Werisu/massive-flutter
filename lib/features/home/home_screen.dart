import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sync_status_card.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/services/exercise_catalog.dart';
import '../../data/services/history_grouping.dart';
import '../../data/services/workout_share_snapshot.dart';
import '../hiit/hiit_today_card.dart';
import '../share/workout_share_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncStatusProvider.notifier).autoSyncIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final today = ref.watch(todayPlanProvider);
    ref.watch(sessionsProvider);
    final repo = ref.watch(sessionRepositoryProvider);
    final last = repo.getLastFinishedSession();
    final active = repo.getActiveSession();
    final greeting = greetingForNow();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '$greeting, ${prefs.userName}',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Massive Arms and Shoulders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryLight,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SyncStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: 'Treino de hoje'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              highlighted: !today.isDayOff,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    today.weekday.labelUpper,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    today.isDayOff ? 'DAY OFF' : today.name.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (!today.isDayOff) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${today.exerciseCount} exercícios',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (active != null &&
                        active.workoutPlanId == today.id &&
                        !active.isFinished) ...[
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: active.progress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${(active.progress * 100).round()}% concluído',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: active != null &&
                              active.workoutPlanId == today.id &&
                              !active.isFinished
                          ? 'Continuar treino'
                          : 'Começar treino',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => context.push('/session/${today.id}'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      label: 'Ver detalhes',
                      onPressed: () => context.push('/workout/${today.id}'),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Dia de recuperação da musculação. O HIIT de qualidade da semana entra aqui — pernas frescas, melhor estímulo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const HiitTodayCard(),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Seu último treino',
              actionLabel: 'Histórico',
              onAction: () => context.push('/history'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (last == null)
              AppCard(
                child: EmptyState(
                  title: 'Pronto para o primeiro treino',
                  subtitle:
                      'Comece agora ou entre com Google no Perfil para trazer o histórico da nuvem.',
                  icon: Icons.rocket_launch_outlined,
                  actionLabel:
                      today.isDayOff ? null : 'Começar primeiro treino',
                  onAction: today.isDayOff
                      ? null
                      : () => context.push('/session/${today.id}'),
                ),
              )
            else
              _LastWorkoutCard(sessionId: last.id),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Resumo'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Treinos',
                    value: '${repo.completedWorkoutCount}',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatTile(
                    label: 'Volume',
                    value: '${repo.totalVolume.round()} kg',
                    icon: Icons.bar_chart_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Atalhos'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ShortcutTile(
                    label: 'Exercícios',
                    icon: Icons.fitness_center,
                    onTap: () => context.go('/exercises'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ShortcutTile(
                    label: 'Guia',
                    icon: Icons.menu_book_outlined,
                    onTap: () => context.push('/guide'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LastWorkoutCard extends ConsumerWidget {
  const _LastWorkoutCard({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(sessionRepositoryProvider);
    final session = repo.getById(sessionId);
    if (session == null) return const SizedBox.shrink();
    final dayId =
        HistoryGrouping.dayKey(session.startedAt, session.workoutPlanId);
    final day = HistoryGrouping.findById(repo.getFinishedSessions(), dayId);
    final plan = ProtocolData.planById(session.workoutPlanId);
    final date = DateFormat('dd/MM/yyyy').format(session.startedAt);

    SetRecord? highlight;
    final exercises = day?.exercises ?? session.exercises;
    for (final ex in exercises) {
      for (final set in ex.sets.reversed) {
        if (set.completed && set.weight != null) {
          highlight = set;
          break;
        }
      }
      if (highlight != null) break;
    }

    final exerciseName = highlight == null
        ? null
        : ExerciseCatalog.nameOf(highlight.exerciseId);

    return AppCard(
      onTap: () => context.push('/history/day/$dayId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(date, style: Theme.of(context).textTheme.bodySmall),
              ),
              if (day != null)
                IconButton(
                  tooltip: 'Compartilhar treino',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  onPressed: () {
                    showWorkoutShareSheet(
                      context,
                      WorkoutShareSnapshot.fromDay(
                        day: day,
                        allFinishedSessions: repo.getFinishedSessions(),
                        athleteName: ref.read(preferencesProvider).userName,
                        hiitCompleted: ref
                            .read(hiitCompletionProvider)
                            .completedOn(day.date),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan == null
                ? 'Treino'
                : '${plan.weekday.labelPt} — ${plan.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            day == null
                ? '${session.completedExercises}/${session.exercises.length} exercícios concluídos'
                : '${day.completedExercises}/${day.exerciseCount} exercícios'
                    '${day.sessionCount > 1 ? ' · ${day.sessionCount} registros unidos' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (highlight != null && exerciseName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exerciseName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${formatWeight(highlight.weight)} × ${highlight.repetitions ?? '—'} reps'
                    '${highlight.rir != null ? ' · RIR ${highlight.rir}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
