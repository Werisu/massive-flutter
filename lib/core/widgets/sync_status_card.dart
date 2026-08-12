import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'common_widgets.dart';

/// Banner de status de sincronização (Home / Perfil).
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final prefs = ref.watch(preferencesProvider);
    final syncAsync = ref.watch(syncStatusProvider);
    final ui = ref.watch(syncUiProvider);
    final isSyncing = syncAsync.isLoading || ui.isSyncing;

    if (user == null) {
      return AppCard(
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entre com Google',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Para puxar seu histórico e manter os treinos sincronizados.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Entrar com Google',
              icon: Icons.login,
              onPressed: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signInWithGoogleAndSync();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login e sincronização concluídos.'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Falha no login: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    final last = ui.lastResult;
    final lastSynced = prefs.lastSyncedAt;
    final statusColor = isSyncing
        ? AppColors.primaryLight
        : (last?.success == false
            ? AppColors.error
            : AppColors.success);
    final statusIcon = isSyncing
        ? Icons.cloud_sync_outlined
        : (last?.success == false
            ? Icons.cloud_off_outlined
            : Icons.cloud_done_outlined);

    String subtitle;
    if (isSyncing) {
      subtitle = 'Sincronizando com a nuvem…';
    } else if (last?.success == false) {
      subtitle = last?.error ?? 'Falha na sincronização';
    } else if (lastSynced != null) {
      final imported = last?.newlyImported;
      final total = last?.importedSessions;
      final time = DateFormat('dd/MM HH:mm').format(lastSynced);
      if (imported != null && imported > 0) {
        subtitle =
            'Último sync $time · +$imported novos'
            '${total != null ? ' ($total na nuvem)' : ''}';
      } else if (total != null && total > 0) {
        subtitle = 'Último sync $time · $total treinos na nuvem';
      } else {
        subtitle = 'Último sync $time · ${user.email ?? user.displayName ?? ''}';
      }
    } else {
      subtitle = 'Conectado · toque para sincronizar agora';
    }

    return AppCard(
      onTap: isSyncing
          ? null
          : () async {
              final result =
                  await ref.read(syncStatusProvider.notifier).syncNow();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.success
                        ? 'Sync ok: +${result.newlyImported} novos · '
                            '${result.importedSessions} na nuvem'
                        : 'Falha: ${result.error}',
                  ),
                  backgroundColor:
                      result.success ? null : AppColors.error,
                ),
              );
            },
      child: Row(
        children: [
          if (isSyncing)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(statusIcon, color: statusColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSyncing
                      ? 'Sincronizando'
                      : (last?.success == false
                          ? 'Sync com erro'
                          : 'Conta sincronizada'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Conta'),
          ),
        ],
      ),
    );
  }
}
