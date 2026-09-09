/// IDs e URIs do Spotify App Remote.
///
/// O Client ID pode vir de `--dart-define=SPOTIFY_CLIENT_ID=...` ou ser
/// colado no Perfil. A Redirect URI precisa estar igual no Dashboard:
/// `massivearms://callback`.
abstract final class SpotifyConfig {
  static const clientIdFromDefine = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  static const redirectUrl = 'massivearms://callback';
  static const androidApplicationId = 'space.manus.massive.arms.t20260324141650';

  /// Sem espaço depois da vírgula: o SDK nativo faz split cru.
  static const oauthScopes =
      'app-remote-control,user-modify-playback-state,user-read-playback-state,user-read-currently-playing,playlist-read-private';

  static String resolveClientId(String? stored) {
    final fromPrefs = stored?.trim() ?? '';
    if (fromPrefs.isNotEmpty) return fromPrefs;
    return clientIdFromDefine.trim();
  }
}
