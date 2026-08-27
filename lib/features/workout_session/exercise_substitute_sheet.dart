import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/exercise.dart';
import '../../data/seed/exercise_substitutions.dart';
import '../../data/seed/protocol_data.dart';

class SubstitutionPick {
  const SubstitutionPick({
    required this.exerciseId,
    required this.persist,
  });

  final String exerciseId;
  final bool persist;
}

Future<SubstitutionPick?> showExerciseSubstituteSheet({
  required BuildContext context,
  required String protocolExerciseId,
  required String currentExerciseId,
  bool persistByDefault = false,
  bool showPersistToggle = true,
}) {
  return showModalBottomSheet<SubstitutionPick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ExerciseSubstituteSheet(
      protocolExerciseId: protocolExerciseId,
      currentExerciseId: currentExerciseId,
      persistByDefault: persistByDefault,
      showPersistToggle: showPersistToggle,
    ),
  );
}

class _ExerciseSubstituteSheet extends StatefulWidget {
  const _ExerciseSubstituteSheet({
    required this.protocolExerciseId,
    required this.currentExerciseId,
    required this.persistByDefault,
    required this.showPersistToggle,
  });

  final String protocolExerciseId;
  final String currentExerciseId;
  final bool persistByDefault;
  final bool showPersistToggle;

  @override
  State<_ExerciseSubstituteSheet> createState() =>
      _ExerciseSubstituteSheetState();
}

class _ExerciseSubstituteSheetState extends State<_ExerciseSubstituteSheet> {
  final _search = TextEditingController();
  late bool _persist;

  @override
  void initState() {
    super.initState();
    _persist = widget.persistByDefault;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(String exerciseId) {
    Navigator.pop(
      context,
      SubstitutionPick(exerciseId: exerciseId, persist: _persist),
    );
  }

  @override
  Widget build(BuildContext context) {
    final protocol = ProtocolData.exerciseById(widget.protocolExerciseId);
    final current = ProtocolData.exerciseById(widget.currentExerciseId);
    final query = _search.text.trim();
    final substituted = widget.currentExerciseId != widget.protocolExerciseId;

    final candidates = query.isEmpty
        ? ProtocolData.substitutesFor(
            protocolExerciseId: widget.protocolExerciseId,
            currentExerciseId: widget.currentExerciseId,
          )
        : ProtocolData.catalog.where((e) {
            if (e.id == widget.currentExerciseId) return false;
            final q = query.toLowerCase();
            return e.name.toLowerCase().contains(q) ||
                e.muscleGroup.labelPt.toLowerCase().contains(q);
          }).toList();

    final height = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Substituir exercício',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'As séries do protocolo permanecem. Só o movimento muda.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar variação ou exercício',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (widget.showPersistToggle) ...[
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usar sempre neste treino'),
                subtitle: const Text(
                  'Aplica de novo na próxima vez que iniciar este dia',
                ),
                value: _persist,
                onChanged: (v) => setState(() => _persist = v),
              ),
            ],
            if (substituted && protocol != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                onTap: () => _pick(widget.protocolExerciseId),
                child: Row(
                  children: [
                    const Icon(Icons.restart_alt, color: AppColors.primaryLight),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voltar ao original',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            protocol.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: candidates.isEmpty
                  ? const EmptyState(
                      title: 'Nenhuma variação encontrada',
                      subtitle: 'Tente outro nome.',
                      icon: Icons.search_off,
                    )
                  : ListView.separated(
                      itemCount: candidates.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final exercise = candidates[index];
                        final suggested = ExerciseSubstitutions.isSuggested(
                          protocolExerciseId: widget.protocolExerciseId,
                          candidateId: exercise.id,
                        );
                        return _SubstituteTile(
                          exercise: exercise,
                          suggested: suggested,
                          onTap: () => _pick(exercise.id),
                        );
                      },
                    ),
            ),
            if (current != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubstituteTile extends StatelessWidget {
  const _SubstituteTile({
    required this.exercise,
    required this.suggested,
    required this.onTap,
  });

  final Exercise exercise;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      highlighted: suggested,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    MuscleGroupChip(group: exercise.muscleGroup),
                    if (suggested)
                      const _HintChip(label: 'Sugerido'),
                    if (ExerciseSubstitutions.isAlternative(exercise.id))
                      const _HintChip(label: 'Variação'),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.swap_horiz, color: AppColors.primaryLight),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
