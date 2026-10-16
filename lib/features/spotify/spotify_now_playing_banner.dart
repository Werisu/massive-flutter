import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/spotify_pump_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import 'pump_trainer_sticker.dart';
import 'spotify_vinyl_disc.dart';

/// Banner do Início: faixa no ar e o garoto treinando ao lado.
class SpotifyNowPlayingBanner extends ConsumerWidget {
  const SpotifyNowPlayingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pump = ref.watch(spotifyPumpProvider);
    final prefs = ref.watch(preferencesProvider);
    final hasMix = prefs.spotifyPlaylistUri.isNotEmpty;
    if (!pump.connected && !pump.hasTrack && !hasMix && !prefs.spotifyLinked) {
      return const SizedBox.shrink();
    }

    final playing = pump.connected && !pump.isPaused;
    final notifier = ref.read(spotifyPumpProvider.notifier);
    final title = pump.hasTrack
        ? pump.trackName!
        : prefs.spotifyPlaylistName.isNotEmpty
        ? prefs.spotifyPlaylistName
        : 'Pump do treino';
    final artist = pump.artistName?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        highlighted: playing,
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF123524), Color(0xFF241447), AppColors.surface],
            ),
          ),
          child: SizedBox(
            height: 148,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SpotifyVinylDisc(
                              artwork: pump.artwork,
                              spinning: playing,
                              size: 58,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playing
                                        ? 'NO AR'
                                        : pump.connected
                                        ? 'PAUSADO'
                                        : 'SPOTIFY',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: playing
                                              ? const Color(0xFF1DB954)
                                              : AppColors.primaryLight,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.4,
                                        ),
                                  ),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  if (artist != null && artist.isNotEmpty)
                                    Text(
                                      artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (pump.connected) ...[
                              IconButton(
                                tooltip: playing ? 'Pausar' : 'Tocar',
                                onPressed: notifier.togglePlay,
                                icon: Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Próxima',
                                onPressed: notifier.skipNext,
                                icon: const Icon(Icons.skip_next_rounded),
                              ),
                            ] else
                              TextButton.icon(
                                onPressed: () {
                                  if (notifier.isConfigured) {
                                    notifier.connect(startMix: true);
                                  } else {
                                    notifier.playMix();
                                  }
                                },
                                icon: Icon(
                                  notifier.isConfigured
                                      ? Icons.headphones
                                      : Icons.play_arrow_rounded,
                                ),
                                label: Text(
                                  notifier.isConfigured
                                      ? 'Conectar'
                                      : 'Tocar mix',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const PumpTrainerSticker(height: 148),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
