import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mantém o app vivo em segundo plano (FGS no Android, sessão de áudio no iOS).
class KeepAliveService {
  KeepAliveService._();
  static final instance = KeepAliveService._();

  static const _channel = MethodChannel('space.manus.massive.arms/keep_alive');

  AudioPlayer? _player;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> setEnabled(
    bool enabled, {
    bool requestUnrestricted = false,
  }) async {
    if (!_supported) return;
    if (!enabled) {
      _enabled = false;
      await _stopNative();
      await _stopAudio();
      return;
    }

    final alreadyOn = _enabled;
    _enabled = true;
    if (!alreadyOn || _player == null) {
      await _startAudio();
    }
    await _startNative();
    if (requestUnrestricted) {
      await requestBackgroundUnrestricted();
    }
  }

  Future<bool> isBackgroundUnrestricted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final value = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return value ?? false;
    } catch (e) {
      debugPrint('KeepAlive isBackgroundUnrestricted: $e');
      return false;
    }
  }

  Future<void> requestBackgroundUnrestricted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('KeepAlive requestBackgroundUnrestricted: $e');
    }
  }

  Future<void> _startNative() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('start');
    } catch (e) {
      debugPrint('KeepAlive start nativo falhou: $e');
    }
  }

  Future<void> _stopNative() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('stop');
    } catch (e) {
      debugPrint('KeepAlive stop nativo falhou: $e');
    }
  }

  Future<void> _startAudio() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      _player ??= AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(0.01);
      await _player!.stop();
      await _player!.play(
        BytesSource(_silentWav(), mimeType: 'audio/wav'),
        ctx: AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('KeepAlive áudio de fundo falhou: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}

Uint8List _silentWav({int sampleRate = 8000, int durationMs = 1000}) {
  final totalSamples = sampleRate * durationMs ~/ 1000;
  final dataSize = totalSamples * 2;
  final bytes = ByteData(44 + dataSize);
  var o = 0;

  void writeAscii(String value) {
    for (final code in value.codeUnits) {
      bytes.setUint8(o++, code);
    }
  }

  writeAscii('RIFF');
  bytes.setUint32(o, 36 + dataSize, Endian.little);
  o += 4;
  writeAscii('WAVE');
  writeAscii('fmt ');
  bytes.setUint32(o, 16, Endian.little);
  o += 4;
  bytes.setUint16(o, 1, Endian.little);
  o += 2;
  bytes.setUint16(o, 1, Endian.little);
  o += 2;
  bytes.setUint32(o, sampleRate, Endian.little);
  o += 4;
  bytes.setUint32(o, sampleRate * 2, Endian.little);
  o += 4;
  bytes.setUint16(o, 2, Endian.little);
  o += 2;
  bytes.setUint16(o, 16, Endian.little);
  o += 2;
  writeAscii('data');
  bytes.setUint32(o, dataSize, Endian.little);
  o += 4;
  return bytes.buffer.asUint8List();
}
