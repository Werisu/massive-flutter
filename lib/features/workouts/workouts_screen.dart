import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/workout_plan.dart';
import '../../data/seed/hiit_data.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(allPlansProvider);
    final today = Weekday.fromDateTime(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return WorkoutCard(
            plan: plan,
            isToday: plan.weekday == today,
            onTap: () => context.push('/workout/${plan.id}'),
          );
        },
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isToday = false,
  });

  final WorkoutPlan plan;
  final VoidCallback onTap;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlighted: isToday,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: plan.isDayOff
                  ? AppColors.dayOff
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              plan.weekday.labelPt.substring(0, 3).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: plan.isDayOff
                    ? AppColors.textMuted
                    : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.weekday.labelUpper,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.isDayOff ? 'DAY OFF' : plan.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!plan.isDayOff)
                  Text(
                    '${plan.exerciseCount} exercícios',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Text(
                    HiitData.forWeekday(plan.weekday).shortLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Text(
                'HOJE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
