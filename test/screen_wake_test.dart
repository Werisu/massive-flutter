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
    await ScreenWakeService.instance.setInForeground(true);
    await ScreenWakeService.instance.release(ScreenWakeService.appHolder);
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

  test('mantém a tela ligada se o app ainda está em primeiro plano', () async {
    await ScreenWakeService.instance.acquire(ScreenWakeService.appHolder);
    await ScreenWakeService.instance.setEnabled(true);
    expect(calls, hasLength(1));

    await ScreenWakeService.instance.setEnabled(false);
    expect(ScreenWakeService.instance.isEnabled, isTrue);
    expect(calls, hasLength(1));

    await ScreenWakeService.instance.release(ScreenWakeService.appHolder);
    expect(ScreenWakeService.instance.isEnabled, isFalse);
    expect(calls.last.arguments, {'enabled': false});
  });

  test('desliga a tela ao ir para segundo plano', () async {
    await ScreenWakeService.instance.acquire(ScreenWakeService.appHolder);
    expect(ScreenWakeService.instance.isEnabled, isTrue);

    await ScreenWakeService.instance.setInForeground(false);
    expect(ScreenWakeService.instance.isEnabled, isFalse);
    expect(calls.last.arguments, {'enabled': false});

    await ScreenWakeService.instance.setInForeground(true);
    expect(ScreenWakeService.instance.isEnabled, isTrue);
    expect(calls.last.arguments, {'enabled': true});

    await ScreenWakeService.instance.release(ScreenWakeService.appHolder);
  });
}
