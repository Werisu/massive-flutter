import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/routing/app_router.dart';
import 'core/services/keep_alive_service.dart';
import 'core/services/screen_wake_service.dart';
import 'core/services/spotify_pump_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';

class MassiveApp extends ConsumerStatefulWidget {
  const MassiveApp({super.key});

  @override
  ConsumerState<MassiveApp> createState() => _MassiveAppState();
}

class _MassiveAppState extends ConsumerState<MassiveApp>
    with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenWakeService.instance.acquire(ScreenWakeService.appHolder);
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showSplash = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KeepAliveService.instance.setEnabled(
        ref.read(preferencesProvider).keepAliveEnabled,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenWakeService.instance.setInForeground(false);
    ScreenWakeService.instance.release(ScreenWakeService.appHolder);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inForeground = state == AppLifecycleState.resumed;
    if (inForeground ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ScreenWakeService.instance.setInForeground(inForeground);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoSyncBootstrapProvider);
    ref.watch(spotifyPumpProvider.notifier);
    ref.listen<bool>(
      preferencesProvider.select((p) => p.keepAliveEnabled),
      (previous, next) {
        KeepAliveService.instance.setEnabled(next);
      },
    );
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

class _AppSplash extends StatefulWidget {
  const _AppSplash();

  @override
  State<_AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<_AppSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.96 + t * 0.06,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28 + t * 0.22),
                          blurRadius: 24 + t * 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'MASSIVE ARMS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryLight,
                        letterSpacing: 2.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Hora de encher a manga.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Image.asset(
              'assets/branding/app_icon.png',
              width: 128,
              height: 128,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
