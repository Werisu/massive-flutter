import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/services/exercise_catalog.dart';
import '../../data/services/history_grouping.dart';
import '../../data/services/workout_share_snapshot.dart';
import '../share/workout_share_sheet.dart';

class HistoryDayCard extends ConsumerWidget {
  const HistoryDayCard({
    super.key,
    required this.day,
    this.highlighted = false,
    this.showShareIcon = true,
    this.showSetHighlight = true,
    this.shareButtonLabel,
    this.shareHeadline,
  });

  final WorkoutDaySummary day;
  final bool highlighted;
  final bool showShareIcon;
  final bool showSetHighlight;
  final String? shareButtonLabel;
  final String? shareHeadline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = formatHistoryDateLabel(day.date);
    final duration = day.totalDuration;
    SetRecord? highlight;
    if (showSetHighlight) {
      for (final ex in day.exercises) {
        for (final set in ex.sets.reversed) {
          if (set.completed && set.weight != null) {
            highlight = set;
            break;
          }
        }
        if (highlight != null) break;
      }
    }
    final exerciseName =
        highlight == null ? null : ExerciseCatalog.nameOf(highlight.exerciseId);

    return AppCard(
      highlighted: highlighted,
      onTap: () => context.push('/history/day/${day.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
                    if (day.sessionCount > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
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
                ),
              ),
              if (showShareIcon)
                IconButton(
                  tooltip: 'Compartilhar treino',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  onPressed: () => _share(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(day.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${day.completedExercises}/${day.exerciseCount} exercícios'
            '${duration != null ? ' · ${formatDuration(duration)}' : ''}'
            ' · ${day.volume.round()} kg vol.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (highlight != null && exerciseName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${formatWeight(highlight.weight)} × ${highlight.repetitions ?? '—'} reps'
                    '${highlight.rir != null ? ' · RIR ${highlight.rir}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ],
          if (shareButtonLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: shareButtonLabel!,
              icon: Icons.ios_share_rounded,
              onPressed: () => _share(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _share(BuildContext context, WidgetRef ref) {
    final sessions = ref.read(sessionRepositoryProvider).getFinishedSessions();
    showWorkoutShareSheet(
      context,
      WorkoutShareSnapshot.fromDay(
        day: day,
        allFinishedSessions: sessions,
        athleteName: ref.read(preferencesProvider).userName,
        hiitCompleted: ref.read(hiitCompletionProvider).completedOn(day.date),
      ),
      headline: shareHeadline ?? 'Compartilhar treino',
    );
  }
}
