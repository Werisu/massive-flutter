import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/services/timer_cue_service.dart';

void main() {
  test('WAV do bip do timer tem cabeçalho PCM válido', () {
    final wav = buildTimerBeepWav();
    expect(wav.length, greaterThan(44));
    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
    expect(ascii.decode(wav.sublist(12, 16)), 'fmt ');
    expect(ascii.decode(wav.sublist(36, 40)), 'data');

    final header = ByteData.sublistView(wav);
    expect(header.getUint16(20, Endian.little), 1);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint16(34, Endian.little), 16);
    expect(header.getUint32(40, Endian.little), wav.length - 44);
  });
}
