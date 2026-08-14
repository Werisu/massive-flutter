import 'dart:async';

import 'package:flutter/material.dart';

import '../services/rest_notification_service.dart';
import '../services/timer_cue_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';
import 'common_widgets.dart';

class RestTimer extends StatefulWidget {
  const RestTimer({
    super.key,
    required this.initialDuration,
    this.onFinished,
    this.onSkip,
    this.notifyOnComplete = true,
  });

  final Duration initialDuration;
  final VoidCallback? onFinished;
  final VoidCallback? onSkip;
  final bool notifyOnComplete;

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with WidgetsBindingObserver {
  late Duration _remaining;
  late Duration _total;
  Timer? _timer;
  bool _running = false;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _total = widget.initialDuration;
    _remaining = widget.initialDuration;
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    RestNotificationService.instance.cancelRest();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _endsAt != null && _running) {
      final left = _endsAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _finish();
      } else {
        setState(() => _remaining = left);
      }
    }
  }

  Future<void> _scheduleNotification() async {
    if (!widget.notifyOnComplete || !_running) return;
    if (_remaining.inSeconds <= 0) return;
    await RestNotificationService.instance.scheduleRestFinished(
      after: _remaining,
    );
  }

  void _start() {
    _timer?.cancel();
    _running = true;
    _endsAt = DateTime.now().add(_remaining);
    _scheduleNotification();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      if (_endsAt != null) {
        final left = _endsAt!.difference(DateTime.now());
        if (left <= Duration.zero) {
          _finish();
          return;
        }
        setState(() => _remaining = left);
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    _running = false;
    setState(() => _remaining = Duration.zero);
    RestNotificationService.instance.cancelRest();
    TimerCueService.instance.play();
    widget.onFinished?.call();
  }

  void _toggle() {
    setState(() {
      if (_running) {
        _running = false;
        _timer?.cancel();
        RestNotificationService.instance.cancelRest();
      } else {
        _start();
      }
    });
  }

  void _restart() {
    setState(() {
      _remaining = _total;
    });
    _start();
  }

  void _adjust(int seconds) {
    setState(() {
      final next = _remaining.inSeconds + seconds;
      _remaining = Duration(seconds: next.clamp(0, 60 * 30));
      if (_remaining > _total) _total = _remaining;
      if (_running) {
        _endsAt = DateTime.now().add(_remaining);
        _scheduleNotification();
      }
    });
  }

  Future<void> _skip() async {
    await RestNotificationService.instance.cancelRest();
    widget.onSkip?.call();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total.inSeconds == 0
        ? 0.0
        : 1 - (_remaining.inSeconds / _total.inSeconds);

    return AppCard(
      highlighted: true,
      child: Column(
        children: [
          Text(
            'Descanso',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryLight,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Notificação ao terminar (mesmo fora do app)',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceElevated,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  formatTimer(_remaining),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimerAction(
                icon: Icons.remove,
                label: '-30s',
                onTap: () => _adjust(-30),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TimerAction(
                icon: _running ? Icons.pause : Icons.play_arrow,
                label: _running ? 'Pausar' : 'Continuar',
                onTap: _toggle,
              ),
              const SizedBox(width: AppSpacing.sm),
              _TimerAction(
                icon: Icons.refresh,
                label: 'Reiniciar',
                onTap: _restart,
              ),
              const SizedBox(width: AppSpacing.sm),
              _TimerAction(
                icon: Icons.add,
                label: '+30s',
                onTap: () => _adjust(30),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Pular descanso',
            onPressed: _skip,
            icon: Icons.skip_next,
          ),
        ],
      ),
    );
  }
}

class _TimerAction extends StatelessWidget {
  const _TimerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(48, 48),
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
