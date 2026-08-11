import '../../data/models/enums.dart';

String greetingForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }
  if (m > 0) {
    return '${m}min ${s.toString().padLeft(2, '0')}s';
  }
  return '${s}s';
}

String formatTimer(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final h = d.inHours;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }
  return '$m:$s';
}

String formatWeight(double? weight) {
  if (weight == null) return '—';
  if (weight == weight.roundToDouble()) {
    return '${weight.toInt()} kg';
  }
  return '${weight.toStringAsFixed(1)} kg';
}

String progressionMessage({
  required int? previousReps,
  required int? currentReps,
  required double? previousWeight,
  required double? currentWeight,
  required int targetRepMax,
}) {
  if (previousReps == null || currentReps == null) {
    return '';
  }

  if (previousWeight != null &&
      currentWeight != null &&
      currentWeight > previousWeight) {
    return 'Carga aumentada em relação ao último treino.';
  }

  if (previousWeight == currentWeight ||
      (previousWeight != null &&
          currentWeight != null &&
          previousWeight == currentWeight)) {
    final diff = currentReps - previousReps;
    if (diff > 0) {
      return 'Boa evolução: +$diff repetição${diff > 1 ? 's' : ''}';
    }
  }

  if (currentReps >= targetRepMax) {
    return 'Você atingiu o topo da faixa.';
  }

  return '';
}

String weightSuggestion({
  required int? reps,
  required int targetRepMax,
}) {
  if (reps != null && reps >= targetRepMax) {
    return 'Considere um pequeno aumento de carga no próximo treino.';
  }
  return '';
}

String weekdayWorkoutLabel(Weekday day, String name) {
  return '${day.labelUpper} — $name'.toUpperCase();
}
