import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionsProvider);
    final repo = ref.watch(sessionRepositoryProvider);
    final finished = repo.getFinishedSessions();

    // Pick exercises with history for charts
    final withHistory = ProtocolData.exercises.where((e) {
      return repo.getExerciseWorkingHistory(e.id).isNotEmpty;
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
      body: finished.isEmpty
          ? EmptyState(
              title: 'Ainda não há treinos registrados.',
              subtitle: 'Complete um treino para ver sua evolução.',
              actionLabel: 'Ir para treinos',
              onAction: () => context.go('/workouts'),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Treinos',
                        value: '${repo.completedWorkoutCount}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _Metric(
                        label: 'Volume total',
                        value: '${repo.totalVolume.round()}',
                        suffix: 'kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Metric(
                  label: 'Frequência (últimos 7 dias)',
                  value: '${_frequencyLast7(finished)}',
                  suffix: 'treinos',
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Evolução por exercício'),
                const SizedBox(height: AppSpacing.md),
                if (withHistory.isEmpty)
                  const AppCard(
                    child: Text(
                      'Sem séries valendo registradas ainda.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...withHistory.map((exercise) {
                    final history =
                        repo.getExerciseWorkingHistory(exercise.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: ProgressChartCard(
                        title: exercise.name,
                        history: history
                            .map((s) => (
                                  weight: s.weight ?? 0,
                                  reps: s.repetitions ?? 0,
                                ))
                            .toList(),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  int _frequencyLast7(List<dynamic> finished) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return finished.where((s) => s.startedAt.isAfter(cutoff)).length;
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

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({
    super.key,
    required this.title,
    required this.history,
  });

  final String title;
  final List<({double weight, int reps})> history;

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
                '${formatWeight(h.weight)} × ${h.reps} reps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }),
        ],
      ),
    );
  }
}
