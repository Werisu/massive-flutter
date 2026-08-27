import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/services/rest_overlay_service.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('cronômetro flutuante nativo só existe no Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(RestOverlayService.instance.isSupported, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(RestOverlayService.instance.isSupported, isFalse);
  });
}
