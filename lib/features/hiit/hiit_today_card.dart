import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/hiit_protocol.dart';
import '../../data/seed/hiit_data.dart';

class HiitTodayCard extends ConsumerWidget {
  const HiitTodayCard({super.key, this.protocol});

  /// Se omitido, usa a prescrição do dia.
  final HiitProtocol? protocol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescribed = protocol ?? ref.watch(todayHiitProvider);
    if (prescribed == null) {
      return const SizedBox.shrink();
    }
    final doneToday =
        ref.watch(hiitCompletionProvider).completedOn(DateTime.now());
    final afterLifting = !ref.watch(todayPlanProvider).isDayOff &&
        prescribed.mode != HiitMode.hiitQuality;

    return AppCard(
      highlighted: prescribed.mode == HiitMode.hiitQuality ||
          prescribed.mode == HiitMode.hiitShort,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconFor(prescribed.mode),
                color: AppColors.primaryLight,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  prescribed.isOptional
                      ? 'CARDIO OPCIONAL'
                      : afterLifting
                          ? 'DEPOIS DA MUSCULAÇÃO'
                          : 'CARDIO DE HOJE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              if (doneToday)
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            prescribed.name.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${prescribed.totalMinutes} min'
            '${prescribed.workRounds > 0 ? ' · ${prescribed.workRounds} tiros de 30 s' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            prescribed.rationale,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (doneToday)
            Text(
              'Concluído hoje',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                  ),
            )
          else
            PrimaryButton(
              label: prescribed.isOptional
                  ? 'Começar (opcional)'
                  : 'Começar ${prescribed.shortLabel.toLowerCase()}',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push('/hiit/${prescribed.id}'),
            ),
          if (!doneToday && prescribed.allowsBriskFallback) ...[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Pernas pesadas? Caminhada rápida',
              icon: Icons.directions_walk,
              onPressed: () =>
                  context.push('/hiit/${HiitData.briskWalkId}'),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(HiitMode mode) {
    switch (mode) {
      case HiitMode.hiitQuality:
      case HiitMode.hiitShort:
        return Icons.speed;
      case HiitMode.briskWalk:
      case HiitMode.easyWalk:
        return Icons.directions_walk;
    }
  }
}
