import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'common_widgets.dart';

class WeightInput extends StatelessWidget {
  const WeightInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.label = 'Carga (kg)',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'kg',
      ),
    );
  }
}

class RepsInput extends StatelessWidget {
  const RepsInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.label = 'Reps',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class RirSelector extends StatelessWidget {
  const RirSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  static const options = [0, 1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'RIR',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              tooltip: 'Repetições em reserva',
              onPressed: () => _showInfo(context),
              icon: const Icon(Icons.info_outline, size: 18),
              color: AppColors.textMuted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: options.map((rir) {
            final selected = value == rir;
            final label = rir == 4 ? '4+' : '$rir';
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onChanged(rir),
              selectedColor: AppColors.primary.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repetições em reserva (RIR)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'RIR é a quantidade de repetições que faltariam para chegar à falha.\n\n'
                  'Exemplo: falharia na 10ª, parou na 9ª → RIR = 1.\n\n'
                  'Séries valendo (protocolo):\n'
                  '• Multiarticulares: 0–2 RIR (última série pode chegar à falha)\n'
                  '• Monoarticulares: pode explorar falha nas séries valendo\n\n'
                  'Conteúdo educacional do protocolo — não é aconselhamento médico.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Entendi',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SetTypeBadge extends StatelessWidget {
  const SetTypeBadge({super.key, required this.type});

  final SetType type;

  Color get _color {
    switch (type) {
      case SetType.warmup:
        return AppColors.warmup;
      case SetType.preparation:
        return AppColors.preparation;
      case SetType.working:
        return AppColors.working;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        type.labelPt,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MuscleGroupChip extends StatelessWidget {
  const MuscleGroupChip({
    super.key,
    required this.group,
    this.selected = false,
    this.onTap,
  });

  final MuscleGroup group;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(group.labelPt),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      checkmarkColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryLight : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
