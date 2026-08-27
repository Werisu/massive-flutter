import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/keep_alive_service.dart';
import '../../core/services/rest_notification_service.dart';
import '../../core/services/screen_wake_service.dart';
import '../../core/services/timer_cue_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/hiit_protocol.dart';
import '../../data/seed/hiit_data.dart';

class HiitPlayerScreen extends ConsumerStatefulWidget {
  const HiitPlayerScreen({super.key, required this.protocolId});

  final String protocolId;

  @override
  ConsumerState<HiitPlayerScreen> createState() => _HiitPlayerScreenState();
}

class _HiitPlayerScreenState extends ConsumerState<HiitPlayerScreen>
    with WidgetsBindingObserver {
  HiitProtocol? _protocol;
  int _index = 0;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _running = false;
  bool _started = false;
  bool _completed = false;
  DateTime? _endsAt;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _protocol = HiitData.byId(widget.protocolId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    ScreenWakeService.instance.setEnabled(false);
    RestNotificationService.instance.cancelRest();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _endsAt != null && _running) {
      final left = _endsAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _onTimerElapsed();
      } else {
        setState(() => _remaining = left);
      }
    }
  }

  HiitSegment get _segment => _protocol!.segments[_index];

  Duration get _totalRemaining {
    var sum = _remaining;
    for (var i = _index + 1; i < _protocol!.segments.length; i++) {
      sum += _protocol!.segments[i].duration;
    }
    return sum;
  }

  Future<void> _start() async {
    setState(() {
      _started = true;
      _index = 0;
      _completed = false;
    });
    await KeepAliveService.instance.setEnabled(
      ref.read(preferencesProvider).keepAliveEnabled,
    );
    await _enterSegment(0);
  }

  Future<void> _enterSegment(int index) async {
    final protocol = _protocol!;
    if (index >= protocol.segments.length) {
      await _complete();
      return;
    }

    HapticFeedback.mediumImpact();
    final segment = protocol.segments[index];
    setState(() {
      _index = index;
      _remaining = segment.duration;
      _running = true;
    });
    ScreenWakeService.instance.setEnabled(true);
    _endsAt = DateTime.now().add(segment.duration);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      if (_endsAt == null) return;
      final left = _endsAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _onTimerElapsed();
        return;
      }
      setState(() => _remaining = left);
    });

    final nextIndex = index + 1;
    if (nextIndex < protocol.segments.length) {
      final next = protocol.segments[nextIndex];
      await RestNotificationService.instance.scheduleRestFinished(
        after: segment.duration,
        title: next.label,
        body: next.treadmillCue,
      );
    } else {
      await RestNotificationService.instance.scheduleRestFinished(
        after: segment.duration,
        title: 'Cardio concluído',
        body: 'Pode descer da esteira.',
      );
    }
  }

  void _onTimerElapsed() {
    TimerCueService.instance.play();
    _advance();
  }

  void _advance() {
    if (_advancing || _completed || _protocol == null) return;
    _advancing = true;
    _timer?.cancel();
    _enterSegment(_index + 1).whenComplete(() => _advancing = false);
  }

  void _toggle() {
    setState(() {
      if (_running) {
        _running = false;
        _timer?.cancel();
        ScreenWakeService.instance.setEnabled(false);
        RestNotificationService.instance.cancelRest();
      } else {
        _endsAt = DateTime.now().add(_remaining);
        _running = true;
        ScreenWakeService.instance.setEnabled(true);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!_running || _endsAt == null) return;
          final left = _endsAt!.difference(DateTime.now());
          if (left <= Duration.zero) {
            _onTimerElapsed();
            return;
          }
          setState(() => _remaining = left);
        });
        final protocol = _protocol!;
        final nextIndex = _index + 1;
        if (nextIndex < protocol.segments.length) {
          final next = protocol.segments[nextIndex];
          RestNotificationService.instance.scheduleRestFinished(
            after: _remaining,
            title: next.label,
            body: next.treadmillCue,
          );
        }
      }
    });
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await RestNotificationService.instance.cancelRest();
    HapticFeedback.heavyImpact();
    await ref
        .read(hiitCompletionProvider.notifier)
        .markCompleted(_protocol!.id);
    if (!mounted) return;
    setState(() {
      _running = false;
      _completed = true;
      _advancing = false;
    });
    ScreenWakeService.instance.setEnabled(false);
  }

  Future<void> _confirmLeave() async {
    if (!_started || _completed) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar cardio?'),
        content: const Text('O cronômetro será interrompido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final protocol = _protocol;
    if (protocol == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cardio')),
        body: EmptyState(
          title: 'Protocolo não encontrado',
          actionLabel: 'Voltar',
          onAction: () => context.pop(),
        ),
      );
    }

    if (!_started) {
      return _Preview(
        protocol: protocol,
        onStart: _start,
        onFallback: protocol.allowsBriskFallback
            ? () => context.pushReplacement('/hiit/${HiitData.briskWalkId}')
            : null,
      );
    }

    if (_completed) {
      return Scaffold(
        appBar: AppBar(title: Text(protocol.name)),
        body: EmptyState(
          title: 'Cardio concluído',
          subtitle: protocol.mode == HiitMode.hiitQuality ||
                  protocol.mode == HiitMode.hiitShort
              ? 'Dois HIIT bem colocados na semana rendem mais do que '
                  'correr forte todos os dias.'
              : 'Gasto extra sem competir com a musculação.',
          icon: Icons.check_circle_outline,
          actionLabel: 'Voltar',
          onAction: () => context.pop(),
        ),
      );
    }

    final segment = _segment;
    final color = _colorFor(segment.kind);
    final progress = segment.duration.inMilliseconds == 0
        ? 1.0
        : 1 - (_remaining.inMilliseconds / segment.duration.inMilliseconds);
    final next = _index + 1 < protocol.segments.length
        ? protocol.segments[_index + 1]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(protocol.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmLeave,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_index + progress.clamp(0.0, 1.0)) /
                              protocol.segments.length,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${_index + 1}/${protocol.segments.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Restam ${formatTimer(_totalRemaining)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  segment.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 160,
                  width: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: 160,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor: AppColors.surfaceElevated,
                          color: color,
                        ),
                      ),
                      Text(
                        formatTimer(_remaining),
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Velocidade',
                        value: segment.speedLabel,
                      ),
                    ),
                    if (segment.hasIncline) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MetricTile(
                          label: 'Inclinação',
                          value: segment.inclineLabel ?? '',
                        ),
                      ),
                    ],
                  ],
                ),
                if (next != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Próximo: ${next.label} · ${formatTimer(next.duration)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: _running ? 'Pausar' : 'Continuar',
                        icon: _running ? Icons.pause : Icons.play_arrow,
                        onPressed: _toggle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SecondaryButton(
                        label: next == null ? 'Concluir' : 'Pular',
                        icon: Icons.skip_next,
                        onPressed: _advance,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  protocol.cue,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorFor(HiitSegmentKind kind) {
    switch (kind) {
      case HiitSegmentKind.work:
        return AppColors.warning;
      case HiitSegmentKind.recover:
        return AppColors.info;
      case HiitSegmentKind.steady:
        return AppColors.primaryLight;
      case HiitSegmentKind.warmup:
      case HiitSegmentKind.cooldown:
        return AppColors.warmup;
    }
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.protocol,
    required this.onStart,
    this.onFallback,
  });

  final HiitProtocol protocol;
  final VoidCallback onStart;
  final VoidCallback? onFallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(protocol.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '${protocol.totalMinutes} minutos na esteira',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              protocol.rationale,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Text(
                protocol.cue,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Blocos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ...protocol.segments.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          formatTimer(s.duration),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              s.treadmillCue,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Começar',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
            if (onFallback != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Trocar por caminhada rápida',
                onPressed: onFallback,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlighted: true,
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}
