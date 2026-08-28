import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/services/exercise_catalog.dart';
import '../../data/services/history_grouping.dart';
import '../../data/services/workout_share_snapshot.dart';
import '../share/workout_share_sheet.dart';

class HistoryDayDetailScreen extends ConsumerWidget {
  const HistoryDayDetailScreen({super.key, required this.dayId});

  final String dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionsProvider);
    ref.watch(preferencesProvider);
    ref.watch(hiitCompletionProvider);
    final sessions =
        ref.watch(sessionRepositoryProvider).getFinishedSessions();
    final day = HistoryGrouping.findById(sessions, dayId);

    if (day == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const EmptyState(title: 'Dia de treino não encontrado'),
      );
    }

    final plan = ProtocolData.planById(day.workoutPlanId);
    final dateLabel = plan != null
        ? '${plan.weekday.labelPt}, ${DateFormat('dd/MM/yyyy').format(day.date)}'
        : DateFormat('dd/MM/yyyy').format(day.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(day.title),
        actions: [
          IconButton(
            tooltip: 'Compartilhar treino',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              final snapshot = WorkoutShareSnapshot.fromDay(
                day: day,
                allFinishedSessions: sessions,
                athleteName: ref.read(preferencesProvider).userName,
                hiitCompleted:
                    ref.read(hiitCompletionProvider).completedOn(day.date),
              );
              showWorkoutShareSheet(context, snapshot);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (day.totalDuration != null)
                'Duração: ${formatDuration(day.totalDuration!)}',
              'Volume: ${day.volume.round()} kg',
              if (day.sessionCount > 1)
                '${day.sessionCount} registros unidos neste dia',
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...day.exercises.map((ex) {
            final exercise = ExerciseCatalog.byId(ex.exerciseId);
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
                    if (ex.isSubstituted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'No lugar de ${ExerciseCatalog.nameOf(ex.originalExerciseId!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

/// Compat: `/history/:sessionId` abre o dia unificado da sessão.
class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(sessionRepositoryProvider).getFinishedSessions();
    final asDay = HistoryGrouping.findById(sessions, sessionId);
    if (asDay != null) {
      return HistoryDayDetailScreen(dayId: sessionId);
    }

    final session = ref.watch(sessionRepositoryProvider).getById(sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const EmptyState(title: 'Sessão não encontrada'),
      );
    }

    final dayId =
        HistoryGrouping.dayKey(session.startedAt, session.workoutPlanId);
    return HistoryDayDetailScreen(dayId: dayId);
  }
}
