/// Segmento de um bloco de cardio na esteira.
enum HiitSegmentKind { warmup, work, recover, cooldown, steady }

enum HiitMode {
  /// Caminhada rápida no plano — baixo interferência com hipertrofia.
  briskWalk,

  /// HIIT curto (15 min) pós-musculação, só com pernas recuperadas.
  hiitShort,

  /// HIIT de qualidade no Day Off, pernas frescas.
  hiitQuality,

  /// Caminhada leve opcional (domingo).
  easyWalk,
}

class HiitSegment {
  const HiitSegment({
    required this.duration,
    required this.speedMinKmh,
    required this.speedMaxKmh,
    required this.kind,
    required this.label,
    this.inclineMinPct,
    this.inclineMaxPct,
  });

  final Duration duration;
  final double speedMinKmh;
  final double speedMaxKmh;
  final double? inclineMinPct;
  final double? inclineMaxPct;
  final HiitSegmentKind kind;
  final String label;

  bool get hasIncline => inclineMinPct != null || inclineMaxPct != null;

  String get speedLabel {
    if (speedMinKmh == speedMaxKmh) {
      return '${_fmt(speedMinKmh)} km/h';
    }
    return '${_fmt(speedMinKmh)}–${_fmt(speedMaxKmh)} km/h';
  }

  String? get inclineLabel {
    final min = inclineMinPct;
    final max = inclineMaxPct;
    if (min == null && max == null) return null;
    final a = min ?? max!;
    final b = max ?? min!;
    if (a == b) return '${_fmt(a)}%';
    return '${_fmt(a)}–${_fmt(b)}%';
  }

  String get treadmillCue {
    final incline = inclineLabel;
    if (incline == null) return speedLabel;
    return '$speedLabel · $incline';
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class HiitProtocol {
  const HiitProtocol({
    required this.id,
    required this.name,
    required this.mode,
    required this.rationale,
    required this.cue,
    required this.segments,
    this.isOptional = false,
  });

  final String id;
  final String name;
  final HiitMode mode;
  final String rationale;
  final String cue;
  final List<HiitSegment> segments;
  final bool isOptional;

  Duration get totalDuration => segments.fold(
        Duration.zero,
        (sum, s) => sum + s.duration,
      );

  int get workRounds =>
      segments.where((s) => s.kind == HiitSegmentKind.work).length;

  int get totalMinutes => (totalDuration.inSeconds / 60).round();

  String get shortLabel {
    final min = totalMinutes;
    switch (mode) {
      case HiitMode.briskWalk:
        return 'Caminhada $min min';
      case HiitMode.hiitShort:
        return 'HIIT $min min';
      case HiitMode.hiitQuality:
        return 'HIIT $min min';
      case HiitMode.easyWalk:
        return 'Caminhada $min min';
    }
  }

  bool get allowsBriskFallback =>
      mode == HiitMode.hiitShort || mode == HiitMode.hiitQuality;
}

class HiitCompletionState {
  const HiitCompletionState({
    this.lastCompletedDate,
    this.lastProtocolId,
  });

  /// Data local `yyyy-MM-dd`.
  final String? lastCompletedDate;
  final String? lastProtocolId;

  bool completedOn(DateTime day) => lastCompletedDate == dateKey(day);

  HiitCompletionState copyWith({
    String? lastCompletedDate,
    String? lastProtocolId,
  }) {
    return HiitCompletionState(
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      lastProtocolId: lastProtocolId ?? this.lastProtocolId,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastCompletedDate': lastCompletedDate,
        'lastProtocolId': lastProtocolId,
      };

  factory HiitCompletionState.fromJson(Map<String, dynamic> json) =>
      HiitCompletionState(
        lastCompletedDate: json['lastCompletedDate'] as String?,
        lastProtocolId: json['lastProtocolId'] as String?,
      );

  static String dateKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
