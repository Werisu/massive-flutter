/// URLs de vídeo reais do PDF/projeto.
///
/// Não inventar links. Quando houver URL oficial, cadastrar aqui pelo `exerciseId`.
abstract final class ExerciseMedia {
  static const Map<String, String> videoUrls = <String, String>{
    // Exemplo (não usar sem URL real do protocolo):
    // 'ex_scott_maquina': 'https://...',
  };

  static const Map<String, String> thumbnailUrls = <String, String>{};

  static String? videoUrlFor(String exerciseId) {
    final url = videoUrls[exerciseId];
    if (url == null || url.isEmpty) return null;
    return url;
  }

  static String? thumbnailUrlFor(String exerciseId) {
    final url = thumbnailUrls[exerciseId];
    if (url == null || url.isEmpty) return null;
    return url;
  }
}
