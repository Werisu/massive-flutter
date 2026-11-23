import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/services/custom_workout_week.dart';

class TrainingSplitSelector extends ConsumerWidget {
  const TrainingSplitSelector({super.key, this.allowEdit = true});

  /// Mostra o botão de criar ou editar a lista quando a divisão é personalizada.
  final bool allowEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final split = prefs.trainingSplit;
    final ready = CustomWorkoutWeek.hasTrainingDay(prefs.customPlans);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in TrainingSplit.values)
              _SplitChip(
                label: option.labelPt,
                selected: split == option,
                onTap: () async {
                  final openEditor =
                      option == TrainingSplit.custom &&
                      !CustomWorkoutWeek.hasTrainingDay(
                        ref.read(preferencesProvider).customPlans,
                      );
                  await ref
                      .read(preferencesProvider.notifier)
                      .setTrainingSplit(option);
                  if (openEditor && context.mounted) {
                    context.push('/custom-workouts');
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(_hint(split), style: Theme.of(context).textTheme.bodySmall),
        if (allowEdit && split == TrainingSplit.custom) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: ready ? 'Editar lista' : 'Criar lista de treinos',
            icon: ready ? Icons.edit_outlined : Icons.playlist_add,
            onPressed: () => context.push('/custom-workouts'),
          ),
        ],
      ],
    );
  }

  String _hint(TrainingSplit split) {
    switch (split) {
      case TrainingSplit.protocol:
        return 'Divisão do protocolo: braços, ombros, costas, peito '
            'e um dia de inferiores.';
      case TrainingSplit.fullBody:
        return 'Segunda, quarta e sexta. O mesmo treino nos três dias; '
            'os outros ficam de recuperação.';
      case TrainingSplit.differentiated:
        return 'Segunda upper, terça lower, quarta braços, quinta descanso '
            'ativo e sexta push/pull. Cada exercício tem aquecimento, '
            'preparação e séries valendo.';
      case TrainingSplit.threeSeven:
        return 'Segunda peito e costas, terça pernas, quinta ombros e costas, '
            'sexta braços. Cada exercício é um bloco 3/7: 3, 4, 5, 6 e 7 reps '
            'na mesma carga, com 15 segundos entre as mini-séries.';
      case TrainingSplit.custom:
        return 'Sua lista. Crie um treino para cada dia da semana, '
            'com os exercícios e as séries que você quiser.';
    }
  }
}

class _SplitChip extends StatelessWidget {
  const _SplitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
