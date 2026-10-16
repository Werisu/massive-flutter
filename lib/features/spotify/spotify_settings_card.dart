import 'dart:math' as math;

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
import 'pump_trainer_sticker.dart';

const _spotifyGreen = Color(0xFF1DB954);

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
    await ref
        .read(preferencesProvider.notifier)
        .updateSpotify(playlistUri: mix.uri, playlistName: mix.name ?? mix.id);
    _playlistCtrl.text = mix.name ?? mix.uri;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final pump = ref.watch(spotifyPumpProvider);
    final clientId = SpotifyConfig.resolveClientId(prefs.spotifyClientId);
    final playing = pump.connected && !pump.isPaused;

    return AppCard(
      padding: EdgeInsets.zero,
      highlighted: playing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AccentBar(),
          _Hero(pump: pump, playing: playing),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A mix toca no descanso. Se você ligar, a série valendo '
                  'pula pra próxima faixa. O login só aparece na primeira vez.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Playlist de pump',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final mix in workoutMixPresets)
                      _MixChip(
                        label: mix.name ?? mix.id,
                        selected: prefs.spotifyPlaylistUri == mix.uri,
                        onTap: () => _savePlaylist(mix),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _playlistCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ou cola o link da sua playlist',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  onSubmitted: (value) async {
                    final parsed = parseSpotifyInput(value);
                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Isso não parece um link do Spotify.'),
                        ),
                      );
                      return;
                    }
                    await _savePlaylist(parsed);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        title: const Text('Tocar ao começar o treino'),
                        subtitle: const Text('Abre a mix com shuffle.'),
                        value: prefs.spotifyAutoplay,
                        onChanged: (v) => ref
                            .read(preferencesProvider.notifier)
                            .updateSpotify(autoplay: v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        title: const Text('Pular faixa ao concluir série'),
                        subtitle: const Text(
                          'Série valendo (ou tiro de HIIT) pula pra próxima música.',
                        ),
                        value: prefs.spotifySkipOnSet,
                        onChanged: (v) => ref
                            .read(preferencesProvider.notifier)
                            .updateSpotify(skipOnSet: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _RemoteSection(
                  clientId: clientId,
                  clientIdCtrl: _clientIdCtrl,
                  sha1: _sha1,
                  pump: pump,
                  prefsLinked: prefs.spotifyLinked,
                  hasPlaylist: prefs.spotifyPlaylistUri.isNotEmpty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  const _AccentBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_spotifyGreen, AppColors.primaryLight],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pump, required this.playing});

  final SpotifyPumpState pump;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final status = _status(pump);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth < 340 ? 176.0 : 196.0;
        return SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF123524),
                  Color(0xFF2A1454),
                  AppColors.surface,
                ],
                stops: [0, 0.48, 1],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 36,
                  bottom: 8,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _spotifyGreen.withValues(alpha: 0.16),
                      boxShadow: [
                        BoxShadow(
                          color: _spotifyGreen.withValues(
                            alpha: playing ? 0.45 : 0.2,
                          ),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _spotifyGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.headphones_rounded,
                                    color: Color(0xFF06210F),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SPOTIFY',
                                        style: TextStyle(
                                          color: _spotifyGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.6,
                                        ),
                                      ),
                                      Text(
                                        'Pump do treino',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            _StatusPill(
                              label: status.label,
                              color: status.color,
                              live: playing,
                            ),
                            if (pump.hasTrack) ...[
                              const SizedBox(height: 6),
                              Text(
                                pump.trackName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Controle a faixa sem desbloquear o celular.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PumpTrainerSticker(height: height),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _Status _status(SpotifyPumpState pump) {
    if (playing) {
      return const _Status('No ar', _spotifyGreen);
    }
    if (pump.connected) {
      return const _Status('Pausado', AppColors.warning);
    }
    if (pump.connecting) {
      return const _Status('Conectando', AppColors.primaryLight);
    }
    return const _Status('Desconectado', AppColors.textMuted);
  }
}

class _Status {
  const _Status(this.label, this.color);
  final String label;
  final Color color;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.live,
  });

  final String label;
  final Color color;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              const _LiveBars(),
              const SizedBox(width: 6),
            ] else ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBars extends StatefulWidget {
  const _LiveBars();

  @override
  State<_LiveBars> createState() => _LiveBarsState();
}

class _LiveBarsState extends State<_LiveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bars;

  @override
  void initState() {
    super.initState();
    _bars = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _bars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bars,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  width: 2.5,
                  height:
                      4 +
                      8 *
                          (0.5 +
                                  0.5 *
                                      math.sin(
                                        (_bars.value + i * 0.22) * math.pi * 2,
                                      ))
                              .abs(),
                  decoration: BoxDecoration(
                    color: _spotifyGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MixChip extends StatelessWidget {
  const _MixChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.22)
          : AppColors.surfaceElevated,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primaryLight : AppColors.surfaceBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteSection extends ConsumerWidget {
  const _RemoteSection({
    required this.clientId,
    required this.clientIdCtrl,
    required this.sha1,
    required this.pump,
    required this.prefsLinked,
    required this.hasPlaylist,
  });

  final String clientId;
  final TextEditingController clientIdCtrl;
  final String? sha1;
  final SpotifyPumpState pump;
  final bool prefsLinked;
  final bool hasPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!spotifyRemoteSupported) {
      return Text(
        'No celular: conecta o app do Spotify e controla o pump daqui. '
        'Enquanto isso, dá pra escolher a playlist.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    if (clientId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para controlar o player daqui, crie um app em '
            'developer.spotify.com/dashboard e cole o Client ID. '
            'Redirect URI: ${SpotifyConfig.redirectUrl}\n'
            'Pacote Android: ${SpotifyConfig.androidApplicationId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: clientIdCtrl,
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
                  .updateSpotify(clientId: clientIdCtrl.text.trim());
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Client ID salvo.')));
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
          _CopyPackageButton(),
          if (sha1 != null) _CopyShaButton(sha1: sha1!),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pump.error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              pump.error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        PrimaryButton(
          label: pump.connected
              ? 'Desconectar Spotify'
              : pump.connecting
              ? 'Conectando…'
              : prefsLinked
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
          label: hasPlaylist ? 'Tocar mix agora' : 'Abrir Spotify',
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            ref.read(spotifyPumpProvider.notifier).playMix();
          },
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            iconColor: AppColors.textMuted,
            collapsedIconColor: AppColors.textMuted,
            title: Text(
              'Ajuste do Dashboard',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No Dashboard, em Android, o pacote e o SHA-1 deste APK '
                  'precisam estar cadastrados. Redirect URI: '
                  '${SpotifyConfig.redirectUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: clientIdCtrl,
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
                      .updateSpotify(clientId: clientIdCtrl.text.trim());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client ID salvo.')),
                  );
                },
              ),
              _CopyPackageButton(),
              if (sha1 != null) _CopyShaButton(sha1: sha1!),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyPackageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
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
    );
  }
}

class _CopyShaButton extends StatelessWidget {
  const _CopyShaButton({required this.sha1});

  final String sha1;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: sha1));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SHA-1 copiado. Cole em Android / fingerprints.'),
          ),
        );
      },
      icon: const Icon(Icons.copy, size: 16),
      label: const Text('Copiar SHA-1 deste APK'),
    );
  }
}
