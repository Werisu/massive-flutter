import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/spotify_pump_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import 'spotify_vinyl_disc.dart';

/// Banner do Início: disco girando + faixa quando o Spotify está no ar.
class SpotifyNowPlayingBanner extends ConsumerWidget {
  const SpotifyNowPlayingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pump = ref.watch(spotifyPumpProvider);
    if (!pump.connected || !pump.hasTrack) {
      return const SizedBox.shrink();
    }

    final playing = !pump.isPaused;
    final notifier = ref.read(spotifyPumpProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        highlighted: playing,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            SpotifyVinylDisc(
              artwork: pump.artwork,
              spinning: playing,
              size: 76,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playing ? 'NO AR' : 'PAUSADO',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: playing
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pump.trackName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (pump.artistName != null &&
                      pump.artistName!.trim().isNotEmpty)
                    Text(
                      pump.artistName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: playing ? 'Pausar' : 'Tocar',
              onPressed: notifier.togglePlay,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.primaryLight,
              ),
            ),
            IconButton(
              tooltip: 'Próxima',
              onPressed: notifier.skipNext,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
