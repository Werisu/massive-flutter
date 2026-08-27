import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Impede a tela de apagar enquanto o cronômetro está visível no app.
class ScreenWakeService {
  ScreenWakeService._();
  static final instance = ScreenWakeService._();

  static const _channel = MethodChannel('space.manus.massive.arms/screen_wake');

  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('setEnabled', {
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('ScreenWake setEnabled: $e');
    }
  }
}
