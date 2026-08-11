import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _syncing = false;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: ref.read(preferencesProvider).userName,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    try {
      final user =
          await ref.read(authControllerProvider.notifier).signInWithGoogleAndSync();
      if (!mounted) return;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        _nameCtrl.text = user.displayName!;
      }
      final prefs = ref.read(preferencesProvider);
      if (prefs.userName.isNotEmpty) {
        _nameCtrl.text = prefs.userName;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logado como ${user?.email ?? user?.displayName ?? 'Google'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha no login: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão encerrada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sync() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      await _signIn();
      return;
    }

    setState(() => _syncing = true);
    final result = await ref.read(syncStatusProvider.notifier).syncNow();
    if (!mounted) return;
    setState(() => _syncing = false);

    final messenger = ScaffoldMessenger.of(context);
    if (result.success) {
      if (result.profileName != null && result.profileName!.isNotEmpty) {
        _nameCtrl.text = result.profileName!;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Sincronizado: ${result.importedSessions} treinos no Firebase'
            '${result.profileName != null && result.profileName!.isNotEmpty ? ' · ${result.profileName}' : ''}',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Falha na sincronização: ${result.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final syncState = ref.watch(syncStatusProvider);
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;
    final authBusy = ref.watch(authControllerProvider).isLoading;

    ref.listen(preferencesProvider, (_, next) {
      if (_nameCtrl.text != next.userName && next.userName.isNotEmpty) {
        _nameCtrl.text = next.userName;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            highlighted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person,
                              color: AppColors.primaryLight, size: 28)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user != null
                                ? (user.displayName ?? prefs.userName)
                                : 'Não conectado',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ??
                                'Entre com Google para sincronizar treinos',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (user == null)
                  PrimaryButton(
                    label: _signingIn || authBusy
                        ? 'Entrando...'
                        : 'Entrar com Google',
                    icon: Icons.login,
                    isLoading: _signingIn || authBusy,
                    onPressed: _signingIn || authBusy ? null : _signIn,
                  )
                else ...[
                  PrimaryButton(
                    label: _syncing || syncState.isLoading
                        ? 'Sincronizando...'
                        : 'Sincronizar agora',
                    icon: Icons.sync,
                    isLoading: _syncing || syncState.isLoading,
                    onPressed: _syncing ? null : _sync,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Sair da conta',
                    icon: Icons.logout,
                    onPressed: _signOut,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  user != null
                      ? 'Conta conectada\n'
                          'Caminho: users/${user.uid}/data\n'
                          '${prefs.lastSyncedAt != null ? 'Último sync: ${DateFormat('dd/MM/yyyy HH:mm').format(prefs.lastSyncedAt!)}' : 'Toque em sincronizar para importar o histórico'}'
                      : 'O login usa a mesma conta Google do Firebase para manter '
                          'perfil e histórico sincronizados entre dispositivos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seu nome',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Como devemos te chamar?',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Salvar',
                  onPressed: () async {
                    await ref
                        .read(preferencesProvider.notifier)
                        .updateName(_nameCtrl.text);
                    try {
                      final sync = ref.read(firestoreSyncProvider);
                      final u = ref.read(authRepositoryProvider).currentUser;
                      if (u != null) {
                        await sync.saveProfileFromPreferences(
                          ref.read(preferencesProvider),
                          uid: u.uid,
                        );
                      }
                    } catch (_) {}
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preferências salvas.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descanso padrão',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aquecimento/preparatórias: ${prefs.restMinutesPrep} min\n'
                  'Séries valendo: ${prefs.restMinutesWorking} min\n'
                  '(Protocolo: ~1 min prep · 2–5 min valendo)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Valendo (minutos)',
                    style: Theme.of(context).textTheme.bodySmall),
                Slider(
                  value: prefs.restMinutesWorking.toDouble(),
                  min: 2,
                  max: 5,
                  divisions: 3,
                  label: '${prefs.restMinutesWorking} min',
                  onChanged: (v) {
                    ref
                        .read(preferencesProvider.notifier)
                        .updateRest(working: v.round());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () => context.push('/guide'),
            child: const Row(
              children: [
                Icon(Icons.menu_book_outlined, color: AppColors.primaryLight),
                SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Guia do protocolo')),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.push('/history'),
            child: const Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryLight),
                SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Histórico de treinos')),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Massive Arms and Shoulders\nVersão 1.0 · Google + Firebase',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
