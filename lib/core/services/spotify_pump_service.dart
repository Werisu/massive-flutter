import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class SpotifyPumpNotifier extends StateNotifier<SpotifyPumpState> {
  SpotifyPumpNotifier(this._ref) : super(const SpotifyPumpState());

  final Ref _ref;
  StreamSubscription<PlayerState>? _playerSub;
  String? _lastTrackUri;

  UserPreferences get _prefs => _ref.read(preferencesProvider);

  String get clientId =>
      SpotifyConfig.resolveClientId(_prefs.spotifyClientId);

  bool get isConfigured => clientId.isNotEmpty;

  void disposeStreams() {
    _playerSub?.cancel();
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }

  Future<void> connect({bool startMix = false}) async {
    if (!spotifyRemoteSupported) {
      state = state.copyWith(
        error: 'O controle remoto do Spotify só funciona no celular.',
      );
      return;
    }
    if (!isConfigured) {
      state = state.copyWith(
        error: 'Cole o Client ID do Spotify no Perfil para conectar de verdade.',
      );
      return;
    }

    state = state.copyWith(connecting: true, clearError: true);
    try {
      final token = await _authorize();
      final ok = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: SpotifyConfig.redirectUrl,
        accessToken: token,
      );
      if (!ok) {
        state = state.copyWith(
          connecting: false,
          connected: false,
          error: 'Não conectou. Confira o app do Spotify e o Client ID.',
        );
        return;
      }
      await _listenPlayer();
      state = state.copyWith(connecting: false, connected: true, clearError: true);
      if (startMix && _savedMix != null) await playMix();
    } catch (e) {
      debugPrint('Spotify connect: $e');
      state = state.copyWith(
        connecting: false,
        connected: false,
        error: _friendlyError(e),
      );
    }
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
    _lastTrackUri = null;
    try {
      await SpotifySdk.disconnect();
    } catch (_) {}
    state = const SpotifyPumpState();
  }

  /// Toca a playlist de treino no Spotify (remoto) ou abre o app.
  Future<void> playMix() async {
    final mix = _savedMix;
    if (mix == null) {
      state = state.copyWith(error: 'Escolha uma playlist de pump no Perfil.');
      return;
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

  /// Início de treino/HIIT: conecta e, se marcado, dispara a mix.
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
