import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import 'guide_content.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  IconData _iconFor(String key) {
    switch (key) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'trending_up':
        return Icons.trending_up;
      case 'bolt':
        return Icons.bolt;
      case 'timer':
        return Icons.timer_outlined;
      case 'tune':
        return Icons.tune;
      case 'sports':
        return Icons.sports;
      case 'speed':
        return Icons.speed;
      case 'bedtime':
        return Icons.bedtime_outlined;
      case 'science':
        return Icons.science_outlined;
      case 'handshake':
        return Icons.handshake_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guia do protocolo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            highlighted: true,
            child: Text(
              GuideContent.disclaimer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Conheça o protocolo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...GuideContent.topics.map((topic) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                onTap: () => context.push('/guide/${topic.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        _iconFor(topic.icon),
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        topic.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
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
