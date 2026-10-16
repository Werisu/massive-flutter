import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/spotify_pump_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'pump_trainer_sticker.dart';
import 'spotify_vinyl_disc.dart';

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
    final subtitle =
        pump.artistName ??
        (pump.connected
            ? 'No ponto'
            : notifier.isConfigured
            ? 'Toque para conectar'
            : 'Abre no app do Spotify');

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 84,
        child: Stack(
          children: [
            const Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: PumpTrainerSticker(height: 84, showLabel: false),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm, right: 62),
              child: Row(
                children: [
                  SpotifyVinylDisc(
                    artwork: pump.artwork,
                    spinning: pump.connected && !pump.isPaused,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                    _BarButton(
                      tooltip: 'Anterior',
                      onPressed: notifier.skipPrevious,
                      icon: Icons.skip_previous_rounded,
                    ),
                    _BarButton(
                      tooltip: pump.isPaused ? 'Tocar' : 'Pausar',
                      onPressed: notifier.togglePlay,
                      icon: pump.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    _BarButton(
                      tooltip: 'Próxima',
                      onPressed: notifier.skipNext,
                      icon: Icons.skip_next_rounded,
                    ),
                  ] else
                    _BarButton(
                      tooltip: notifier.isConfigured ? 'Conectar' : 'Abrir mix',
                      onPressed: () {
                        if (notifier.isConfigured) {
                          notifier.connect(startMix: true);
                        } else {
                          notifier.playMix();
                        }
                      },
                      icon: notifier.isConfigured
                          ? Icons.headphones
                          : Icons.open_in_new,
                      color: AppColors.primaryLight,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.color,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      icon: Icon(icon, color: color, size: 22),
    );
  }
}
