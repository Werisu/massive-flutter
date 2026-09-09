import '../models/enums.dart';
import '../models/workout_session.dart';
import '../seed/protocol_data.dart';

/// Sequência de dias de treino. Day off do protocolo não quebra a conta.
abstract final class WorkoutStreak {
  static int current(
    List<WorkoutSession> sessions, {
    DateTime? now,
    Set<Weekday>? dayOffWeekdays,
  }) {
    final offs = dayOffWeekdays ??
        ProtocolData.plans
            .where((p) => p.isDayOff)
            .map((p) => p.weekday)
            .toSet();

    final trained = <DateTime>{};
    for (final session in sessions) {
      if (!session.isFinished) continue;
      trained.add(_dateOnly(session.startedAt));
    }
    if (trained.isEmpty) return 0;

    var cursor = _dateOnly(now ?? DateTime.now());
    if (!trained.contains(cursor) &&
        !offs.contains(Weekday.fromDateTime(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (true) {
      if (trained.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (offs.contains(Weekday.fromDateTime(cursor))) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
