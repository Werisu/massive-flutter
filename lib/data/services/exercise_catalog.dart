import '../models/exercise.dart';
import '../seed/protocol_data.dart';

/// Catálogo do protocolo + exercícios criados pelo usuário.
abstract final class ExerciseCatalog {
  static const customPrefix = 'custom_';

  static List<Exercise> _custom = const [];

  static void setCustom(List<Exercise> exercises) {
    _custom = List<Exercise>.unmodifiable(exercises);
  }

  static List<Exercise> get custom => _custom;

  static bool isCustom(String id) => id.startsWith(customPrefix);

  static Exercise? byId(String id) {
    final builtIn = ProtocolData.exerciseById(id);
    if (builtIn != null) return builtIn;
    for (final exercise in _custom) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  static String nameOf(String id) => byId(id)?.name ?? id;

  static List<Exercise> get all => [...ProtocolData.catalog, ..._custom];

  static Exercise? findByName(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final exercise in all) {
      if (exercise.name.toLowerCase() == needle) return exercise;
    }
    return null;
  }
}
