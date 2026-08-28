import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/services/exercise_catalog.dart';
import '../../data/services/progress_analytics.dart';

final progressPeriodProvider =
    StateProvider<ProgressPeriod>((ref) => ProgressPeriod.days30);

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionsProvider);
    ref.watch(preferencesProvider);
    final repo = ref.watch(sessionRepositoryProvider);
    final sessions = repo.getFinishedSessions();
    final period = ref.watch(progressPeriodProvider);

    final dayCount =
        ProgressAnalytics.trainingDayCount(sessions, period: period);
    final volume = ProgressAnalytics.totalVolume(sessions, period: period);
    final best = ProgressAnalytics.bestMarks(sessions, period: period);
    final weekly = ProgressAnalytics.weeklyVolume(sessions);
    final tips = ProgressAnalytics.progressionTips(sessions);
    final withHistory = ExerciseCatalog.all.where((e) {
      return ProgressAnalytics.workingPoints(
        sessions,
        exerciseId: e.id,
        period: period,
      ).isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? EmptyState(
              title: 'Sem dados de progresso ainda',
              subtitle:
                  'Complete treinos para ver volume, melhores marcas e sugestões.',
              icon: Icons.show_chart,
              actionLabel: 'Ir para treinos',
              onAction: () => context.go('/workouts'),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Período',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: ProgressPeriod.values.map((p) {
                    final selected = period == p;
                    return ChoiceChip(
                      label: Text(p.label),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(progressPeriodProvider.notifier).state = p,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Dias de treino',
                        value: '$dayCount',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _Metric(
                        label: 'Volume',
                        value: '${volume.round()}',
                        suffix: 'kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Volume semanal'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: SizedBox(
                    height: 160,
                    child: _WeeklyVolumeChart(buckets: weekly),
                  ),
                ),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Sugestões de progressão'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Baseado no protocolo: mais reps com o mesmo peso, depois aumentar carga. '
                    'Não altera séries automaticamente.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...tips.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        highlighted: t.message.contains('aumento') ||
                            t.message.contains('Topo'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.exerciseName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              t.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.primaryLight),
                            ),
                            if (t.detail != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                t.detail!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (best.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Melhores marcas'),
                  const SizedBox(height: AppSpacing.md),
                  ...best.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.exerciseName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${formatWeight(m.weight)} × ${m.reps}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Evolução por exercício'),
                const SizedBox(height: AppSpacing.md),
                if (withHistory.isEmpty)
                  const AppCard(
                    child: Text(
                      'Sem séries valendo neste período.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...withHistory.map((exercise) {
                    final history = ProgressAnalytics.workingPoints(
                      sessions,
                      exerciseId: exercise.id,
                      period: period,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: ProgressChartCard(
                        title: exercise.name,
                        history: history
                            .map(
                              (s) => (
                                weight: s.weight,
                                reps: s.reps,
                                at: s.at,
                              ),
                            )
                            .toList(),
                        tip: tips
                            .where((t) => t.exerciseId == exercise.id)
                            .map((t) => t.message)
                            .firstOrNull,
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(suffix!,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyVolumeChart extends StatelessWidget {
  const _WeeklyVolumeChart({required this.buckets});

  final List<WeeklyVolumeBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxY = buckets.fold<double>(0, (m, b) => b.volume > m ? b.volume : m);
    if (maxY <= 0) {
      return const Center(
        child: Text(
          'Sem volume registrado ainda.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) {
                  return const SizedBox.shrink();
                }
                final label =
                    DateFormat('dd/MM').format(buckets[i].weekStart);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].volume,
                  color: AppColors.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({
    super.key,
    required this.title,
    required this.history,
    this.tip,
  });

  final String title;
  final List<({double weight, int reps, DateTime at})> history;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].weight));
    }

    final last = history.last;
    final first = history.first;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatWeight(first.weight)} × ${first.reps}  →  ${formatWeight(last.weight)} × ${last.reps}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryLight,
                ),
          ),
          if (tip != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              tip!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 140,
            child: spots.length < 2
                ? Center(
                    child: Text(
                      '${formatWeight(last.weight)} × ${last.reps} reps',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...history.reversed.take(5).map((h) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${DateFormat('dd/MM').format(h.at)} · ${formatWeight(h.weight)} × ${h.reps} reps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }),
        ],
      ),
    );
  }
}
