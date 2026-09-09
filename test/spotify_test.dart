import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/spotify/spotify_resource.dart';
import 'package:massive_arms/data/models/user_preferences.dart';

void main() {
  test('parseia URI nativa do Spotify', () {
    final parsed = parseSpotifyInput(
      'spotify:playlist:37i9dQZF1DX76Wlfdnj7AP',
      name: 'Beast Mode',
    );
    expect(parsed?.uri, 'spotify:playlist:37i9dQZF1DX76Wlfdnj7AP');
    expect(parsed?.webUrl, contains('/playlist/37i9dQZF1DX76Wlfdnj7AP'));
    expect(parsed?.name, 'Beast Mode');
  });

  test('parseia link web com query e intl', () {
    final parsed = parseSpotifyInput(
      'https://open.spotify.com/intl-pt/playlist/37i9dQZF1DX0XUsuxWHRQd?si=abc',
    );
    expect(parsed?.uri, 'spotify:playlist:37i9dQZF1DX0XUsuxWHRQd');
    expect(parsed?.type, 'playlist');
  });

  test('rejeita texto que não é Spotify', () {
    expect(parseSpotifyInput('Beast Mode'), isNull);
    expect(parseSpotifyInput(''), isNull);
  });

  test('preferências de Spotify sobrevivem ao JSON', () {
    const prefs = UserPreferences(
      userName: 'Atleta',
      spotifyClientId: 'abc123',
      spotifyPlaylistUri: 'spotify:playlist:37i9dQZF1DX76Wlfdnj7AP',
      spotifyPlaylistName: 'Beast Mode',
      spotifyAutoplay: false,
      spotifySkipOnSet: false,
    );
    final encoded = UserPreferences.fromJson(prefs.toJson());
    expect(encoded.spotifyClientId, 'abc123');
    expect(encoded.spotifyPlaylistName, 'Beast Mode');
    expect(encoded.spotifyAutoplay, isFalse);
    expect(encoded.spotifySkipOnSet, isFalse);
    expect(encoded.spotifyLinked, isFalse);
  });

  test('vínculo do Spotify sobrevive ao JSON local', () {
    final at = DateTime.utc(2026, 9, 9, 12);
    final prefs = UserPreferences(
      userName: 'Atleta',
      spotifyLinked: true,
      spotifyAccessToken: 'tok',
      spotifyAccessTokenAt: at,
    );
    final encoded = UserPreferences.fromJson(prefs.toJson());
    expect(encoded.spotifyLinked, isTrue);
    expect(encoded.spotifyAccessToken, 'tok');
    expect(encoded.spotifyAccessTokenAt, at);
  });

  test('JSON antigo assume autoplay e skip ligados', () {
    final prefs = UserPreferences.fromJson({
      'userName': 'Wellysson',
      'restMinutesWorking': 3,
      'restMinutesPrep': 1,
    });
    expect(prefs.spotifyAutoplay, isTrue);
    expect(prefs.spotifySkipOnSet, isTrue);
    expect(prefs.spotifyPlaylistUri, '');
    expect(prefs.spotifyLinked, isFalse);
    expect(prefs.spotifyAccessToken, '');
  });
}
