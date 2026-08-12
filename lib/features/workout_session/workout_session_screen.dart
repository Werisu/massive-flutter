import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/input_widgets.dart';
import '../../core/widgets/rest_timer.dart';
import '../../data/models/enums.dart';
import '../../data/models/workout_plan.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  WorkoutSession? _session;
  WorkoutPlan? _plan;
  int _exerciseIndex = 0;
  bool _loading = true;
  bool _showRest = false;
  Duration _restDuration = const Duration(minutes: 1);
  String? _error;

  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  int? _rir;
  String? _prefillHint;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final plan = ProtocolData.planById(widget.planId);
    if (plan == null || plan.isDayOff) {
      setState(() {
        _error = plan?.isDayOff == true
            ? 'Este dia é Day Off.'
            : 'Treino não encontrado.';
        _loading = false;
      });
      return;
    }

    try {
      final session =
          await ref.read(sessionsProvider.notifier).start(plan);
      final idx = _firstIncompleteExercise(session);
      setState(() {
        _plan = plan;
        _session = session;
        _exerciseIndex = idx;
        _loading = false;
      });
      _prefillCurrentSet();
    } catch (e) {
      setState(() {
        _error = 'Não foi possível iniciar o treino.';
        _loading = false;
      });
    }
  }

  int _firstIncompleteExercise(WorkoutSession session) {
    for (var i = 0; i < session.exercises.length; i++) {
      if (!session.exercises[i].isCompleted) return i;
    }
    return 0;
  }

  SessionExercise get _currentExercise =>
      _session!.exercises[_exerciseIndex];

  SetPrescription? _prescriptionFor(int setIndex) {
    final we = _plan!.exercises[_exerciseIndex];
    if (setIndex >= we.sets.length) return null;
    return we.sets[setIndex];
  }

  int? get _currentSetIndex {
    final sets = _currentExercise.sets;
    for (var i = 0; i < sets.length; i++) {
      if (!sets[i].completed) return i;
    }
    return null;
  }

  void _prefillCurrentSet() {
    final setIndex = _currentSetIndex;
    if (setIndex == null || _session == null) {
      setState(() => _prefillHint = null);
      return;
    }

    final set = _currentExercise.sets[setIndex];
    final repo = ref.read(sessionRepositoryProvider);
    final suggestion = repo.suggestPrefill(
      exerciseId: _currentExercise.exerciseId,
      setType: set.setType,
      currentSets: _currentExercise.sets,
      currentSetIndex: setIndex,
    );

    // Já preenchido na própria série (retomada)
    if (set.weight != null) {
      _weightCtrl.text = _formatNum(set.weight!);
    } else if (suggestion?.weight != null) {
      _weightCtrl.text = _formatNum(suggestion!.weight!);
    } else {
      _weightCtrl.clear();
    }

    if (set.repetitions != null) {
      _repsCtrl.text = '${set.repetitions}';
    } else if (suggestion?.repetitions != null) {
      final s = suggestion!;
      final shouldPrefillReps = set.setType == SetType.working ||
          s.sourceType == set.setType ||
          !s.fromHistory;
      if (shouldPrefillReps) {
        _repsCtrl.text = '${s.repetitions}';
      } else {
        _repsCtrl.clear();
      }
    } else {
      _repsCtrl.clear();
    }

    _rir = set.rir ?? suggestion?.rir;

    String? hint;
    if (suggestion != null &&
        (suggestion.weight != null || suggestion.repetitions != null)) {
      final origin =
          suggestion.fromHistory ? 'Último treino' : 'Série anterior';
      hint =
          '$origin: ${formatWeight(suggestion.weight)} × ${suggestion.repetitions ?? '—'} reps'
          '${suggestion.rir != null ? ' · RIR ${suggestion.rir}' : ''}';
    }

    setState(() => _prefillHint = hint);
  }

  String _formatNum(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

  Future<void> _completeCurrentSet() async {
    final setIndex = _currentSetIndex;
    if (setIndex == null || _session == null) return;

    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsCtrl.text);

    if (reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as repetições realizadas.')),
      );
      return;
    }

    final prescription = _prescriptionFor(setIndex);
    final previous = ref
        .read(sessionRepositoryProvider)
        .getLastWorkingSet(_currentExercise.exerciseId);

    final updated = await ref.read(sessionsProvider.notifier).completeSet(
          session: _session!,
          exerciseId: _currentExercise.exerciseId,
          setIndex: setIndex,
          weight: weight,
          repetitions: reps,
          rir: _rir,
        );

    final msg = progressionMessage(
      previousReps: previous?.repetitions,
      currentReps: reps,
      previousWeight: previous?.weight,
      currentWeight: weight,
      targetRepMax: prescription?.repMax ?? 10,
    );
    final suggestion = weightSuggestion(
      reps: reps,
      targetRepMax: prescription?.repMax ?? 10,
    );

    if (mounted && (msg.isNotEmpty || suggestion.isNotEmpty)) {
      final text = [msg, suggestion].where((e) => e.isNotEmpty).join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final setType = updated.exercises[_exerciseIndex].sets[setIndex].setType;
    final prefs = ref.read(preferencesProvider);
    final rest = setType == SetType.working
        ? Duration(minutes: prefs.restMinutesWorking)
        : Duration(minutes: prefs.restMinutesPrep);

    setState(() {
      _session = updated;
      _showRest = true;
      _restDuration = rest;
    });

    // If exercise done, advance after rest skip/finish
    if (updated.exercises[_exerciseIndex].isCompleted) {
      // keep index; advance when rest ends
    }
  }

  void _afterRest() {
    if (_session == null) return;
    setState(() => _showRest = false);

    if (_session!.exercises[_exerciseIndex].isCompleted) {
      if (_exerciseIndex < _session!.exercises.length - 1) {
        setState(() => _exerciseIndex++);
      }
    }
    _prefillCurrentSet();
  }

  Future<void> _finishWorkout() async {
    if (_session == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar treino?'),
        content: Text(
          'Séries concluídas: ${_session!.completedSets}/${_session!.totalSets}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(sessionsProvider.notifier).finish(_session!);
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treino salvo no histórico.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _session == null || _plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: EmptyState(
          title: _error ?? 'Erro',
          actionLabel: 'Voltar',
          onAction: () => context.pop(),
        ),
      );
    }

    final exercise =
        ProtocolData.exerciseById(_currentExercise.exerciseId);
    final setIndex = _currentSetIndex;
    final last = ref
        .watch(sessionRepositoryProvider)
        .getLastWorkingSet(_currentExercise.exerciseId);
    final prescription =
        setIndex == null ? null : _prescriptionFor(setIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan!.name),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('Finalizar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _session!.progress,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${(_session!.progress * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _session!.exercises.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final done = _session!.exercises[i].isCompleted;
                        final selected = i == _exerciseIndex;
                        return ChoiceChip(
                          label: Text('${i + 1}'),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _exerciseIndex = i;
                              _showRest = false;
                            });
                            _prefillCurrentSet();
                          },
                          avatar: done
                              ? const Icon(Icons.check, size: 16)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Exercício ${_exerciseIndex + 1}/${_session!.exercises.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    exercise?.name ?? _currentExercise.exerciseId,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (exercise?.hasVideo == true)
                    SecondaryButton(
                      label: 'Ver vídeo',
                      icon: Icons.play_circle_outline,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reprodução de vídeo disponível quando houver URL.'),
                          ),
                        );
                      },
                    )
                  else
                    Text(
                      'Vídeo indisponível',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (last != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.history,
                              color: AppColors.primaryLight),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Último treino',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${formatWeight(last.weight)} × ${last.repetitions ?? '—'} reps',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Séries',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...List.generate(_currentExercise.sets.length, (i) {
                    final set = _currentExercise.sets[i];
                    final presc = _prescriptionFor(i)!;
                    final isCurrent = i == setIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SetCard(
                        set: set,
                        prescription: presc,
                        highlighted: isCurrent && !_showRest,
                      ),
                    );
                  }),
                  if (_showRest) ...[
                    const SizedBox(height: AppSpacing.md),
                    RestTimer(
                      key: ValueKey(_restDuration.inSeconds +
                          DateTime.now().millisecondsSinceEpoch),
                      initialDuration: _restDuration,
                      onFinished: _afterRest,
                      onSkip: _afterRest,
                    ),
                  ] else if (setIndex != null && prescription != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Registrar série ${setIndex + 1}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${prescription.type.labelPt} · ${prescription.repsLabel} reps',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_prefillHint != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history,
                                size: 18, color: AppColors.primaryLight),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Pré-preenchido · $_prefillHint',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: WeightInput(controller: _weightCtrl)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: RepsInput(controller: _repsCtrl)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RirSelector(
                      value: _rir,
                      onChanged: (v) => setState(() => _rir = v),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Concluir série',
                      icon: Icons.check_rounded,
                      onPressed: _completeCurrentSet,
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppCard(
                      highlighted: true,
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events_outlined,
                              color: AppColors.primaryLight, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _session!.exercises.every((e) => e.isCompleted)
                                ? 'Todas as séries concluídas!'
                                : 'Exercício concluído',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (_exerciseIndex <
                              _session!.exercises.length - 1)
                            PrimaryButton(
                              label: 'Próximo exercício',
                              onPressed: () {
                                setState(() => _exerciseIndex++);
                                _prefillCurrentSet();
                              },
                            )
                          else
                            PrimaryButton(
                              label: 'Finalizar treino',
                              onPressed: _finishWorkout,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.set,
    required this.prescription,
    this.highlighted = false,
  });

  final SetRecord set;
  final SetPrescription prescription;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlighted: highlighted,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: set.completed
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.surfaceElevated,
            child: set.completed
                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                : Text(
                    '${set.setNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SetTypeBadge(type: set.setType),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${prescription.repsLabel} reps',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (set.completed) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${formatWeight(set.weight)} × ${set.repetitions ?? '—'}'
                    '${set.rir != null ? ' · RIR ${set.rir}' : ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
