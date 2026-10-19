import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/fun_copy.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/services/history_grouping.dart';
import 'history_day_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionsProvider);
    ref.watch(preferencesProvider);
    final sessions = ref.watch(sessionRepositoryProvider).getFinishedSessions();
    final days = HistoryGrouping.groupFinishedSessions(sessions);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: days.isEmpty
          ? EmptyState(
              title: FunCopy.emptyHistoryTitle,
              subtitle: FunCopy.emptyHistorySubtitle,
              icon: Icons.history_toggle_off,
              actionLabel: 'Ver treinos',
              onAction: () => context.go('/workouts'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final day = days[index];
                return HistoryDayCard(
                  day: day,
                  highlighted: isSameCalendarDay(day.date, yesterday),
                  showSetHighlight: false,
                  shareHeadline: relativeHistoryWord(day.date) == 'Ontem'
                      ? 'Treino de ontem'
                      : 'Compartilhar treino',
                );
              },
            ),
    );
  }
}
