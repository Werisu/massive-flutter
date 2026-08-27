import 'package:flutter_test/flutter_test.dart';
import 'package:massive_arms/data/models/user_preferences.dart';

void main() {
  test('keepAliveEnabled padrão é true e sobrevive ao JSON', () {
    const prefs = UserPreferences(userName: 'Atleta');
    expect(prefs.keepAliveEnabled, isTrue);

    final encoded = UserPreferences.fromJson(prefs.toJson());
    expect(encoded.keepAliveEnabled, isTrue);

    final disabled = prefs.copyWith(keepAliveEnabled: false);
    expect(UserPreferences.fromJson(disabled.toJson()).keepAliveEnabled, isFalse);
  });

  test('preferências antigas sem a chave ligam keep-alive', () {
    final prefs = UserPreferences.fromJson({
      'userName': 'Wellysson',
      'restMinutesWorking': 3,
      'restMinutesPrep': 1,
    });
    expect(prefs.keepAliveEnabled, isTrue);
  });

  test('substituições de exercício sobrevivem ao JSON', () {
    const prefs = UserPreferences(
      userName: 'Atleta',
      exerciseSubstitutions: {'wed_1': 'alt_martelo_polia'},
    );
    final encoded = UserPreferences.fromJson(prefs.toJson());
    expect(encoded.exerciseSubstitutions['wed_1'], 'alt_martelo_polia');
  });
}
