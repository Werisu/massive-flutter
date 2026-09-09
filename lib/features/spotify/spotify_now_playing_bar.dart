import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/spotify_pump_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Mini player compacto para o treino — skip sem sair da série.
class SpotifyNowPlayingBar extends ConsumerWidget {
  const SpotifyNowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pump = ref.watch(spotifyPumpProvider);
    final prefs = ref.watch(preferencesProvider);
    final hasMix = prefs.spotifyPlaylistUri.isNotEmpty;
    final mixName = prefs.spotifyPlaylistName;
    final notifier = ref.read(spotifyPumpProvider.notifier);

    if (!spotifyRemoteSupported && !hasMix) {
      return const SizedBox.shrink();
    }

    final title = pump.hasTrack
        ? pump.trackName!
        : mixName.isNotEmpty
            ? mixName
            : 'Spotify';
    final subtitle = pump.artistName ??
        (pump.connected
            ? 'No ponto'
            : notifier.isConfigured
                ? 'Toque para conectar'
                : 'Abre no app do Spotify');

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _Artwork(bytes: pump.artwork),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (pump.connected) ...[
              IconButton(
                tooltip: 'Anterior',
                onPressed: notifier.skipPrevious,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton(
                tooltip: pump.isPaused ? 'Tocar' : 'Pausar',
                onPressed: notifier.togglePlay,
                icon: Icon(
                  pump.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Próxima',
                onPressed: notifier.skipNext,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ] else
              IconButton(
                tooltip: notifier.isConfigured ? 'Conectar' : 'Abrir mix',
                onPressed: () {
                  if (notifier.isConfigured) {
                    notifier.connect(startMix: true);
                  } else {
                    notifier.playMix();
                  }
                },
                icon: Icon(
                  notifier.isConfigured ? Icons.headphones : Icons.open_in_new,
                  color: AppColors.primaryLight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: bytes == null
            ? const ColoredBox(
                color: AppColors.surface,
                child: Icon(Icons.graphic_eq, color: AppColors.primaryLight),
              )
            : Image.memory(bytes!, fit: BoxFit.cover),
      ),
    );
  }
}
