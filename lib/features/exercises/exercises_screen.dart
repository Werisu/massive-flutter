import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/seed/protocol_data.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _search = TextEditingController();
  MuscleGroup? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allExercisesProvider);
    final query = _search.text.trim().toLowerCase();

    final filtered = all.where((e) {
      final matchQuery =
          query.isEmpty || e.name.toLowerCase().contains(query);
      final matchGroup = _filter == null || e.muscleGroup == _filter;
      return matchQuery && matchGroup;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Pesquisar por nome',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                ...MuscleGroup.values.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: MuscleGroupChip(
                      group: g,
                      selected: _filter == g,
                      onTap: () => setState(() {
                        _filter = _filter == g ? null : g;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'Nenhum exercício encontrado',
                    icon: Icons.search_off,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ExerciseCard(
                        exercise: exercise,
                        onTap: () =>
                            context.push('/exercise/${exercise.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plans = ProtocolData.plansContainingExercise(exercise.id);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              MuscleGroupChip(group: exercise.muscleGroup),
              const Spacer(),
              Icon(
                exercise.hasVideo ? Icons.videocam : Icons.videocam_off_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
          if (plans.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Treinos: ${plans.map((p) => p.weekday.labelPt).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
