import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';

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

    final plans = ProtocolData.plansContainingExercise(exerciseId);
    final repo = ref.watch(sessionRepositoryProvider);
    final history = repo.getExerciseWorkingHistory(exerciseId);
    final last = repo.getLastWorkingSet(exerciseId);

    // Find set prescription from first plan occurrence
    String? setsSummary;
    for (final plan in plans) {
      for (final we in plan.exercises) {
        if (we.exerciseId != exerciseId) continue;
        final warmup =
            we.sets.where((s) => s.type == SetType.warmup).length;
        final prep =
            we.sets.where((s) => s.type == SetType.preparation).length;
        final working =
            we.sets.where((s) => s.type == SetType.working).length;
        final parts = <String>[];
        if (warmup > 0) parts.add('Aquecimento ${warmup}x10');
        if (prep > 0) parts.add('Preparatórias ${prep}x2-7');
        if (working > 0) parts.add('Valendo ${working}x8-10');
        setsSummary = parts.join(' · ');
        break;
      }
      if (setsSummary != null) break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          MuscleGroupChip(group: exercise.muscleGroup),
          const SizedBox(height: AppSpacing.lg),
          if (setsSummary != null) ...[
            Text('Séries (protocolo)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Text(
                setsSummary,
                style: Theme.of(context).textTheme.bodyLarge,
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
                  (p) => Chip(
                    label: Text('${p.weekday.labelPt} — ${p.name}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Vídeo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Row(
              children: [
                Icon(
                  exercise.hasVideo
                      ? Icons.play_circle_fill
                      : Icons.videocam_off_outlined,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  exercise.hasVideo
                      ? 'Abrir vídeo'
                      : 'Vídeo indisponível',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Histórico', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (history.isEmpty)
            const AppCard(
              child: Text(
                'Ainda não há registros para este exercício.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else ...[
            if (last != null)
              AppCard(
                highlighted: true,
                child: Text(
                  'Último: ${formatWeight(last.weight)} × ${last.repetitions ?? '—'} reps',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            ...history.reversed.take(10).map((set) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '${formatWeight(set.weight)} × ${set.repetitions ?? '—'} reps'
                    '${set.rir != null ? ' · RIR ${set.rir}' : ''}'
                    '${set.completedAt != null ? ' · ${set.completedAt!.day.toString().padLeft(2, '0')}/${set.completedAt!.month.toString().padLeft(2, '0')}' : ''}',
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
