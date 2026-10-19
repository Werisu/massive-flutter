import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
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
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TrainingSplit>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 4),
              ),
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            segments: const [
              ButtonSegment(
                value: TrainingSplit.protocol,
                label: Text(
                  'Protocolo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: TrainingSplit.fullBody,
                label: Text(
                  'Full body',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: TrainingSplit.custom,
                label: Text(
                  'Meus treinos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {split},
            onSelectionChanged: (next) async {
              final selected = next.first;
              final openEditor =
                  selected == TrainingSplit.custom &&
                  !CustomWorkoutWeek.hasTrainingDay(
                    ref.read(preferencesProvider).customPlans,
                  );
              await ref
                  .read(preferencesProvider.notifier)
                  .setTrainingSplit(selected);
              if (openEditor && context.mounted) {
                context.push('/custom-workouts');
              }
            },
          ),
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
      case TrainingSplit.custom:
        return 'Sua lista. Crie um treino para cada dia da semana, '
            'com os exercícios e as séries que você quiser.';
    }
  }
}
