import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/fun_copy.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sync_status_card.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/services/custom_workout_week.dart';
import '../../data/services/history_grouping.dart';
import '../../data/services/workout_streak.dart';
import '../history/history_day_card.dart';
import '../spotify/spotify_now_playing_banner.dart';
import '../workouts/training_split_selector.dart';

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
    final finished = repo.getFinishedSessions();
    final last = repo.getLastFinishedSession();
    final yesterdayDays = HistoryGrouping.daysOn(
      finished,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final lastDay = last == null
        ? null
        : HistoryGrouping.findById(
            finished,
            HistoryGrouping.dayKey(last.startedAt, last.workoutPlanId),
          );
    final lastIsYesterday =
        lastDay != null && yesterdayDays.any((day) => day.id == lastDay.id);
    final active = repo.getActiveSession();
    final greeting = greetingForNow();
    final plans = ref.watch(allPlansProvider);
    final customPending =
        prefs.trainingSplit == TrainingSplit.custom &&
        !CustomWorkoutWeek.hasTrainingDay(prefs.customPlans);
    final streak = WorkoutStreak.current(
      repo.getFinishedSessions(),
      dayOffWeekdays: plans
          .where((plan) => plan.isDayOff)
          .map((plan) => plan.weekday)
          .toSet(),
    );
    final streakLabel = FunCopy.streakLabel(streak);

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
              FunCopy.tagline(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryLight),
            ),
            if (streakLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _StreakChip(label: streakLabel),
            ],
            const SizedBox(height: AppSpacing.md),
            const SpotifyNowPlayingBanner(),
            const SyncStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: 'Treino de hoje'),
            const SizedBox(height: AppSpacing.md),
            TrainingSplitSelector(allowEdit: customPending),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              highlighted: customPending || !today.isDayOff,
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
                    customPending
                        ? 'SUA LISTA'
                        : (today.isDayOff
                              ? 'DAY OFF'
                              : today.name.toUpperCase()),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (customPending) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Crie os treinos da semana para ver o de hoje aqui. '
                      'Dá para nomear cada dia, escolher os exercícios e marcar folga.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else if (!today.isDayOff) ...[
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
                      label:
                          active != null &&
                              active.workoutPlanId == today.id &&
                              !active.isFinished
                          ? 'Continuar treino'
                          : 'Bora treinar',
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
                      prefs.trainingSplit == TrainingSplit.custom
                          ? 'Folga na sua lista. O treino volta no próximo dia que você marcou.'
                          : FunCopy.dayOffNote(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (yesterdayDays.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Treino de ontem',
                actionLabel: 'Histórico',
                onAction: () => context.push('/history'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < yesterdayDays.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                HistoryDayCard(
                  day: yesterdayDays[i],
                  highlighted: true,
                  showShareIcon: false,
                  shareButtonLabel: 'Compartilhar',
                  shareHeadline: 'Treino de ontem',
                ),
              ],
            ],
            if (last == null || lastDay == null) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Seu último treino',
                actionLabel: yesterdayDays.isEmpty ? 'Histórico' : null,
                onAction: yesterdayDays.isEmpty
                    ? () => context.push('/history')
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: EmptyState(
                  title: FunCopy.firstWorkoutTitle,
                  subtitle: FunCopy.firstWorkoutSubtitle,
                  icon: Icons.rocket_launch_outlined,
                  actionLabel: customPending
                      ? 'Criar lista de treinos'
                      : (today.isDayOff ? null : 'Bora pro primeiro treino'),
                  onAction: customPending
                      ? () => context.push('/custom-workouts')
                      : (today.isDayOff
                            ? null
                            : () => context.push('/session/${today.id}')),
                ),
              ),
            ] else if (!lastIsYesterday) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Seu último treino',
                actionLabel: yesterdayDays.isEmpty ? 'Histórico' : null,
                onAction: yesterdayDays.isEmpty
                    ? () => context.push('/history')
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              HistoryDayCard(day: lastDay),
            ],
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

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.prGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.prGold.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.prGold),
            ),
          ],
        ),
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
