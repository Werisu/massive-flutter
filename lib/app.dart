import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';

class MassiveApp extends ConsumerStatefulWidget {
  const MassiveApp({super.key});

  @override
  ConsumerState<MassiveApp> createState() => _MassiveAppState();
}

class _MassiveAppState extends ConsumerState<MassiveApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (_showSplash) const _AppSplash(),
            ],
          ),
        );
      },
    );
  }
}

class _AppSplash extends StatelessWidget {
  const _AppSplash();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Image.asset(
                'assets/branding/app_icon.png',
                width: 128,
                height: 128,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
