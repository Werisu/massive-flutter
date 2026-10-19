import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/core/theme/app_theme.dart';
import 'package:massive_arms/data/repositories/preferences_repository.dart';
import 'package:massive_arms/data/services/exercise_catalog.dart';
import 'package:massive_arms/features/workout_session/exercise_substitute_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ExerciseCatalog.setCustom(const []);
  });

  tearDown(() {
    ExerciseCatalog.setCustom(const []);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            PreferencesRepository.memory(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showExerciseSubstituteSheet(
                  context: context,
                  protocolExerciseId: 'ex_martelo',
                  currentExerciseId: 'ex_martelo',
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('fechar o diálogo de novo exercício não quebra a árvore', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Criar exercício'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Novo exercício'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Substituir exercício'), findsOneWidget);
  });

  testWidgets('criar e usar um exercício fecha o diálogo sem assertion', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Criar exercício'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField).last, 'Rosca');
    await tester.tap(find.text('Criar e usar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Novo exercício'), findsNothing);
    expect(find.text('Substituir exercício'), findsNothing);
    expect(ExerciseCatalog.findByName('Rosca')?.muscleGroup.name, 'biceps');
  });
}
