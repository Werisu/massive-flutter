import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bip + vibração quando um cronômetro chega a zero.
class TimerCueService {
  TimerCueService._();
  static final instance = TimerCueService._();

  AudioPlayer? _player;
  Uint8List? _wav;

  Future<void> play() async {
    await HapticFeedback.vibrate();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      HapticFeedback.heavyImpact();
    });

    try {
      _player ??= AudioPlayer();
      _wav ??= buildTimerBeepWav();
      await _player!.stop();
      await _player!.play(
        BytesSource(_wav!, mimeType: 'audio/wav'),
        ctx: AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            stayAwake: false,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('TimerCueService: falha no som, usando alerta do sistema: $e');
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}

/// WAV PCM 16-bit mono: dois bips curtos (som clássico de timer).
Uint8List buildTimerBeepWav({int sampleRate = 22050}) {
  const frequency = 880.0;
  const beepMs = 160;
  const gapMs = 90;
  const fadeMs = 8;
  const pulses = 2;

  final beepSamples = sampleRate * beepMs ~/ 1000;
  final gapSamples = sampleRate * gapMs ~/ 1000;
  final fadeSamples = max(1, sampleRate * fadeMs ~/ 1000);
  final totalSamples = pulses * beepSamples + (pulses - 1) * gapSamples;

  final pcm = Int16List(totalSamples);
  var offset = 0;
  for (var pulse = 0; pulse < pulses; pulse++) {
    for (var i = 0; i < beepSamples; i++) {
      var envelope = 1.0;
      if (i < fadeSamples) envelope = i / fadeSamples;
      final tail = beepSamples - 1 - i;
      if (tail < fadeSamples) envelope = min(envelope, tail / fadeSamples);
      final sample =
          sin(2 * pi * frequency * i / sampleRate) * envelope * 0.72;
      pcm[offset + i] = (sample * 32767).round().clamp(-32767, 32767);
    }
    offset += beepSamples;
    if (pulse < pulses - 1) offset += gapSamples;
  }

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
  for (var i = 0; i < totalSamples; i++) {
    bytes.setInt16(o, pcm[i], Endian.little);
    o += 2;
  }
  return bytes.buffer.asUint8List();
}
