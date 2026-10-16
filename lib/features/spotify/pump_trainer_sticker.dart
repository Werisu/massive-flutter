import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Adesivo em loop de um garoto treinando (rosca, agacho, press).
/// Fundo transparente, no lugar de um GIF — nítido em qualquer tela.
class PumpTrainerSticker extends StatefulWidget {
  const PumpTrainerSticker({
    super.key,
    this.height = 186,
    this.showLabel = true,
    this.progress,
  });

  final double height;
  final bool showLabel;

  /// Quadro fixo de 0 a 1. Sem valor, a animação fica em loop.
  final double? progress;

  @override
  State<PumpTrainerSticker> createState() => _PumpTrainerStickerState();
}

class _PumpTrainerStickerState extends State<PumpTrainerSticker>
    with SingleTickerProviderStateMixin {
  static const _viewW = 150.0;
  static const _viewH = 210.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6600),
    );
    if (widget.progress == null) {
      _loop.repeat();
    } else {
      _loop.value = widget.progress!.clamp(0.0, 1.0);
    }
  }

  @override
  void didUpdateWidget(covariant PumpTrainerSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final frame = widget.progress;
    if (frame != null) {
      _loop.stop();
      _loop.value = frame.clamp(0.0, 1.0);
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * _viewW / _viewH;
    return Semantics(
      label: 'Garoto treinando',
      child: SizedBox(
        width: width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = widget.progress ?? _loop.value;
            final sample = _sample(t);
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrainerPainter(sample: sample, travel: t),
                  ),
                ),
                if (widget.showLabel)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: widget.height * 0.012,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0A0A0B,
                          ).withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _spotifyGreen.withValues(alpha: 0.85),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            sample.label,
                            style: TextStyle(
                              color: _spotifyGreen,
                              fontSize: (widget.height * 0.062).clamp(10, 13),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _spotifyGreen = Color(0xFF1DB954);

class _Sample {
  const _Sample({required this.label, required this.amp, required this.pose});

  final String label;
  final double amp;
  final _Pose pose;
}

_Sample _sample(double t) {
  final clamped = t.clamp(0.0, 0.999999);
  final segment = (clamped * 3).floor();
  final local = clamped * 3 - segment;
  const fade = 0.1;
  var edge = 1.0;
  if (local < fade) {
    edge = local / fade;
  } else if (local > 1 - fade) {
    edge = (1 - local) / fade;
  }
  final wave = math.sin(local * math.pi * 2).abs();
  final raw = wave * edge;
  final amp = raw > 0.72 ? 1.0 : Curves.easeOut.transform(raw / 0.72);
  final peak = switch (segment) {
    0 => _curl,
    1 => _squat,
    _ => _press,
  };
  const labels = ['Rosca', 'Agachamento', 'Press'];
  return _Sample(
    label: labels[segment],
    amp: amp,
    pose: _stand.lerp(peak, amp),
  );
}

class _Pose {
  const _Pose({
    required this.head,
    required this.shoulder,
    required this.hip,
    required this.kneeBack,
    required this.footBack,
    required this.kneeFront,
    required this.footFront,
    required this.elbow,
    required this.hand,
    required this.elbowBack,
    required this.handBack,
  });

  final Offset head;
  final Offset shoulder;
  final Offset hip;
  final Offset kneeBack;
  final Offset footBack;
  final Offset kneeFront;
  final Offset footFront;
  final Offset elbow;
  final Offset hand;
  final Offset elbowBack;
  final Offset handBack;

  _Pose lerp(_Pose other, double t) {
    Offset mix(Offset a, Offset b) => Offset.lerp(a, b, t)!;
    return _Pose(
      head: mix(head, other.head),
      shoulder: mix(shoulder, other.shoulder),
      hip: mix(hip, other.hip),
      kneeBack: mix(kneeBack, other.kneeBack),
      footBack: mix(footBack, other.footBack),
      kneeFront: mix(kneeFront, other.kneeFront),
      footFront: mix(footFront, other.footFront),
      elbow: mix(elbow, other.elbow),
      hand: mix(hand, other.hand),
      elbowBack: mix(elbowBack, other.elbowBack),
      handBack: mix(handBack, other.handBack),
    );
  }
}

const _stand = _Pose(
  head: Offset(78, 40),
  shoulder: Offset(76, 64),
  hip: Offset(74, 116),
  kneeBack: Offset(60, 152),
  footBack: Offset(54, 180),
  kneeFront: Offset(84, 154),
  footFront: Offset(94, 180),
  elbow: Offset(104, 94),
  hand: Offset(110, 126),
  elbowBack: Offset(58, 96),
  handBack: Offset(52, 126),
);

const _curl = _Pose(
  head: Offset(74, 42),
  shoulder: Offset(74, 66),
  hip: Offset(72, 116),
  kneeBack: Offset(58, 152),
  footBack: Offset(52, 180),
  kneeFront: Offset(84, 154),
  footFront: Offset(94, 180),
  elbow: Offset(108, 98),
  hand: Offset(116, 64),
  elbowBack: Offset(46, 104),
  handBack: Offset(42, 136),
);

const _squat = _Pose(
  head: Offset(82, 70),
  shoulder: Offset(80, 94),
  hip: Offset(86, 140),
  kneeBack: Offset(58, 160),
  footBack: Offset(48, 180),
  kneeFront: Offset(114, 158),
  footFront: Offset(96, 180),
  elbow: Offset(104, 122),
  hand: Offset(108, 148),
  elbowBack: Offset(66, 124),
  handBack: Offset(62, 148),
);

const _press = _Pose(
  head: Offset(76, 52),
  shoulder: Offset(76, 74),
  hip: Offset(74, 118),
  kneeBack: Offset(60, 154),
  footBack: Offset(54, 180),
  kneeFront: Offset(86, 156),
  footFront: Offset(94, 180),
  elbow: Offset(106, 46),
  hand: Offset(86, 20),
  elbowBack: Offset(46, 48),
  handBack: Offset(66, 20),
);

class _TrainerPainter extends CustomPainter {
  const _TrainerPainter({required this.sample, required this.travel});

  final _Sample sample;
  final double travel;

  static const _skin = Color(0xFFF3C1A0);
  static const _skinShade = Color(0xFFE0A67E);
  static const _hair = Color(0xFF3A2A24);
  static const _shirt = Color(0xFF7C3AED);
  static const _shirtLight = Color(0xFFA78BFA);
  static const _shorts = Color(0xFF2E1065);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = sample.pose;
    canvas.save();
    canvas.scale(size.width / 150, size.height / 210);
    final bob = math.sin(travel * math.pi * 6) * 1.1;
    canvas.translate(0, bob);

    _shadow(canvas);
    _leg(canvas, pose.hip, pose.kneeBack, pose.footBack, front: false);
    _arm(
      canvas,
      pose.shoulder,
      pose.hip,
      pose.elbowBack,
      pose.handBack,
      front: false,
    );
    _leg(canvas, pose.hip, pose.kneeFront, pose.footFront, front: true);
    _torso(canvas, pose.shoulder, pose.hip);
    _drawShorts(canvas, pose);
    _shoe(canvas, pose.footBack, front: false);
    _shoe(canvas, pose.footFront, front: true);
    _head(canvas, pose.head);
    _arm(canvas, pose.shoulder, pose.hip, pose.elbow, pose.hand, front: true);
    _dumbbell(canvas, pose.elbow, pose.hand, pose.handBack);
    _notes(canvas);
    canvas.restore();
  }

  void _shadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(78, 192), width: 86, height: 14),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.32),
    );
  }

  void _leg(
    Canvas canvas,
    Offset hip,
    Offset knee,
    Offset foot, {
    required bool front,
  }) {
    final color = front ? _skin : _skinShade;
    final thigh = front ? 15.0 : 13.0;
    final shin = front ? 12.5 : 11.0;
    _limb(canvas, hip, knee, thigh, color);
    _limb(canvas, knee, foot, shin, color);
    canvas.drawCircle(knee, front ? 6 : 5, Paint()..color = color);
  }

  void _arm(
    Canvas canvas,
    Offset shoulder,
    Offset hip,
    Offset elbow,
    Offset hand, {
    required bool front,
  }) {
    final origin = _shoulderSide(shoulder, hip, front: front);
    final color = front ? _skin : _skinShade;
    _limb(canvas, origin, elbow, front ? 14 : 12, color);
    _limb(canvas, elbow, hand, front ? 12 : 10.5, color);
    canvas.drawCircle(elbow, front ? 6 : 5, Paint()..color = color);
    canvas.drawCircle(hand, front ? 5.6 : 4.6, Paint()..color = color);
    if (front) _wristband(canvas, elbow, hand);
  }

  void _wristband(Canvas canvas, Offset elbow, Offset hand) {
    var dir = hand - elbow;
    final len = dir.distance;
    if (len < 1) return;
    final px = -dir.dy / len;
    final py = dir.dx / len;
    final wrist = elbow + dir * 0.74;
    canvas.drawLine(
      wrist + Offset(px, py) * 7.5,
      wrist - Offset(px, py) * 7.5,
      Paint()
        ..color = _spotifyGreen
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _torso(Canvas canvas, Offset shoulder, Offset hip) {
    final axis = hip - shoulder;
    final len = math.max(axis.distance, 0.001);
    final nx = -axis.dy / len;
    final ny = axis.dx / len;
    final neck = shoulder - axis / len * 14;
    _limb(canvas, neck, Offset.lerp(shoulder, hip, 0.2)!, 11, _skin);

    Offset side(double along, double width) {
      final p = Offset.lerp(shoulder, hip, along)!;
      return Offset(p.dx + nx * width, p.dy + ny * width);
    }

    final shirt = Path()
      ..moveTo(side(0.12, -16).dx, side(0.12, -16).dy)
      ..lineTo(side(0.5, -14).dx, side(0.5, -14).dy)
      ..lineTo(side(0.9, -15).dx, side(0.9, -15).dy)
      ..lineTo(side(0.9, 15).dx, side(0.9, 15).dy)
      ..lineTo(side(0.5, 14).dx, side(0.5, 14).dy)
      ..lineTo(side(0.12, 16).dx, side(0.12, 16).dy)
      ..close();
    canvas.drawPath(shirt, Paint()..color = _shirt);

    final shine = Path()
      ..moveTo(side(0.22, -4).dx, side(0.22, -4).dy)
      ..lineTo(side(0.62, -2).dx, side(0.62, -2).dy)
      ..lineTo(side(0.62, 5).dx, side(0.62, 5).dy)
      ..lineTo(side(0.22, 4).dx, side(0.22, 4).dy)
      ..close();
    canvas.drawPath(
      shine,
      Paint()..color = _shirtLight.withValues(alpha: 0.45),
    );
  }

  void _drawShorts(Canvas canvas, _Pose pose) {
    final left = Offset.lerp(pose.hip, pose.kneeBack, 0.42)!;
    final right = Offset.lerp(pose.hip, pose.kneeFront, 0.42)!;
    _limb(canvas, pose.hip, left, 16, _shorts);
    _limb(canvas, pose.hip, right, 17, _shorts);
    canvas.drawCircle(pose.hip, 8, Paint()..color = _shorts);
    _limb(
      canvas,
      pose.hip + const Offset(8, 4),
      right + const Offset(2, -2),
      2.2,
      _spotifyGreen,
    );
  }

  void _shoe(Canvas canvas, Offset foot, {required bool front}) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: foot + const Offset(6, 2),
        width: front ? 24 : 20,
        height: 9,
      ),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawLine(
      foot + const Offset(-4, 5),
      foot + const Offset(16, 5),
      Paint()
        ..color = _spotifyGreen
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _head(Canvas canvas, Offset head) {
    canvas.drawCircle(head + const Offset(-13, 3), 4.2, Paint()..color = _skin);
    canvas.drawCircle(head + const Offset(-1, -3), 17, Paint()..color = _hair);
    canvas.drawCircle(head + const Offset(1, 1), 15.5, Paint()..color = _skin);
    final spike = Path()
      ..moveTo(head.dx - 7, head.dy - 14)
      ..lineTo(head.dx - 1, head.dy - 27)
      ..lineTo(head.dx + 6, head.dy - 13)
      ..close();
    canvas.drawPath(spike, Paint()..color = _hair);
    canvas.drawArc(
      Rect.fromCircle(center: head + const Offset(1, -4), radius: 15),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = _hair
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    _eye(canvas, head + const Offset(3, -1));
    _eye(canvas, head + const Offset(9, 0));
    canvas.drawLine(
      head + const Offset(2, -6),
      head + const Offset(10, -7.5),
      Paint()
        ..color = _hair
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCenter(center: head + const Offset(6, 6), width: 8, height: 6),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFF6B3E2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      head + const Offset(-6, -7),
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    final band = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: head + const Offset(0, 1), radius: 19),
      math.pi,
      -math.pi,
      false,
      band,
    );
    for (final cup in [
      head + const Offset(-16, 3),
      head + const Offset(16, 2),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: cup, width: 8, height: 12),
          const Radius.circular(3),
        ),
        Paint()..color = _spotifyGreen,
      );
    }

    if (sample.amp > 0.55) {
      final drop = (sample.amp - 0.55) / 0.45;
      canvas.drawCircle(
        head + Offset(16 + drop * 4, -2 + drop * 16),
        2.1,
        Paint()..color = const Color(0xFF7DD3FC).withValues(alpha: 0.85),
      );
    }
  }

  void _eye(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      center + const Offset(0.7, 0.2),
      1.35,
      Paint()..color = const Color(0xFF2A211C),
    );
  }

  void _dumbbell(Canvas canvas, Offset elbow, Offset hand, Offset otherHand) {
    final overhead = hand.dy < 36 && otherHand.dy < 36;
    if (overhead) {
      final mid = Offset(
        (hand.dx + otherHand.dx) / 2,
        (hand.dy + otherHand.dy) / 2,
      );
      _bar(canvas, mid + const Offset(-20, 0), mid + const Offset(20, 0));
      return;
    }

    var dir = hand - elbow;
    if (dir.distance < 1) dir = const Offset(0, 1);
    final len = dir.distance;
    final px = -dir.dy / len;
    final py = dir.dx / len;
    const bar = 12.0;
    _bar(canvas, hand + Offset(px, py) * bar, hand - Offset(px, py) * bar);
  }

  void _bar(Canvas canvas, Offset a, Offset b) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = AppColors.prGold
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );
    final plate = Paint()..color = const Color(0xFFE4E4E7);
    final inner = Paint()..color = const Color(0xFFA1A1AA);
    for (final end in [a, b]) {
      canvas.drawCircle(end, 7.4, plate);
      canvas.drawCircle(end, 3.5, inner);
    }
  }

  void _notes(Canvas canvas) {
    if (sample.amp < 0.4) return;
    final rise = (travel * 3) % 1;
    final alpha = math.sin(rise * math.pi) * 0.9;
    _note(canvas, Offset(126, 36 - rise * 18), alpha);
  }

  void _note(Canvas canvas, Offset c, double alpha) {
    final color = _spotifyGreen.withValues(alpha: alpha);
    canvas.drawCircle(c + const Offset(0, 8), 3.1, Paint()..color = color);
    canvas.drawLine(
      c + const Offset(2.8, 8),
      c + const Offset(2.8, -5),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(c.dx + 2.8, c.dy - 5)
      ..quadraticBezierTo(c.dx + 12, c.dy - 2, c.dx + 7, c.dy + 2);
    canvas.drawPath(
      flag,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  Offset _shoulderSide(Offset shoulder, Offset hip, {required bool front}) {
    final axis = hip - shoulder;
    final len = math.max(axis.distance, 0.001);
    final nx = -axis.dy / len;
    final ny = axis.dx / len;
    final width = front ? 12.0 : -10.0;
    return Offset(shoulder.dx + nx * width, shoulder.dy + ny * width);
  }

  void _limb(Canvas canvas, Offset a, Offset b, double width, Color color) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrainerPainter oldDelegate) {
    return oldDelegate.travel != travel || oldDelegate.sample.amp != sample.amp;
  }
}
