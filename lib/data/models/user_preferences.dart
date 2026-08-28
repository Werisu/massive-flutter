import 'exercise.dart';

class UserPreferences {
  const UserPreferences({
    this.userName = 'Atleta',
    this.restMinutesWorking = 3,
    this.restMinutesPrep = 1,
    this.weightKg,
    this.heightCm,
    this.age,
    this.firebaseUid,
    this.cloudSyncEnabled = true,
    this.lastSyncedAt,
    this.keepAliveEnabled = true,
    this.exerciseSubstitutions = const {},
    this.customExercises = const [],
  });

  final String userName;
  final int restMinutesWorking;
  final int restMinutesPrep;
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final String? firebaseUid;
  final bool cloudSyncEnabled;
  final DateTime? lastSyncedAt;
  final bool keepAliveEnabled;

  /// Slot do plano (`WorkoutExercise.id`) → exercício substituto.
  final Map<String, String> exerciseSubstitutions;

  /// Exercícios criados pelo usuário para substituição.
  final List<Exercise> customExercises;

  UserPreferences copyWith({
    String? userName,
    int? restMinutesWorking,
    int? restMinutesPrep,
    double? weightKg,
    double? heightCm,
    int? age,
    String? firebaseUid,
    bool? cloudSyncEnabled,
    DateTime? lastSyncedAt,
    bool? keepAliveEnabled,
    Map<String, String>? exerciseSubstitutions,
    List<Exercise>? customExercises,
  }) {
    return UserPreferences(
      userName: userName ?? this.userName,
      restMinutesWorking: restMinutesWorking ?? this.restMinutesWorking,
      restMinutesPrep: restMinutesPrep ?? this.restMinutesPrep,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
      exerciseSubstitutions:
          exerciseSubstitutions ?? this.exerciseSubstitutions,
      customExercises: customExercises ?? this.customExercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'restMinutesWorking': restMinutesWorking,
        'restMinutesPrep': restMinutesPrep,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'age': age,
        'firebaseUid': firebaseUid,
        'cloudSyncEnabled': cloudSyncEnabled,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'keepAliveEnabled': keepAliveEnabled,
        'exerciseSubstitutions': exerciseSubstitutions,
        'customExercises': customExercises.map((e) => e.toJson()).toList(),
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final raw = json['exerciseSubstitutions'];
    final substitutions = <String, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        substitutions['${entry.key}'] = '${entry.value}';
      }
    }

    final custom = <Exercise>[];
    final rawCustom = json['customExercises'];
    if (rawCustom is List) {
      for (final item in rawCustom) {
        if (item is! Map) continue;
        try {
          custom.add(Exercise.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }

    return UserPreferences(
      userName: json['userName'] as String? ?? 'Atleta',
      restMinutesWorking: json['restMinutesWorking'] as int? ?? 3,
      restMinutesPrep: json['restMinutesPrep'] as int? ?? 1,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      age: json['age'] as int?,
      firebaseUid: json['firebaseUid'] as String?,
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? true,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      keepAliveEnabled: json['keepAliveEnabled'] as bool? ?? true,
      exerciseSubstitutions: substitutions,
      customExercises: custom,
    );
  }
}
