import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/user_preferences.dart';
import '../providers/app_providers.dart';
import '../spotify/spotify_config.dart';
import '../spotify/spotify_resource.dart';

bool get spotifyRemoteSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class SpotifyPumpState {
  const SpotifyPumpState({
    this.connecting = false,
    this.connected = false,
    this.isPaused = true,
    this.trackName,
    this.artistName,
    this.artwork,
    this.error,
  });

  final bool connecting;
  final bool connected;
  final bool isPaused;
  final String? trackName;
  final String? artistName;
  final Uint8List? artwork;
  final String? error;

  bool get hasTrack => trackName != null && trackName!.isNotEmpty;

  SpotifyPumpState copyWith({
    bool? connecting,
    bool? connected,
    bool? isPaused,
    String? trackName,
    String? artistName,
    Uint8List? artwork,
    String? error,
    bool clearError = false,
    bool clearTrack = false,
  }) {
    return SpotifyPumpState(
      connecting: connecting ?? this.connecting,
      connected: connected ?? this.connected,
      isPaused: isPaused ?? this.isPaused,
      trackName: clearTrack ? null : (trackName ?? this.trackName),
      artistName: clearTrack ? null : (artistName ?? this.artistName),
      artwork: clearTrack ? null : (artwork ?? this.artwork),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final spotifyPumpProvider =
    StateNotifierProvider<SpotifyPumpNotifier, SpotifyPumpState>((ref) {
  final notifier = SpotifyPumpNotifier(ref);
  ref.onDispose(notifier.disposeStreams);
  return notifier;
});

class SpotifyPumpNotifier extends StateNotifier<SpotifyPumpState>
    with WidgetsBindingObserver {
  SpotifyPumpNotifier(this._ref) : super(const SpotifyPumpState()) {
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(reconnectSilently);
  }

  static const _tokenTtl = Duration(minutes: 50);

  final Ref _ref;
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<ConnectionStatus>? _connSub;
  String? _lastTrackUri;

  UserPreferences get _prefs => _ref.read(preferencesProvider);

  String get clientId =>
      SpotifyConfig.resolveClientId(_prefs.spotifyClientId);

  bool get isConfigured => clientId.isNotEmpty;

  void disposeStreams() {
    _playerSub?.cancel();
    _connSub?.cancel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeStreams();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      reconnectSilently();
    }
  }

  /// Reconecta o App Remote sem abrir a tela de login.
  Future<void> reconnectSilently() async {
    if (!spotifyRemoteSupported || !isConfigured) return;
    if (!_prefs.spotifyLinked) return;
    if (state.connected || state.connecting) return;
    await _connectInternal(allowAuth: false, startMix: false);
  }

  Future<void> connect({bool startMix = false}) async {
    if (state.connected) {
      if (startMix) await playMix();
      return;
    }
    await _connectInternal(allowAuth: true, startMix: startMix);
  }

  Future<void> _connectInternal({
    required bool allowAuth,
    required bool startMix,
  }) async {
    if (!spotifyRemoteSupported) {
      if (allowAuth) {
        state = state.copyWith(
          error: 'O controle remoto do Spotify só funciona no celular.',
        );
      }
      return;
    }
    if (!isConfigured) {
      if (allowAuth) {
        state = state.copyWith(
          error: 'Cole o Client ID do Spotify no Perfil para conectar de verdade.',
        );
      }
      return;
    }
    if (state.connecting) return;

    state = state.copyWith(
      connecting: true,
      clearError: allowAuth,
    );
    try {
      String? token = _freshToken;
      if (allowAuth && !_prefs.spotifyLinked) {
        token = await _authorize() ?? token;
      }

      var remoteError = await _tryRemote(token);
      if (remoteError != null && token != null) {
        remoteError = await _tryRemote(null);
      }
      if (remoteError != null && allowAuth) {
        token = await _authorize() ?? token;
        remoteError = await _tryRemote(token);
      }

      if (remoteError != null) {
        state = state.copyWith(
          connecting: false,
          connected: false,
          error: allowAuth ? _friendlyError(remoteError) : state.error,
        );
        return;
      }

      await _listenConnection();
      await _listenPlayer();
      await _markLinked(token: token);
      state = state.copyWith(
        connecting: false,
        connected: true,
        clearError: true,
      );
      if (startMix && _savedMix != null) await playMix();
    } catch (e) {
      debugPrint('Spotify connect: $e');
      state = state.copyWith(
        connecting: false,
        connected: false,
        error: allowAuth ? _friendlyError(e) : state.error,
      );
    }
  }

  /// `null` = conectou.
  Future<Object?> _tryRemote(String? token) async {
    try {
      final ok = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: SpotifyConfig.redirectUrl,
        accessToken: token,
      );
      if (ok) return null;
      return 'Não conectou. Confira o app do Spotify e o Client ID.';
    } catch (e) {
      debugPrint('Spotify remote: $e');
      return e;
    }
  }

  String? get _freshToken {
    final token = _prefs.spotifyAccessToken;
    final at = _prefs.spotifyAccessTokenAt;
    if (token.isEmpty || at == null) return null;
    if (DateTime.now().difference(at) > _tokenTtl) return null;
    return token;
  }

  Future<void> _markLinked({String? token}) async {
    await _ref.read(preferencesProvider.notifier).updateSpotify(
          linked: true,
          accessToken: token,
          accessTokenAt: token != null && token.isNotEmpty
              ? DateTime.now()
              : null,
        );
  }

  Future<String?> _authorize() async {
    try {
      final token = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: SpotifyConfig.redirectUrl,
        scope: SpotifyConfig.oauthScopes,
      );
      if (token.isEmpty || token == 'null') return null;
      return token;
    } on PlatformException catch (e) {
      debugPrint(
        'Spotify getAccessToken: code=${e.code} message=${e.message} details=${e.details}',
      );
      if (_isEmptyAuthResult(e)) return null;
      throw e;
    }
  }

  bool _isEmptyAuthResult(PlatformException e) {
    final blob = '${e.code} ${e.message} ${e.details}'.toLowerCase();
    return blob.contains('no implementation found') ||
        blob.contains('missingpluginexception') ||
        blob.contains('notimplemented');
  }

  Future<void> disconnect() async {
    await _playerSub?.cancel();
    _playerSub = null;
    await _connSub?.cancel();
    _connSub = null;
    _lastTrackUri = null;
    try {
      await SpotifySdk.disconnect();
    } catch (_) {}
    await _ref.read(preferencesProvider.notifier).updateSpotify(
          linked: false,
          clearAccessToken: true,
        );
    state = const SpotifyPumpState();
  }

  /// Toca a playlist de treino no Spotify (remoto) ou abre o app.
  Future<void> playMix() async {
    final mix = _savedMix;
    if (mix == null) {
      state = state.copyWith(error: 'Escolha uma playlist de pump no Perfil.');
      return;
    }

    if (!state.connected && _prefs.spotifyLinked) {
      await reconnectSilently();
    }

    if (state.connected) {
      try {
        await SpotifySdk.setShuffle(shuffle: true);
        await SpotifySdk.play(spotifyUri: mix.uri);
        return;
      } catch (e) {
        state = state.copyWith(error: _friendlyError(e));
      }
    }

    await openInSpotify(mix);
  }

  Future<void> openInSpotify(SpotifyResource mix) async {
    final native = Uri.parse(mix.uri);
    try {
      final ok = await launchUrl(native, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    await launchUrl(Uri.parse(mix.webUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> togglePlay() async {
    if (!state.connected) {
      await connect();
      return;
    }
    try {
      if (state.isPaused) {
        await SpotifySdk.resume();
      } else {
        await SpotifySdk.pause();
      }
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  Future<void> skipNext() async {
    if (!state.connected) return;
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  Future<void> skipPrevious() async {
    if (!state.connected) return;
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  /// Chamado ao concluir série valendo / tiro de HIIT.
  Future<void> onHardEffort() async {
    if (!_prefs.spotifySkipOnSet || !state.connected) return;
    await skipNext();
  }

  /// Início de treino/HIIT: reconecta se já vinculado e, se marcado, dispara a mix.
  Future<void> onWorkoutStarted() async {
    if (!spotifyRemoteSupported) return;
    if (isConfigured) {
      await connect(startMix: _prefs.spotifyAutoplay);
      return;
    }
    if (_prefs.spotifyAutoplay) {
      final mix = _savedMix;
      if (mix != null) await openInSpotify(mix);
    }
  }

  SpotifyResource? get _savedMix {
    return parseSpotifyInput(
      _prefs.spotifyPlaylistUri,
      name: _prefs.spotifyPlaylistName,
    );
  }

  Future<void> _listenConnection() async {
    await _connSub?.cancel();
    _connSub = SpotifySdk.subscribeConnectionStatus().listen((status) {
      if (!status.connected && state.connected) {
        state = state.copyWith(connected: false, isPaused: true);
      }
    });
  }

  Future<void> _listenPlayer() async {
    await _playerSub?.cancel();
    _playerSub = SpotifySdk.subscribePlayerState().listen((player) async {
      final track = player.track;
      state = state.copyWith(
        connected: true,
        isPaused: player.isPaused,
        trackName: track?.name,
        artistName: track?.artist.name,
        clearTrack: track == null,
        clearError: true,
      );
      final uri = track?.uri;
      if (uri == null || uri == _lastTrackUri || track == null) return;
      _lastTrackUri = uri;
      try {
        final image = await SpotifySdk.getImage(
          imageUri: track.imageUri,
          dimension: ImageDimension.small,
        );
        if (uri == _lastTrackUri) {
          state = state.copyWith(artwork: image);
        }
      } catch (_) {}
    }, onError: (Object e) {
      state = state.copyWith(error: _friendlyError(e), connected: false);
    });
  }

  String _friendlyError(Object e) {
    if (e is String && e.isNotEmpty) return e;
    if (e is PlatformException) {
      final code = e.code;
      final details = '${e.details ?? ''}'.trim();
      final message = (e.message ?? '').trim();
      final blob = '$code $message $details'.toLowerCase();

      if (blob.contains('usernotauthorized') ||
          blob.contains('explicit user authorization')) {
        return 'O Spotify ainda não autorizou o app. Aceite a tela de permissão '
            'e, no Dashboard, cadastre o SHA-1 do Android (não só a Redirect URI).';
      }
      if (blob.contains('couldnotfindspotifyapp') ||
          blob.contains('not installed')) {
        return 'Instale o app do Spotify neste celular.';
      }
      if (blob.contains('authenticationfailed') ||
          blob.contains('invalid_client')) {
        return 'O Spotify recusou o app. Confira no Dashboard o pacote '
            '${SpotifyConfig.androidApplicationId} e o SHA-1 deste APK '
            '(copie no Perfil). Redirect: ${SpotifyConfig.redirectUrl}';
      }
      if (blob.contains('authenticationtokenerror')) {
        final extra = details.isEmpty ? message : details;
        return extra.isEmpty
            ? 'Spotify recusou o login. Confira SHA-1 e Redirect URI no Dashboard.'
            : 'Spotify recusou o login: $extra';
      }
      if (blob.contains('no implementation found') ||
          blob.contains('notimplemented')) {
        return 'O login não voltou para o app. Tenta de novo; se repetir, '
            'cadastre o SHA-1 deste APK no Dashboard.';
      }
      if (details.isNotEmpty) return 'Spotify: $message ($details)';
      if (message.isNotEmpty) return 'Spotify: $message';
      return 'Spotify: $code';
    }
    return 'Spotify: não rolou desta vez.';
  }
}
