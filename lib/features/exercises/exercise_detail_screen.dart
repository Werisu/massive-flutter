import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/open_url.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/services/progress_analytics.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ProtocolData.exerciseById(exerciseId);
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercício')),
        body: const EmptyState(title: 'Exercício não encontrado'),
      );
    }

    ref.watch(sessionsProvider);
    final plans = ProtocolData.plansContainingExercise(exerciseId);
    final repo = ref.watch(sessionRepositoryProvider);
    final sessions = repo.getFinishedSessions();
    final dayLogs = repo.getExerciseDayHistory(exerciseId);
    final last = repo.getLastWorkingSet(exerciseId);
    final points = ProgressAnalytics.workingPoints(
      sessions,
      exerciseId: exerciseId,
    );
    final best = ProgressAnalytics.bestMarkForExercise(sessions, exerciseId);
    final tip = ProgressAnalytics.tipForExercise(sessions, exerciseId);
    final setsSummary = ProtocolData.setsSummary(exerciseId);
    final prescription = ProtocolData.firstPrescription(exerciseId);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              MuscleGroupChip(group: exercise.muscleGroup),
              const Spacer(),
              if (last != null)
                Text(
                  '${formatWeight(last.weight)} × ${last.repetitions ?? '—'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryLight,
                      ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (setsSummary != null) ...[
            Text('Protocolo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setsSummary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (prescription != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _SetTypeBadge(
                          label:
                              'Aquec. ${prescription.sets.where((s) => s.type == SetType.warmup).length}',
                          color: AppColors.textMuted,
                        ),
                        _SetTypeBadge(
                          label:
                              'Prep. ${prescription.sets.where((s) => s.type == SetType.preparation).length}',
                          color: AppColors.warning,
                        ),
                        _SetTypeBadge(
                          label:
                              'Valendo ${prescription.sets.where((s) => s.type == SetType.working).length}',
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Treinos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: plans
                .map(
                  (p) => ActionChip(
                    label: Text('${p.weekday.labelPt} — ${p.name}'),
                    onPressed: () => context.push('/workout/${p.id}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Vídeo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: exercise.hasVideo
                ? () => openExternalUrl(
                      exercise.videoUrl!,
                      context: context,
                      failureMessage: 'Não foi possível abrir o vídeo.',
                    )
                : null,
            child: Row(
              children: [
                Icon(
                  exercise.hasVideo
                      ? Icons.play_circle_fill
                      : Icons.videocam_off_outlined,
                  color: exercise.hasVideo
                      ? AppColors.primaryLight
                      : AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.hasVideo
                            ? 'Abrir vídeo de execução'
                            : 'Vídeo indisponível',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        exercise.hasVideo
                            ? 'Abre no navegador / app externo'
                            : 'URL ainda não cadastrada no protocolo',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (exercise.hasVideo)
                  const Icon(Icons.open_in_new, color: AppColors.textMuted),
              ],
            ),
          ),
          if (best != null || tip != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Marcas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (best != null)
              AppCard(
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Melhor marca',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatWeight(best.weight)} × ${best.reps} reps',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(best.at),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            if (tip != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                    if (tip.detail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tip.detail!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
          if (points.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Evolução', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _ExerciseChart(points: points),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Histórico', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (dayLogs.isEmpty)
            const AppCard(
              child: Text(
                'Ainda não há registros para este exercício. '
                'Complete séries valendo no treino para ver o histórico aqui.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...dayLogs.take(20).map((log) => _DayHistoryCard(log: log)),
        ],
      ),
    );
  }
}

class _SetTypeBadge extends StatelessWidget {
  const _SetTypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _ExerciseChart extends StatelessWidget {
  const _ExerciseChart({required this.points});

  final List<WorkingSetPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].weight));
    }
    final last = points.last;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carga nas séries valendo',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
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
        ],
      ),
    );
  }
}

class _DayHistoryCard extends StatelessWidget {
  const _DayHistoryCard({required this.log});

  final ExerciseDayLog log;

  @override
  Widget build(BuildContext context) {
    final plan = ProtocolData.planById(log.workoutPlanId);
    final date = DateFormat('dd/MM/yyyy').format(log.date);
    final title = plan == null
        ? date
        : '$date · ${plan.weekday.labelPt}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Vol. ${log.volume.round()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...log.sets.map((set) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Série ${set.setNumber}: ${formatWeight(set.weight)} × '
                  '${set.repetitions ?? '—'} reps'
                  '${set.rir != null ? ' · RIR ${set.rir}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
