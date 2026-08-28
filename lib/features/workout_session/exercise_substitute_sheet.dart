import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/seed/exercise_substitutions.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/services/exercise_catalog.dart';

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
    builder: (context) => ExerciseSubstituteSheet(
      protocolExerciseId: protocolExerciseId,
      currentExerciseId: currentExerciseId,
      persistByDefault: persistByDefault,
      showPersistToggle: showPersistToggle,
    ),
  );
}

class ExerciseSubstituteSheet extends ConsumerStatefulWidget {
  const ExerciseSubstituteSheet({
    super.key,
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
  ConsumerState<ExerciseSubstituteSheet> createState() =>
      _ExerciseSubstituteSheetState();
}

class _ExerciseSubstituteSheetState
    extends ConsumerState<ExerciseSubstituteSheet> {
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

  Future<void> _createExercise() async {
    final protocol = ProtocolData.exerciseById(widget.protocolExerciseId);
    final nameCtrl = TextEditingController(text: _search.text.trim());
    var group = protocol?.muscleGroup ?? MuscleGroup.biceps;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return AlertDialog(
              title: const Text('Novo exercício'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Ex.: Martelo na polia sentado',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Grupo muscular',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: MuscleGroup.values
                          .map(
                            (g) => MuscleGroupChip(
                              group: g,
                              selected: group == g,
                              onTap: () => setModal(() => group = g),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Criar e usar'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (confirmed != true || !mounted) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do exercício.')),
      );
      return;
    }

    final created = await ref.read(preferencesProvider.notifier).addCustomExercise(
          name: name,
          muscleGroup: group,
        );
    if (!mounted) return;
    _pick(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    ExerciseCatalog.setCustom(prefs.customExercises);

    final protocol = ProtocolData.exerciseById(widget.protocolExerciseId);
    final query = _search.text.trim();
    final substituted = widget.currentExerciseId != widget.protocolExerciseId;

    final candidates = query.isEmpty
        ? ProtocolData.substitutesFor(
            protocolExerciseId: widget.protocolExerciseId,
            currentExerciseId: widget.currentExerciseId,
            extra: prefs.customExercises,
          )
        : ExerciseCatalog.all.where((e) {
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
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Buscar ou criar um exercício',
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
                  ? EmptyState(
                      title: query.isEmpty
                          ? 'Nenhuma variação encontrada'
                          : 'Nenhum exercício com esse nome',
                      subtitle: query.isEmpty
                          ? 'Crie um exercício novo para usar neste treino.'
                          : 'Crie “$query” e use no lugar do protocolo.',
                      icon: Icons.search_off,
                      actionLabel: query.isEmpty
                          ? 'Criar exercício'
                          : 'Criar “$query”',
                      onAction: _createExercise,
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
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: query.isEmpty
                  ? 'Criar exercício'
                  : 'Criar “$query”',
              icon: Icons.add,
              onPressed: _createExercise,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
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
                    if (suggested) const _HintChip(label: 'Sugerido'),
                    if (ExerciseCatalog.isCustom(exercise.id))
                      const _HintChip(label: 'Meu')
                    else if (ExerciseSubstitutions.isAlternative(exercise.id))
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
