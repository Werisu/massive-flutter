import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

class MassiveApp extends ConsumerWidget {
  const MassiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ativa bootstrap de sync automático (auth → sync se stale)
    ref.watch(autoSyncBootstrapProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Massive Arms',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.background,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
