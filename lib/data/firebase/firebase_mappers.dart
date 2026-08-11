import '../../data/models/enums.dart';
import '../../data/seed/protocol_data.dart';

/// Mapeamento do schema legado do Firestore (dayId / exerciseId) → protocolo atual.
abstract final class FirebaseMappers {
  static const dayIdToPlanId = <String, String>{
    'segunda': 'plan_monday',
    'terca': 'plan_tuesday',
    'quarta': 'plan_wednesday',
    'quinta': 'plan_thursday',
    'sexta': 'plan_friday',
    'sabado': 'plan_saturday',
    'domingo': 'plan_sunday',
  };

  static const planIdToDayId = <String, String>{
    'plan_monday': 'segunda',
    'plan_tuesday': 'terca',
    'plan_wednesday': 'quarta',
    'plan_thursday': 'quinta',
    'plan_friday': 'sexta',
    'plan_saturday': 'sabado',
    'plan_sunday': 'domingo',
  };

  static const legacyExerciseToId = <String, String>{
    'seg-1': 'ex_triceps_barra_v',
    'seg-2': 'ex_triceps_polia_caneleira',
    'seg-3': 'ex_posterior_45',
    'seg-4': 'ex_puxada_pronada_media',
    'seg-5': 'ex_puxada_unilateral',
    'seg-6': 'ex_remada_pronada',
    'ter-1': 'ex_pant_leg_press',
    'ter-2': 'ex_mesa_flexora',
    'ter-3': 'ex_agachamento_smith_hack',
    'ter-4': 'ex_stiff_barra',
    'ter-5': 'ex_extensora_uni',
    'ter-6': 'ex_adutora',
    'qua-1': 'ex_martelo',
    'qua-2': 'ex_rosca_polia_uni',
    'qua-3': 'ex_elev_lateral_tras',
    'qua-4': 'ex_supino_inclinado',
    'qua-5': 'ex_paralela_crossover',
    'qua-6': 'ex_peck_deck',
    'qua-7': 'ex_extensao_punho',
    'sex-1': 'ex_triceps_cabo',
    'sex-2': 'ex_frances_polia',
    'sex-3': 'ex_crucifixo_inverso',
    'sex-4': 'ex_remada_supinada',
    'sex-5': 'ex_puxada_super_aberta',
    'sex-6': 'ex_kelso_shrug',
    'sab-1': 'ex_scott_maquina',
    'sab-2': 'ex_rosca_banco_inclinado',
    'sab-3': 'ex_elev_lateral_peito',
    'sab-4': 'ex_desenvolvimento',
    'sab-5': 'ex_supino_reto',
    'sab-6': 'ex_flexao_punho',
    'dom-1': 'ex_abdominal_polia',
    'dom-2': 'ex_abdominal_romano',
    'dom-3': 'ex_pant_leg_press',
  };

  static String? planIdFromDayId(String? dayId) {
    if (dayId == null) return null;
    return dayIdToPlanId[dayId];
  }

  static String? dayIdFromPlanId(String planId) => planIdToDayId[planId];

  static String resolveExerciseId(String? legacyId, String? name) {
    if (legacyId != null && legacyExerciseToId.containsKey(legacyId)) {
      return legacyExerciseToId[legacyId]!;
    }
    if (name != null && name.isNotEmpty) {
      final lower = name.toLowerCase();
      for (final e in ProtocolData.exercises) {
        if (e.name.toLowerCase() == lower) return e.id;
      }
      for (final e in ProtocolData.exercises) {
        if (e.name.toLowerCase().contains(lower) ||
            lower.contains(e.name.toLowerCase())) {
          return e.id;
        }
      }
    }
    return legacyId ?? 'unknown';
  }

  static String dayNameFromWeekday(Weekday day) {
    switch (day) {
      case Weekday.monday:
        return 'Segunda-feira';
      case Weekday.tuesday:
        return 'Terça-feira';
      case Weekday.wednesday:
        return 'Quarta-feira';
      case Weekday.thursday:
        return 'Quinta-feira';
      case Weekday.friday:
        return 'Sexta-feira';
      case Weekday.saturday:
        return 'Sábado';
      case Weekday.sunday:
        return 'Domingo';
    }
  }
}
