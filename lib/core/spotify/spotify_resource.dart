class SpotifyResource {
  const SpotifyResource({
    required this.uri,
    required this.webUrl,
    this.name,
  });

  /// Ex.: `spotify:playlist:37i9dQZF1DX76Wlfdnj7AP`
  final String uri;
  final String webUrl;
  final String? name;

  String get type {
    final parts = uri.split(':');
    return parts.length >= 2 ? parts[1] : 'playlist';
  }

  String get id {
    final parts = uri.split(':');
    return parts.isEmpty ? '' : parts.last;
  }
}

const workoutMixPresets = <SpotifyResource>[
  SpotifyResource(
    name: 'Beast Mode',
    uri: 'spotify:playlist:37i9dQZF1DX76Wlfdnj7AP',
    webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP',
  ),
  SpotifyResource(
    name: 'RapCaviar',
    uri: 'spotify:playlist:37i9dQZF1DX0XUsuxWHRQd',
    webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd',
  ),
  SpotifyResource(
    name: 'Power Hour',
    uri: 'spotify:playlist:37i9dQZF1DX32NsLKyzScr',
    webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX32NsLKyzScr',
  ),
];

/// Aceita `spotify:...` ou link `open.spotify.com`.
SpotifyResource? parseSpotifyInput(String raw, {String? name}) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  final uriMatch = RegExp(
    r'^spotify:(playlist|album|track|artist):([A-Za-z0-9]+)$',
  ).firstMatch(t);
  if (uriMatch != null) {
    final type = uriMatch.group(1)!;
    final id = uriMatch.group(2)!;
    return SpotifyResource(
      uri: t,
      webUrl: 'https://open.spotify.com/$type/$id',
      name: name,
    );
  }

  final uri = Uri.tryParse(t);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (!host.contains('spotify.com')) return null;

  const types = {'playlist', 'album', 'track', 'artist'};
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  for (var i = 0; i < parts.length - 1; i++) {
    if (!types.contains(parts[i])) continue;
    final type = parts[i];
    final id = parts[i + 1].split('?').first;
    if (id.isEmpty) return null;
    return SpotifyResource(
      uri: 'spotify:$type:$id',
      webUrl: 'https://open.spotify.com/$type/$id',
      name: name,
    );
  }
  return null;
}
