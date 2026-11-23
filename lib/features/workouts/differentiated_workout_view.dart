import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/workout_plan.dart';
import '../../data/seed/differentiated_data.dart';
import '../../data/services/exercise_catalog.dart';
import '../workout_session/exercise_substitute_sheet.dart';

/// Página da semana diferenciada: as três etapas ficam explícitas em cada exercício.
class DifferentiatedWorkoutView extends ConsumerWidget {
  const DifferentiatedWorkoutView({super.key, required this.plan});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Aquecimento, preparação e séries valendo. A carga da preparação '
          'sai da carga que você vai usar nas séries efetivas.',
          style: theme.textTheme.bodyMedium,
        ),
        if (plan.summary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(plan.summary!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _StageLegend(),
        const SizedBox(height: AppSpacing.lg),
        for (final slot in plan.exercises) ...[
          _ExerciseCard(slot: slot),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class DifferentiatedRecoveryView extends StatelessWidget {
  const DifferentiatedRecoveryView({super.key, required this.plan});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context) {
    final routine = DifferentiatedData.recoveryFor(plan.id);
    final theme = Theme.of(context);
    if (routine == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(routine.intro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        for (final block in routine.blocks) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(block.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  block.dose,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(block.detail, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StageLegend extends StatelessWidget {
  const _StageLegend();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        children: [
          _LegendRow(
            color: AppColors.warmup,
            title: 'Aquecimento',
            text: 'Lubrifica a articulação e ativa o músculo.',
          ),
          SizedBox(height: AppSpacing.sm),
          _LegendRow(
            color: AppColors.preparation,
            title: 'Preparação',
            text: 'Acelera o sistema nervoso, sem gerar fadiga.',
          ),
          SizedBox(height: AppSpacing.sm),
          _LegendRow(
            color: AppColors.working,
            title: 'Valendo',
            text: 'Séries efetivas, levadas ao limite técnico.',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.title,
    required this.text,
  });

  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title. ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: text),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.slot});

  final WorkoutExercise slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final replacementId = prefs.exerciseSubstitutions[slot.id];
    final displayId = replacementId ?? slot.exerciseId;
    final exercise = ExerciseCatalog.byId(displayId);
    final original = replacementId == null
        ? null
        : ExerciseCatalog.byId(slot.exerciseId);
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  '${slot.order}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/exercise/$displayId'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise?.name ?? displayId,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (slot.focus != null)
                        Text(slot.focus!, style: theme.textTheme.bodySmall),
                      if (original != null)
                        Text(
                          'No lugar de ${original.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
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
                    protocolExerciseId: slot.exerciseId,
                    currentExerciseId: displayId,
                    persistByDefault: true,
                    showPersistToggle: false,
                  );
                  if (pick == null) return;
                  await ref
                      .read(preferencesProvider.notifier)
                      .setExerciseSubstitution(
                        workoutExerciseId: slot.id,
                        replacementExerciseId:
                            pick.exerciseId == slot.exerciseId
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
          _StageLine(
            label: 'Aquecimento',
            color: AppColors.warmup,
            value: _stageDose(slot.sets, SetType.warmup),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StageLine(
            label: 'Preparação',
            color: AppColors.preparation,
            value: _stageDose(slot.sets, SetType.preparation),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StageLine(
            label: 'Valendo',
            color: AppColors.working,
            value: _stageDose(slot.sets, SetType.working),
          ),
          if (slot.restLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Descanso das séries valendo: ${slot.restLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _stageDose(List<SetPrescription> sets, SetType type) {
  final matched = sets.where((set) => set.type == type).toList();
  if (matched.isEmpty) return '';
  return '${matched.length}x ${matched.first.doseLabel}';
}
