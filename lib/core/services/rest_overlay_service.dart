import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'rest_notification_service.dart';

/// Cronômetro flutuante sobre outros apps (Android).
class RestOverlayService {
  RestOverlayService._();
  static final instance = RestOverlayService._();

  static const _channel = MethodChannel('space.manus.massive.arms/rest_overlay');

  bool _prompted = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (e) {
      debugPrint('RestOverlay hasPermission: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('requestPermission');
    } catch (e) {
      debugPrint('RestOverlay requestPermission: $e');
    }
  }

  Future<void> show({required DateTime endsAt}) async {
    if (kIsWeb) return;
    await RestNotificationService.instance.showRestCountdown(endsAt: endsAt);
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('show', {
        'endsAtMillis': endsAt.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('RestOverlay show: $e');
    }
  }

  Future<void> hide() async {
    await RestNotificationService.instance.cancelCountdown();
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('hide');
    } catch (e) {
      debugPrint('RestOverlay hide: $e');
    }
  }

  Future<void> promptIfNeeded(BuildContext context) async {
    if (!isSupported || _prompted) return;
    if (await hasPermission()) return;
    if (!context.mounted) return;
    _prompted = true;

    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cronômetro flutuante'),
        content: const Text(
          'Para ver o tempo de descanso sobre outros apps '
          '(YouTube, Instagram, etc.), permita que o Massive Arms '
          'seja exibido sobre outros aplicativos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
    if (allow == true) {
      await requestPermission();
    }
  }
}
