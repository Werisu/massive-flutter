import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/services/screen_wake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('space.manus.massive.arms/screen_wake');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() async {
    await ScreenWakeService.instance.setEnabled(false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('liga a tela só na primeira vez e desliga ao parar', () async {
    await ScreenWakeService.instance.setEnabled(true);
    await ScreenWakeService.instance.setEnabled(true);
    expect(ScreenWakeService.instance.isEnabled, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setEnabled');
    expect(calls.single.arguments, {'enabled': true});

    await ScreenWakeService.instance.setEnabled(false);
    expect(ScreenWakeService.instance.isEnabled, isFalse);
    expect(calls, hasLength(2));
    expect(calls.last.arguments, {'enabled': false});
  });
}
