import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/services/history_grouping.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionsProvider);
    final sessions =
        ref.watch(sessionRepositoryProvider).getFinishedSessions();
    final days = HistoryGrouping.groupFinishedSessions(sessions);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: days.isEmpty
          ? EmptyState(
              title: 'Seu histórico está vazio',
              subtitle:
                  'Finalize um treino ou entre com Google no Perfil para importar da nuvem.',
              icon: Icons.history_toggle_off,
              actionLabel: 'Ver treinos',
              onAction: () => context.go('/workouts'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: days.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final day = days[index];
                final date = DateFormat('dd/MM/yyyy').format(day.date);
                final duration = day.totalDuration;

                return AppCard(
                  onTap: () => context.push('/history/day/${day.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(date,
                              style: Theme.of(context).textTheme.bodySmall),
                          if (day.sessionCount > 1) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${day.sessionCount} registros unidos',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        day.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${day.completedExercises}/${day.exerciseCount} exercícios'
                        '${duration != null ? ' · ${formatDuration(duration)}' : ''}'
                        ' · ${day.volume.round()} kg vol.',
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
