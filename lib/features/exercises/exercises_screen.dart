import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/seed/exercise_substitutions.dart';
import '../../data/services/exercise_catalog.dart';

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
    ref.watch(sessionsProvider);
    final all = ref.watch(allExercisesProvider);
    final repo = ref.watch(sessionRepositoryProvider);
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
                    subtitle: 'Tente outro nome ou limpe o filtro muscular.',
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
                        lastSet: repo.getLastWorkingSet(exercise.id),
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
    this.lastSet,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final SetRecord? lastSet;

  @override
  Widget build(BuildContext context) {
    final plans = ProtocolData.plansContainingExercise(exercise.id);
    final summary = ProtocolData.setsSummary(exercise.id);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Icon(
                exercise.hasVideo
                    ? Icons.videocam
                    : Icons.videocam_off_outlined,
                size: 18,
                color: exercise.hasVideo
                    ? AppColors.primaryLight
                    : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MuscleGroupChip(group: exercise.muscleGroup),
              if (ExerciseCatalog.isCustom(exercise.id))
                Text(
                  'Meu',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                )
              else if (ExerciseSubstitutions.isAlternative(exercise.id))
                Text(
                  'Variação',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (plans.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Treinos: ${plans.map((p) => p.weekday.labelPt).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (lastSet != null &&
              (lastSet!.weight != null || lastSet!.repetitions != null)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Último: ${formatWeight(lastSet!.weight)} × ${lastSet!.repetitions ?? '—'} reps',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
