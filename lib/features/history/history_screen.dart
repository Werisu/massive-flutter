import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionsProvider);
    final sessions =
        ref.watch(sessionRepositoryProvider).getFinishedSessions();

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: sessions.isEmpty
          ? EmptyState(
              title: 'Ainda não há treinos registrados.',
              actionLabel: 'Começar treino',
              onAction: () => context.go('/workouts'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sessions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final plan = ProtocolData.planById(session.workoutPlanId);
                final date =
                    DateFormat('dd/MM/yyyy').format(session.startedAt);
                final duration = session.duration;

                return AppCard(
                  onTap: () => context.push('/history/${session.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        plan == null
                            ? 'Treino'
                            : '${plan.weekday.labelPt} — ${plan.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${session.completedExercises}/${session.exercises.length} exercícios'
                        '${duration != null ? ' · ${formatDuration(duration)}' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
