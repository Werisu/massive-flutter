import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/firebase/auth_repository.dart';
import 'data/firebase/firebase_options.dart';
import 'data/local/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveBoxes.init();
  } catch (e, st) {
    debugPrint('Hive init falhou: $e\n$st');
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    try {
      await AuthRepository().initializeGoogleSignIn();
    } catch (e) {
      debugPrint('Google Sign-In init: $e');
    }
  } catch (e, st) {
    debugPrint('Firebase init falhou (seguindo offline): $e\n$st');
  }

  runApp(
    const ProviderScope(
      child: MassiveApp(),
    ),
  );
}
