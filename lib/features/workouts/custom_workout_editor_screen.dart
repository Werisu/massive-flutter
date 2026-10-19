import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_plan.dart';
import '../../data/services/custom_workout_week.dart';
import '../../data/services/exercise_catalog.dart';
import '../workout_session/exercise_substitute_sheet.dart';

class CustomWorkoutEditorScreen extends ConsumerStatefulWidget {
  const CustomWorkoutEditorScreen({super.key});

  @override
  ConsumerState<CustomWorkoutEditorScreen> createState() =>
      _CustomWorkoutEditorScreenState();
}

class _CustomWorkoutEditorScreenState
    extends ConsumerState<CustomWorkoutEditorScreen> {
  final _uuid = const Uuid();
  late final List<_DayDraft> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final stored = ref.read(preferencesProvider).customPlans;
    final week = CustomWorkoutWeek.normalize(stored);
    _days = [for (final plan in week) _DayDraft.fromPlan(plan)];
  }

  @override
  void dispose() {
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  String get _summary {
    final training = _days
        .where((day) => !day.isDayOff && day.exercises.isNotEmpty)
        .length;
    final exercises = _days
        .where((day) => !day.isDayOff)
        .fold<int>(0, (total, day) => total + day.exercises.length);
    if (training == 0) return 'Nenhum dia de treino ainda.';
    final dayLabel = training == 1 ? 'dia' : 'dias';
    final exerciseLabel = exercises == 1 ? 'exercício' : 'exercícios';
    return '$training $dayLabel de treino · $exercises $exerciseLabel.';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addExercise(int dayIndex) async {
    final exerciseId = await showCustomExercisePicker(context);
    if (exerciseId == null || !mounted) return;
    setState(() {
      _days[dayIndex].exercises.add(
        _SlotDraft(
          id: 'custom_${_days[dayIndex].weekday.name}_${_uuid.v4()}',
          exerciseId: exerciseId,
        ),
      );
    });
  }

  Future<void> _editSets(int dayIndex, int exerciseIndex) async {
    final slot = _days[dayIndex].exercises[exerciseIndex];
    final next = await showDialog<_SetChoice>(
      context: context,
      builder: (context) => _SetsDialog(
        exerciseName: ExerciseCatalog.nameOf(slot.exerciseId),
        sets: slot.sets,
        repMin: slot.repMin,
        repMax: slot.repMax,
      ),
    );
    if (next == null || !mounted) return;
    setState(() {
      slot.sets = next.sets;
      slot.repMin = next.repMin;
      slot.repMax = next.repMax;
    });
  }

  void _move(int dayIndex, int exerciseIndex, int delta) {
    final list = _days[dayIndex].exercises;
    final target = exerciseIndex + delta;
    if (target < 0 || target >= list.length) return;
    setState(() {
      final slot = list.removeAt(exerciseIndex);
      list.insert(target, slot);
    });
  }

  Future<void> _save() async {
    for (final day in _days) {
      if (!day.isDayOff && day.exercises.isEmpty) {
        _snack(
          '${day.weekday.labelPt} está sem exercícios. '
          'Adicione algum ou marque folga.',
        );
        return;
      }
    }
    if (!CustomWorkoutWeek.hasTrainingDay(_plans())) {
      _snack('Inclua pelo menos um dia com exercícios.');
      return;
    }

    setState(() => _saving = true);
    await ref.read(preferencesProvider.notifier).saveCustomPlans(_plans());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Lista salva. Ela vale nos treinos de hoje.'),
      ),
    );
  }

  List<WorkoutPlan> _plans() {
    return [
      for (final day in _days)
        WorkoutPlan(
          id: CustomWorkoutWeek.idFor(day.weekday),
          name: day.nameCtrl.text,
          weekday: day.weekday,
          isDayOff: day.isDayOff,
          exercises: [
            for (var i = 0; i < day.exercises.length; i++)
              day.exercises[i].toWorkoutExercise(i + 1),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus treinos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Monte a semana inteira. Cada dia ganha um nome, os exercícios '
            'e as séries — ou fica de folga.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O exercício entra com 3 séries de 8 a 12. Toque nele para mudar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _summary,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primaryLight),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _days.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _DayCard(
              day: _days[i],
              onDayOffChanged: (value) =>
                  setState(() => _days[i].isDayOff = value),
              onAdd: () => _addExercise(i),
              onEdit: (index) => _editSets(i, index),
              onMoveUp: (index) => _move(i, index, -1),
              onMoveDown: (index) => _move(i, index, 1),
              onRemove: (index) =>
                  setState(() => _days[i].exercises.removeAt(index)),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Salvar lista',
            icon: Icons.check,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }
}

class _DayDraft {
  _DayDraft({
    required this.weekday,
    required String name,
    required this.isDayOff,
    required this.exercises,
  }) : nameCtrl = TextEditingController(text: name);

  factory _DayDraft.fromPlan(WorkoutPlan plan) {
    final untouched =
        plan.isDayOff && plan.exercises.isEmpty && plan.name == 'Treino';
    return _DayDraft(
      weekday: plan.weekday,
      name: untouched ? '' : plan.name,
      isDayOff: plan.isDayOff,
      exercises: [
        for (final slot in plan.exercises) _SlotDraft.fromWorkout(slot),
      ],
    );
  }

  final Weekday weekday;
  final TextEditingController nameCtrl;
  bool isDayOff;
  final List<_SlotDraft> exercises;

  void dispose() => nameCtrl.dispose();
}

class _SlotDraft {
  _SlotDraft({
    required this.id,
    required this.exerciseId,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
  });

  factory _SlotDraft.fromWorkout(WorkoutExercise slot) {
    final working = slot.sets.where((set) => set.type == SetType.working);
    final source = working.isEmpty ? slot.sets : working.toList();
    final first = source.isEmpty ? null : source.first;
    return _SlotDraft(
      id: slot.id,
      exerciseId: slot.exerciseId,
      sets: source.isEmpty ? 3 : source.length,
      repMin: first?.repMin ?? 8,
      repMax: first?.repMax ?? 12,
    );
  }

  final String id;
  final String exerciseId;
  int sets;
  int repMin;
  int repMax;

  String get label =>
      repMin == repMax ? '${sets}x$repMin' : '${sets}x$repMin-$repMax';

  WorkoutExercise toWorkoutExercise(int order) {
    final min = repMin <= repMax ? repMin : repMax;
    final max = repMax >= repMin ? repMax : repMin;
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      order: order,
      sets: [
        for (var i = 0; i < sets; i++)
          SetPrescription(type: SetType.working, repMin: min, repMax: max),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.onDayOffChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final _DayDraft day;
  final ValueChanged<bool> onDayOffChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day.weekday.labelUpper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: ValueKey('custom-name-${day.weekday.name}'),
              controller: day.nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do treino',
                hintText: 'Ex.: Peito e tríceps',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Treinar neste dia'),
              subtitle: Text(
                day.isDayOff
                    ? (day.exercises.isEmpty
                          ? 'Folga'
                          : 'Folga. Os exercícios ficam guardados.')
                    : 'Adicione os exercícios abaixo',
              ),
              value: !day.isDayOff,
              onChanged: (train) => onDayOffChanged(!train),
            ),
            if (!day.isDayOff) ...[
              for (var i = 0; i < day.exercises.length; i++)
                _ExerciseRow(
                  slot: day.exercises[i],
                  canMoveUp: i > 0,
                  canMoveDown: i < day.exercises.length - 1,
                  onEdit: () => onEdit(i),
                  onMoveUp: () => onMoveUp(i),
                  onMoveDown: () => onMoveDown(i),
                  onRemove: () => onRemove(i),
                ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Adicionar exercício',
                icon: Icons.add,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.slot,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final _SlotDraft slot;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final exercise = ExerciseCatalog.byId(slot.exerciseId);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise?.name ?? slot.exerciseId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        exercise == null
                            ? '${slot.label} valendo'
                            : '${slot.label} valendo · ${exercise.muscleGroup.labelPt}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Subir',
                  visualDensity: VisualDensity.compact,
                  onPressed: canMoveUp ? onMoveUp : null,
                  icon: const Icon(Icons.arrow_upward, size: 20),
                ),
                IconButton(
                  tooltip: 'Descer',
                  visualDensity: VisualDensity.compact,
                  onPressed: canMoveDown ? onMoveDown : null,
                  icon: const Icon(Icons.arrow_downward, size: 20),
                ),
                IconButton(
                  tooltip: 'Remover',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetChoice {
  const _SetChoice({
    required this.sets,
    required this.repMin,
    required this.repMax,
  });

  final int sets;
  final int repMin;
  final int repMax;
}

class _SetsDialog extends StatefulWidget {
  const _SetsDialog({
    required this.exerciseName,
    required this.sets,
    required this.repMin,
    required this.repMax,
  });

  final String exerciseName;
  final int sets;
  final int repMin;
  final int repMax;

  @override
  State<_SetsDialog> createState() => _SetsDialogState();
}

class _SetsDialogState extends State<_SetsDialog> {
  late int _sets;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _sets = widget.sets.clamp(1, 10);
    _minCtrl = TextEditingController(text: '${widget.repMin}');
    _maxCtrl = TextEditingController(text: '${widget.repMax}');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    var min = int.tryParse(_minCtrl.text) ?? widget.repMin;
    var max = int.tryParse(_maxCtrl.text) ?? widget.repMax;
    min = min.clamp(1, 50);
    max = max.clamp(1, 50);
    if (min > max) {
      final swap = min;
      min = max;
      max = swap;
    }
    Navigator.pop(context, _SetChoice(sets: _sets, repMin: min, repMax: max));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Séries valendo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: 'Menos séries',
                onPressed: _sets <= 1 ? null : () => setState(() => _sets -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_sets', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                tooltip: 'Mais séries',
                onPressed: _sets >= 10
                    ? null
                    : () => setState(() => _sets += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Repetições', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'De'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Até'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Aplicar')),
      ],
    );
  }
}

Future<String?> showCustomExercisePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _search = TextEditingController();
  MuscleGroup? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final draft = await showNewExerciseDialog(
      context: context,
      initialName: _search.text.trim(),
      initialGroup: _group ?? MuscleGroup.chest,
      confirmLabel: 'Criar e adicionar',
    );
    if (draft == null || !mounted) return;
    if (draft.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do exercício.')),
      );
      return;
    }
    final created = await ref
        .read(preferencesProvider.notifier)
        .addCustomExercise(name: draft.name, muscleGroup: draft.muscleGroup);
    if (!mounted) return;
    Navigator.pop(context, created.id);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    ExerciseCatalog.setCustom(prefs.customExercises);
    final query = _search.text.trim().toLowerCase();
    final exercises = ExerciseCatalog.all.where((exercise) {
      if (_group != null && exercise.muscleGroup != _group) return false;
      if (query.isEmpty) return true;
      return exercise.name.toLowerCase().contains(query) ||
          exercise.muscleGroup.labelPt.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

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
              'Adicionar exercício',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou músculo',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: _group == null,
                      onSelected: (_) => setState(() => _group = null),
                    ),
                  ),
                  for (final group in MuscleGroup.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: MuscleGroupChip(
                        group: group,
                        selected: _group == group,
                        onTap: () => setState(() {
                          _group = _group == group ? null : group;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: exercises.isEmpty
                  ? EmptyState(
                      title: 'Nenhum exercício com esse nome',
                      subtitle: query.isEmpty
                          ? 'Crie um exercício novo para a sua lista.'
                          : 'Crie “$query” e coloque neste dia.',
                      icon: Icons.search_off,
                      actionLabel: 'Criar exercício',
                      onAction: _create,
                    )
                  : ListView.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return _PickerTile(
                          exercise: exercise,
                          onTap: () => Navigator.pop(context, exercise.id),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: query.isEmpty ? 'Criar exercício' : 'Criar “$query”',
              icon: Icons.add,
              onPressed: _create,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
                MuscleGroupChip(group: exercise.muscleGroup),
              ],
            ),
          ),
          const Icon(Icons.add, color: AppColors.primaryLight),
        ],
      ),
    );
  }
}
