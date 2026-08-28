import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/workout_share_snapshot.dart';

/// Card 9:16 (360×640 lógicos → 1080×1920 com pixelRatio 3) para stories.
class WorkoutShareCard extends StatelessWidget {
  const WorkoutShareCard({super.key, required this.snapshot});

  static const Size logicalSize = Size(360, 640);

  final WorkoutShareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF12081F),
                    AppColors.background,
                    Color(0xFF0B0614),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            const Positioned(
              top: -80,
              right: -60,
              child: _GlowOrb(size: 260, color: AppColors.primary),
            ),
            const Positioned(
              bottom: 80,
              left: -90,
              child: _GlowOrb(size: 220, color: AppColors.accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: 18),
                  Text(
                    snapshot.athleteName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.workoutTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.dateLabel}  ·  Treino #${snapshot.trainingDayNumber}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatsRow(snapshot: snapshot),
                  if (snapshot.prCount > 0 || snapshot.hiitCompleted) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (snapshot.prCount > 0)
                          _Chip(
                            label:
                                '${snapshot.prCount} ${snapshot.prCount == 1 ? 'PR' : 'PRs'}',
                            color: AppColors.prGold,
                          ),
                        if (snapshot.hiitCompleted)
                          const _Chip(
                            label: 'HIIT ✓',
                            color: AppColors.success,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppColors.surfaceBorder),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: logicalSize.width - 44,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final exercise in snapshot.exercises)
                              _ExerciseBlock(exercise: exercise),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _Footer(),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: 32,
            height: 32,
            errorBuilder: (_, _, _) => Container(
              width: 32,
              height: 32,
              color: AppColors.primary,
              child: const Icon(
                Icons.fitness_center,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'MASSIVE ARMS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'SESSION',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.snapshot});

  final WorkoutShareSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: formatVolumeKg(snapshot.volumeKg).replaceAll(' kg', ''),
            unit: 'kg',
            label: 'Volume',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            value: snapshot.duration == null
                ? '—'
                : formatDurationShort(snapshot.duration!),
            label: 'Duração',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            value: '${snapshot.exerciseCount}',
            label: snapshot.exerciseCount == 1 ? 'Exercício' : 'Exercícios',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.unit,
  });

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit!,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({required this.exercise});

  final WorkoutShareExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (exercise.hasPr) ...[
                const SizedBox(width: 6),
                const _Chip(label: 'PR', color: AppColors.prGold, compact: true),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final set in exercise.sets)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: set.isPr
                        ? AppColors.prGold.withValues(alpha: 0.16)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: set.isPr
                          ? AppColors.prGold.withValues(alpha: 0.55)
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    set.loadLabel,
                    style: TextStyle(
                      color: set.isPr
                          ? AppColors.prGold
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (exercise.progressLabel != null) ...[
            const SizedBox(height: 5),
            Text(
              exercise.progressKind == ShareProgressKind.weightUp
                  ? '↑ ${exercise.progressLabel}'
                  : '↗ ${exercise.progressLabel}',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Divider(color: AppColors.surfaceBorder, height: 1),
        SizedBox(height: 10),
        Text(
          'massive arms and shoulders',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Wellysson N Rocha  ·  dev',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
