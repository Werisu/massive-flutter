import 'dart:async';

import 'package:flutter/material.dart';

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
  });

  final Duration initialDuration;
  final VoidCallback? onFinished;
  final VoidCallback? onSkip;

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late Duration _remaining;
  late Duration _total;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _total = widget.initialDuration;
    _remaining = widget.initialDuration;
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      if (_remaining.inSeconds <= 1) {
        setState(() => _remaining = Duration.zero);
        _timer?.cancel();
        _running = false;
        widget.onFinished?.call();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  void _toggle() {
    setState(() => _running = !_running);
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
    });
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
            onPressed: widget.onSkip,
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
