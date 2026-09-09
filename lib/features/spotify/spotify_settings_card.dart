import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/keep_alive_service.dart';
import '../../core/services/spotify_pump_service.dart';
import '../../core/spotify/spotify_config.dart';
import '../../core/spotify/spotify_resource.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';

class SpotifySettingsCard extends ConsumerStatefulWidget {
  const SpotifySettingsCard({super.key});

  @override
  ConsumerState<SpotifySettingsCard> createState() =>
      _SpotifySettingsCardState();
}

class _SpotifySettingsCardState extends ConsumerState<SpotifySettingsCard> {
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _playlistCtrl;
  String? _sha1;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    _clientIdCtrl = TextEditingController(text: prefs.spotifyClientId);
    _playlistCtrl = TextEditingController(
      text: prefs.spotifyPlaylistUri.isEmpty
          ? ''
          : (prefs.spotifyPlaylistName.isNotEmpty
              ? prefs.spotifyPlaylistName
              : prefs.spotifyPlaylistUri),
    );
    KeepAliveService.instance.signingSha1().then((value) {
      if (mounted) setState(() => _sha1 = value);
    });
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _playlistCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePlaylist(SpotifyResource mix) async {
    await ref.read(preferencesProvider.notifier).updateSpotify(
          playlistUri: mix.uri,
          playlistName: mix.name ?? mix.id,
        );
    _playlistCtrl.text = mix.name ?? mix.uri;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final pump = ref.watch(spotifyPumpProvider);
    final clientId = SpotifyConfig.resolveClientId(prefs.spotifyClientId);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: AppColors.primaryLight),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Spotify · pump do treino',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (pump.connected)
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Controle a faixa no descanso sem desbloquear o celular. '
            'Série valendo concluída pode pular pra próxima música. '
            'O login só aparece na primeira vez; depois o app reconecta sozinho.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Playlist de pump',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: workoutMixPresets.map((mix) {
              final selected = prefs.spotifyPlaylistUri == mix.uri;
              return ChoiceChip(
                label: Text(mix.name ?? mix.id),
                selected: selected,
                onSelected: (_) => _savePlaylist(mix),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _playlistCtrl,
            decoration: const InputDecoration(
              hintText: 'Ou cola o link da sua playlist',
            ),
            onSubmitted: (value) async {
              final parsed = parseSpotifyInput(value);
              if (parsed == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Isso não parece um link do Spotify.')),
                );
                return;
              }
              await _savePlaylist(parsed);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tocar ao começar o treino'),
            subtitle: const Text('Abre a mix com shuffle.'),
            value: prefs.spotifyAutoplay,
            onChanged: (v) =>
                ref.read(preferencesProvider.notifier).updateSpotify(autoplay: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Faixa nova no descanso'),
            subtitle: const Text(
              'Ao fechar uma série valendo (ou um tiro de HIIT), pula a música.',
            ),
            value: prefs.spotifySkipOnSet,
            onChanged: (v) =>
                ref.read(preferencesProvider.notifier).updateSpotify(skipOnSet: v),
          ),
          const SizedBox(height: AppSpacing.md),
          if (spotifyRemoteSupported) ...[
            if (clientId.isEmpty) ...[
              Text(
                'Para controlar o player daqui, crie um app em '
                'developer.spotify.com/dashboard e cole o Client ID. '
                'Redirect URI: ${SpotifyConfig.redirectUrl}\n'
                'Pacote Android: ${SpotifyConfig.androidApplicationId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _clientIdCtrl,
                decoration: const InputDecoration(
                  hintText: 'Client ID do Dashboard',
                ),
                onSubmitted: (value) async {
                  await ref
                      .read(preferencesProvider.notifier)
                      .updateSpotify(clientId: value.trim());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Salvar Client ID',
                onPressed: () async {
                  await ref
                      .read(preferencesProvider.notifier)
                      .updateSpotify(clientId: _clientIdCtrl.text.trim());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client ID salvo.')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Abrir mix no Spotify',
                icon: Icons.open_in_new,
                onPressed: () {
                  ref.read(spotifyPumpProvider.notifier).playMix();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: SpotifyConfig.androidApplicationId),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pacote copiado. Cole no Dashboard.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar pacote Android'),
              ),
              if (_sha1 != null)
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _sha1!));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SHA-1 copiado. Cole em Android / fingerprints.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar SHA-1 deste APK'),
                ),
            ] else ...[
              if (pump.error != null) ...[
                Text(
                  pump.error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                'No Dashboard, em Android, o pacote e o SHA-1 deste APK '
                'precisam estar cadastrados. Redirect URI: '
                '${SpotifyConfig.redirectUrl}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_sha1 != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _sha1!));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SHA-1 copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar SHA-1 deste APK'),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: pump.connected
                    ? 'Desconectar Spotify'
                    : pump.connecting
                        ? 'Conectando…'
                        : prefs.spotifyLinked
                            ? 'Reconectar Spotify'
                            : 'Conectar Spotify',
                icon: Icons.headphones,
                isLoading: pump.connecting,
                onPressed: pump.connecting
                    ? null
                    : () {
                        if (pump.connected) {
                          ref.read(spotifyPumpProvider.notifier).disconnect();
                        } else {
                          ref.read(spotifyPumpProvider.notifier).connect();
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: prefs.spotifyPlaylistUri.isEmpty
                    ? 'Abrir Spotify'
                    : 'Tocar mix agora',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  ref.read(spotifyPumpProvider.notifier).playMix();
                },
              ),
            ],
          ] else
            Text(
              'No celular: conecta o app do Spotify e controla o pump daqui. '
              'Enquanto isso, dá pra escolher a playlist.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
