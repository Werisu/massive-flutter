import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Confete rápido em overlay — some sozinho e não bloqueia o fluxo.
Future<void> playCelebration(
  BuildContext context, {
  required String title,
  String? subtitle,
}) async {
  if (!context.mounted) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  final done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: CelebrationBurst(
        title: title,
        subtitle: subtitle,
        onDone: () {
          entry.remove();
          if (!done.isCompleted) done.complete();
        },
      ),
    ),
  );
  overlay.insert(entry);
  await done.future;
}

class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({
    super.key,
    required this.title,
    this.subtitle,
    this.onDone,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onDone;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _duration = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    final random = math.Random();
    _particles = List.generate(42, (i) {
      final angle = (i / 42) * math.pi * 2 + random.nextDouble() * 0.4;
      final speed = 180 + random.nextDouble() * 280;
      return _Particle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 80,
        color: _colors[i % _colors.length],
        size: 5 + random.nextDouble() * 7,
        spin: (random.nextDouble() - 0.5) * 8,
      );
    });
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone?.call();
      })
      ..forward();
  }

  static const _colors = [
    AppColors.primary,
    AppColors.primaryLight,
    AppColors.prGold,
    AppColors.success,
    AppColors.accent,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final fade = _controller.value < 0.75
            ? 1.0
            : (1 - (_controller.value - 0.75) / 0.25).clamp(0.0, 1.0);
        final scale = 0.85 + Curves.elasticOut.transform(t.value.clamp(0.0, 1.0)) * 0.15;
        return Opacity(
          opacity: fade,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.45 * fade),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _BurstPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.prGold,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.subtitle!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.primaryLight,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  const _Particle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.spin,
  });

  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double spin;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.42);
    final gravity = 520.0;
    for (final p in particles) {
      final t = progress;
      final dx = origin.dx + p.vx * t;
      final dy = origin.dy + p.vy * t + 0.5 * gravity * t * t;
      final paint = Paint()..color = p.color.withValues(alpha: (1 - t) * 0.95);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
