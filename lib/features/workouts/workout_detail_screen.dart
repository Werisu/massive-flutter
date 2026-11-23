import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/workout_plan.dart';
import '../../data/seed/differentiated_data.dart';
import '../../data/seed/full_body_data.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/seed/three_seven_data.dart';
import 'differentiated_workout_view.dart';
import '../../data/services/custom_workout_week.dart';
import '../../data/services/exercise_catalog.dart';
import '../workout_session/exercise_substitute_sheet.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final plan = ProtocolData.planById(planId);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const EmptyState(title: 'Treino não encontrado'),
      );
    }

    final fullBody = FullBodyData.isPlan(plan.id);
    final differentiated = DifferentiatedData.isPlan(plan.id);
    final threeSeven = ThreeSevenData.isPlan(plan.id);
    final recovery = DifferentiatedData.recoveryFor(plan.id);
    final custom = CustomWorkoutWeek.isId(plan.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${plan.weekday.labelPt} — ${plan.name}'),
        actions: [
          if (custom)
            IconButton(
              tooltip: 'Editar lista',
              onPressed: () => context.push('/custom-workouts'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: recovery != null
          ? DifferentiatedRecoveryView(plan: plan)
          : plan.isDayOff
          ? EmptyState(
              title: 'DAY OFF',
              subtitle: custom
                  ? 'Folga na sua lista. Edite a semana se quiser treinar neste dia.'
                  : fullBody
                  ? 'Dia de recuperação do full body. O treino volta na próxima segunda, quarta ou sexta.'
                  : differentiated
                  ? 'Sábado e domingo ficam livres. A semana diferenciada volta na segunda.'
                  : threeSeven
                  ? 'Dia de recuperação do 3/7. O bloco volta na próxima segunda, terça, quinta ou sexta.'
                  : 'Dia de recuperação conforme o protocolo. Sono, comida e descanso fazem o músculo crescer.',
              icon: Icons.hotel_outlined,
            )
          : differentiated
          ? DifferentiatedWorkoutView(plan: plan)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  custom
                      ? '${plan.exerciseCount} exercícios da sua lista. Use a troca se o equipamento não estiver disponível.'
                      : threeSeven
                      ? '${plan.exerciseCount} exercícios. Cada um é um bloco 3/7: mini-séries de 3, 4, 5, 6 e 7 reps na mesma carga, com 15 segundos entre elas. Depois do 7, descanse 3 min.'
                      : fullBody
                      ? '${plan.exerciseCount} exercícios · 3 séries valendo. Compostos em 6–10 reps, bíceps e tríceps em 8–12. Use a troca se o equipamento não estiver disponível.'
                      : '${plan.exerciseCount} exercícios · séries do protocolo. Use a troca se o equipamento não estiver disponível.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...plan.exercises.map((we) {
                  final replacementId = prefs.exerciseSubstitutions[we.id];
                  final displayId = replacementId ?? we.exerciseId;
                  final exercise = ExerciseCatalog.byId(displayId);
                  final original = replacementId == null
                      ? null
                      : ExerciseCatalog.byId(we.exerciseId);
                  final warmup = we.sets
                      .where((s) => s.type == SetType.warmup)
                      .length;
                  final prep = we.sets
                      .where((s) => s.type == SetType.preparation)
                      .length;
                  final working = we.sets
                      .where((s) => s.type == SetType.working)
                      .length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${we.order}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      context.push('/exercise/$displayId'),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise?.name ?? displayId,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      if (original != null)
                                        Text(
                                          'No lugar de ${original.name}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Substituir exercício',
                                onPressed: () async {
                                  final pick =
                                      await showExerciseSubstituteSheet(
                                        context: context,
                                        protocolExerciseId: we.exerciseId,
                                        currentExerciseId: displayId,
                                        persistByDefault: true,
                                        showPersistToggle: false,
                                      );
                                  if (pick == null) return;
                                  await ref
                                      .read(preferencesProvider.notifier)
                                      .setExerciseSubstitution(
                                        workoutExerciseId: we.id,
                                        replacementExerciseId:
                                            pick.exerciseId == we.exerciseId
                                            ? null
                                            : pick.exerciseId,
                                      );
                                },
                                icon: const Icon(Icons.swap_horiz),
                              ),
                            ],
                          ),
                          if (exercise != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            MuscleGroupChip(group: exercise.muscleGroup),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          if (we.focus != null) ...[
                            Text(
                              we.focus!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (warmup > 0)
                                _SetSummary(
                                  label: 'Aquecimento',
                                  value: _setGroupLabel(
                                    we.sets,
                                    SetType.warmup,
                                  ),
                                ),
                              if (prep > 0)
                                _SetSummary(
                                  label: 'Preparatórias',
                                  value: _setGroupLabel(
                                    we.sets,
                                    SetType.preparation,
                                  ),
                                ),
                              if (working > 0)
                                _SetSummary(
                                  label: 'Valendo',
                                  value: _setGroupLabel(
                                    we.sets,
                                    SetType.working,
                                  ),
                                ),
                            ],
                          ),
                          if (we.restLabel != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Pausa entre as mini-séries: ${we.restLabel}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
      bottomNavigationBar: plan.isDayOff
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: 'Bora treinar',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.push('/session/${plan.id}'),
                ),
              ),
            ),
    );
  }
}

String _setGroupLabel(List<SetPrescription> sets, SetType type) {
  final matched = sets.where((s) => s.type == type).toList();
  if (matched.isEmpty) return '';
  final first = matched.first;
  final sameReps = matched.every(
    (set) => set.repMin == first.repMin && set.repMax == first.repMax,
  );
  if (!sameReps) {
    final sequence = matched.map((set) => set.repsLabel).join('+');
    final note = first.note;
    if (note != null &&
        note.isNotEmpty &&
        matched.every((set) => set.note == note)) {
      return '$sequence · $note';
    }
    return sequence;
  }
  return '${matched.length}x${first.repsLabel}';
}

class _SetSummary extends StatelessWidget {
  const _SetSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
