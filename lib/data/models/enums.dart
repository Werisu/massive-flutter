enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get labelPt {
    switch (this) {
      case Weekday.monday:
        return 'Segunda';
      case Weekday.tuesday:
        return 'Terça';
      case Weekday.wednesday:
        return 'Quarta';
      case Weekday.thursday:
        return 'Quinta';
      case Weekday.friday:
        return 'Sexta';
      case Weekday.saturday:
        return 'Sábado';
      case Weekday.sunday:
        return 'Domingo';
    }
  }

  String get labelUpper {
    return labelPt.toUpperCase();
  }

  /// Dart DateTime.weekday: Monday = 1 ... Sunday = 7
  int get dateTimeWeekday => index + 1;

  static Weekday fromDateTime(DateTime date) {
    return Weekday.values[date.weekday - 1];
  }
}

enum MuscleGroup {
  biceps,
  triceps,
  shoulders,
  chest,
  back,
  legs,
  abs,
  calves,
  forearms;

  String get labelPt {
    switch (this) {
      case MuscleGroup.biceps:
        return 'Bíceps';
      case MuscleGroup.triceps:
        return 'Tríceps';
      case MuscleGroup.shoulders:
        return 'Ombros';
      case MuscleGroup.chest:
        return 'Peito';
      case MuscleGroup.back:
        return 'Costas';
      case MuscleGroup.legs:
        return 'Pernas';
      case MuscleGroup.abs:
        return 'Abdômen';
      case MuscleGroup.calves:
        return 'Panturrilha';
      case MuscleGroup.forearms:
        return 'Antebraço';
    }
  }
}

enum SetType {
  warmup,
  preparation,
  working;

  String get labelPt {
    switch (this) {
      case SetType.warmup:
        return 'Aquecimento';
      case SetType.preparation:
        return 'Preparatória';
      case SetType.working:
        return 'Valendo';
    }
  }

  /// Rest guidance from protocol
  Duration get defaultRest {
    switch (this) {
      case SetType.warmup:
      case SetType.preparation:
        return const Duration(minutes: 1);
      case SetType.working:
        return const Duration(minutes: 3);
    }
  }
}
