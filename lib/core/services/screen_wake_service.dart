import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Impede a tela de apagar enquanto o aplicativo está em primeiro plano.
class ScreenWakeService {
  ScreenWakeService._();
  static final instance = ScreenWakeService._();

  static const appHolder = 'app';
  static const sessionHolder = 'session';

  static const _channel = MethodChannel('space.manus.massive.arms/screen_wake');

  final Set<String> _holders = <String>{};
  bool _inForeground = true;
  bool _nativeEnabled = false;

  bool get isEnabled => _nativeEnabled;

  Future<void> setEnabled(bool enabled) {
    return enabled ? acquire(sessionHolder) : release(sessionHolder);
  }

  Future<void> setInForeground(bool inForeground) async {
    if (_inForeground == inForeground) return;
    _inForeground = inForeground;
    await _sync();
  }

  Future<void> acquire(String holder) async {
    _holders.add(holder);
    await _sync();
  }

  Future<void> release(String holder) async {
    _holders.remove(holder);
    await _sync();
  }

  Future<void> _sync() async {
    final enabled = _inForeground && _holders.isNotEmpty;
    if (_nativeEnabled == enabled) return;
    _nativeEnabled = enabled;
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
