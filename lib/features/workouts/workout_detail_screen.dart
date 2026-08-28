import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/services/exercise_catalog.dart';
import '../workout_session/exercise_substitute_sheet.dart';

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

    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${plan.weekday.labelPt} — ${plan.name}'),
      ),
      body: plan.isDayOff
          ? const EmptyState(
              title: 'DAY OFF',
              subtitle:
                  'Dia de recuperação conforme o protocolo. Sono, comida e descanso fazem o músculo crescer.',
              icon: Icons.hotel_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  '${plan.exerciseCount} exercícios · séries do protocolo. Use a troca se o equipamento não estiver disponível.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...plan.exercises.map((we) {
                  final replacementId = prefs.exerciseSubstitutions[we.id];
                  final displayId = replacementId ?? we.exerciseId;
                  final exercise = ExerciseCatalog.byId(displayId);
                  final original = replacementId == null
                      ? null
                      : ExerciseCatalog.byId(we.exerciseId);
                  final warmup = we.sets.where((s) => s.type == SetType.warmup).length;
                  final prep = we.sets.where((s) => s.type == SetType.preparation).length;
                  final working = we.sets.where((s) => s.type == SetType.working).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
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
                                child: InkWell(
                                  onTap: () =>
                                      context.push('/exercise/$displayId'),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise?.name ?? displayId,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      if (original != null)
                                        Text(
                                          'No lugar de ${original.name}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Substituir exercício',
                                onPressed: () async {
                                  final pick = await showExerciseSubstituteSheet(
                                    context: context,
                                    protocolExerciseId: we.exerciseId,
                                    currentExerciseId: displayId,
                                    persistByDefault: true,
                                    showPersistToggle: false,
                                  );
                                  if (pick == null) return;
                                  await ref
                                      .read(preferencesProvider.notifier)
                                      .setExerciseSubstitution(
                                        workoutExerciseId: we.id,
                                        replacementExerciseId:
                                            pick.exerciseId == we.exerciseId
                                                ? null
                                                : pick.exerciseId,
                                      );
                                },
                                icon: const Icon(Icons.swap_horiz),
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
