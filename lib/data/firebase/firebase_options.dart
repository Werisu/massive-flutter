// File generated manually from google-services.json (project massive-4f2f4).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        // Desktop: usa config web do mesmo projeto.
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não suportado nesta plataforma.',
        );
    }
  }

  /// Config web do projeto massive-4f2f4.
  /// Se o Console ainda não tiver app Web, o init pode falhar —
  /// o main.dart trata isso e o app sobe offline.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC3Tcczc7b0WiPapJEHyAlC7tnC0UEUtdY',
    appId: '1:883844314360:web:massiveflutter',
    messagingSenderId: '883844314360',
    projectId: 'massive-4f2f4',
    authDomain: 'massive-4f2f4.firebaseapp.com',
    storageBucket: 'massive-4f2f4.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3Tcczc7b0WiPapJEHyAlC7tnC0UEUtdY',
    appId: '1:883844314360:android:914a1f19cb4517cfadf70d',
    messagingSenderId: '883844314360',
    projectId: 'massive-4f2f4',
    storageBucket: 'massive-4f2f4.firebasestorage.app',
  );

  /// iOS — bundle `com.massive.massiveArms`.
  /// Substitua `appId` pelo GOOGLE_APP_ID do GoogleService-Info.plist oficial
  /// (ver doc/ios-firebase.md). Até lá o init pode falhar e o app segue offline.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3Tcczc7b0WiPapJEHyAlC7tnC0UEUtdY',
    appId: '1:883844314360:ios:REPLACE_AFTER_FIREBASE_CONSOLE',
    messagingSenderId: '883844314360',
    projectId: 'massive-4f2f4',
    storageBucket: 'massive-4f2f4.firebasestorage.app',
    iosBundleId: 'com.massive.massiveArms',
  );
}
