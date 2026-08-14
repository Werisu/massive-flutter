import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/seed/hiit_data.dart';
import '../../data/seed/protocol_data.dart';
import '../hiit/hiit_today_card.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ProtocolData.planById(planId);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const EmptyState(title: 'Treino não encontrado'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${plan.weekday.labelPt} — ${plan.name}'),
      ),
      body: plan.isDayOff
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Recuperação da musculação conforme o protocolo. '
                  'O HIIT da semana entra neste dia, com as pernas frescas.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                HiitTodayCard(protocol: HiitData.forWeekday(plan.weekday)),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  '${plan.exerciseCount} exercícios · séries conforme protocolo',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...plan.exercises.map((we) {
                  final exercise = ProtocolData.exerciseById(we.exerciseId);
                  final warmup = we.sets.where((s) => s.type == SetType.warmup).length;
                  final prep = we.sets.where((s) => s.type == SetType.preparation).length;
                  final working = we.sets.where((s) => s.type == SetType.working).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      onTap: () =>
                          context.push('/exercise/${we.exerciseId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${we.order}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  exercise?.name ?? we.exerciseId,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          if (exercise != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            MuscleGroupChip(group: exercise.muscleGroup),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (warmup > 0)
                                _SetSummary(
                                  label: 'Aquecimento',
                                  value: '${warmup}x10',
                                ),
                              if (prep > 0)
                                _SetSummary(
                                  label: 'Preparatórias',
                                  value: '${prep}x2-7',
                                ),
                              if (working > 0)
                                _SetSummary(
                                  label: 'Valendo',
                                  value: '${working}x8-10',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Depois da musculação',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                HiitTodayCard(protocol: HiitData.forWeekday(plan.weekday)),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
      bottomNavigationBar: plan.isDayOff
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: 'Começar treino',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.push('/session/${plan.id}'),
                ),
              ),
            ),
    );
  }
}

class _SetSummary extends StatelessWidget {
  const _SetSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
