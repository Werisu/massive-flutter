import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/features/spotify/pump_trainer_sticker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, double progress) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PumpTrainerSticker(height: 220, progress: progress),
          ),
        ),
      ),
    );
  }

  testWidgets('mostra rosca, agachamento e press', (tester) async {
    await show(tester, 0.083);
    expect(find.text('Rosca'), findsOneWidget);

    await show(tester, 0.416);
    expect(find.text('Agachamento'), findsOneWidget);

    await show(tester, 0.75);
    expect(find.text('Press'), findsOneWidget);
  });
}
