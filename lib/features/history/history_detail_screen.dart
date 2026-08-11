import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionRepositoryProvider).getById(sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const EmptyState(title: 'Sessão não encontrada'),
      );
    }

    final plan = ProtocolData.planById(session.workoutPlanId);
    final date = DateFormat("dd/MM/yyyy 'às' HH:mm").format(session.startedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(plan?.name ?? 'Treino'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(date, style: Theme.of(context).textTheme.bodyMedium),
          if (session.duration != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Duração: ${formatDuration(session.duration!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ...session.exercises.map((ex) {
            final exercise = ProtocolData.exerciseById(ex.exerciseId);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise?.name ?? ex.exerciseId,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...ex.sets.map((set) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            SetTypeBadge(type: set.setType),
                            const SizedBox(width: AppSpacing.sm),
                            Text('S${set.setNumber}'),
                            const Spacer(),
                            Text(
                              set.completed
                                  ? '${formatWeight(set.weight)} × ${set.repetitions ?? '—'}'
                                      '${set.rir != null ? ' · RIR ${set.rir}' : ''}'
                                  : 'Não concluída',
                              style: TextStyle(
                                color: set.completed
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
