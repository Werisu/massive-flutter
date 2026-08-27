import '../models/enums.dart';
import '../models/exercise.dart';

/// Variações de equipamento para substituir um exercício do protocolo
/// sem alterar séries/reps do slot.
///
/// Não entram no plano semanal. O movimento original continua sendo a fonte.
abstract final class ExerciseSubstitutions {
  static const List<Exercise> alternatives = [
    Exercise(
      id: 'alt_martelo_polia',
      name: 'Martelo na Polia',
      muscleGroup: MuscleGroup.biceps,
      description: 'Mesmo movimento do martelo, na polia (barra V, corda ou unilateral).',
    ),
    Exercise(
      id: 'alt_rosca_halteres',
      name: 'Rosca com Halteres',
      muscleGroup: MuscleGroup.biceps,
    ),
    Exercise(
      id: 'alt_rosca_direta',
      name: 'Rosca Direta na Barra',
      muscleGroup: MuscleGroup.biceps,
    ),
    Exercise(
      id: 'alt_scott_polia',
      name: 'Scott na Polia',
      muscleGroup: MuscleGroup.biceps,
    ),
    Exercise(
      id: 'alt_triceps_corda',
      name: 'Tríceps Corda',
      muscleGroup: MuscleGroup.triceps,
    ),
    Exercise(
      id: 'alt_triceps_testa',
      name: 'Tríceps Testa',
      muscleGroup: MuscleGroup.triceps,
    ),
    Exercise(
      id: 'alt_frances_halteres',
      name: 'Francês com Halteres',
      muscleGroup: MuscleGroup.triceps,
    ),
    Exercise(
      id: 'alt_elev_lateral_polia',
      name: 'Elevação Lateral na Polia',
      muscleGroup: MuscleGroup.shoulders,
    ),
    Exercise(
      id: 'alt_elev_lateral_halteres',
      name: 'Elevação Lateral com Halteres',
      muscleGroup: MuscleGroup.shoulders,
    ),
    Exercise(
      id: 'alt_crucifixo_halteres',
      name: 'Crucifixo com Halteres',
      muscleGroup: MuscleGroup.chest,
    ),
    Exercise(
      id: 'alt_puxada_neutra',
      name: 'Puxada Pegada Neutra',
      muscleGroup: MuscleGroup.back,
    ),
    Exercise(
      id: 'alt_remada_unilateral',
      name: 'Remada Unilateral',
      muscleGroup: MuscleGroup.back,
    ),
    Exercise(
      id: 'alt_stiff_halteres',
      name: 'Stiff com Halteres',
      muscleGroup: MuscleGroup.legs,
    ),
    Exercise(
      id: 'alt_extensora_bilateral',
      name: 'Cadeira Extensora',
      muscleGroup: MuscleGroup.legs,
    ),
  ];

  /// Trocas de equipamento mais naturais para cada exercício do protocolo.
  static const Map<String, List<String>> suggestedByExerciseId = {
    'ex_martelo': ['alt_martelo_polia'],
    'ex_rosca_polia_uni': ['alt_rosca_halteres', 'alt_rosca_direta'],
    'ex_scott_maquina': ['alt_scott_polia', 'alt_rosca_direta'],
    'ex_rosca_banco_inclinado': ['alt_rosca_halteres'],
    'ex_triceps_barra_v': ['alt_triceps_corda', 'alt_triceps_testa'],
    'ex_triceps_polia_caneleira': ['alt_triceps_corda'],
    'ex_triceps_cabo': ['alt_triceps_corda', 'alt_triceps_testa'],
    'ex_frances_polia': ['alt_frances_halteres'],
    'ex_elev_lateral_tras': [
      'alt_elev_lateral_polia',
      'alt_elev_lateral_halteres',
    ],
    'ex_elev_lateral_peito': [
      'alt_elev_lateral_polia',
      'alt_elev_lateral_halteres',
    ],
    'ex_peck_deck': ['alt_crucifixo_halteres'],
    'ex_puxada_pronada_media': ['alt_puxada_neutra'],
    'ex_puxada_unilateral': ['alt_puxada_neutra', 'alt_remada_unilateral'],
    'ex_remada_pronada': ['alt_remada_unilateral'],
    'ex_remada_supinada': ['alt_remada_unilateral'],
    'ex_stiff_barra': ['alt_stiff_halteres'],
    'ex_extensora_uni': ['alt_extensora_bilateral'],
  };

  static bool isAlternative(String id) =>
      alternatives.any((e) => e.id == id);

  static bool isSuggested({
    required String protocolExerciseId,
    required String candidateId,
  }) {
    return suggestedByExerciseId[protocolExerciseId]?.contains(candidateId) ??
        false;
  }
}
