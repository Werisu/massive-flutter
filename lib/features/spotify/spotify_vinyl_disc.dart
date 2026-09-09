import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Disco de vinil: gira com a capa no miolo quando a faixa está no ar.
class SpotifyVinylDisc extends StatefulWidget {
  const SpotifyVinylDisc({
    super.key,
    this.artwork,
    this.spinning = false,
    this.size = 72,
  });

  final Uint8List? artwork;
  final bool spinning;
  final double size;

  @override
  State<SpotifyVinylDisc> createState() => _SpotifyVinylDiscState();
}

class _SpotifyVinylDiscState extends State<SpotifyVinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant SpotifyVinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final sleeve = size * 0.56;
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, child) {
        return Transform.rotate(
          angle: _spin.value * 2 * math.pi,
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: widget.spinning ? 0.35 : 0.12,
              ),
              blurRadius: widget.spinning ? 16 : 8,
              spreadRadius: widget.spinning ? 1 : 0,
            ),
          ],
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: const _VinylGroovePainter(),
              ),
              ClipOval(
                child: SizedBox(
                  width: sleeve,
                  height: sleeve,
                  child: widget.artwork == null
                      ? const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(
                            Icons.graphic_eq,
                            color: AppColors.primaryLight,
                          ),
                        )
                      : Image.memory(
                          widget.artwork!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                ),
              ),
              Container(
                width: size * 0.12,
                height: size * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(
                    color: AppColors.prGold.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinylGroovePainter extends CustomPainter {
  const _VinylGroovePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF121214));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.primary.withValues(alpha: 0.4),
    );
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withValues(alpha: 0.07);
    for (var i = 5; i <= 15; i++) {
      canvas.drawCircle(center, radius * (i / 16), groove);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
