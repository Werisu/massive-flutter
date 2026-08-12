# iOS — Firebase + Google Sign-In

O projeto Android já usa `massive-4f2f4`. Para iOS funcionar de verdade, registre um app iOS no mesmo projeto e baixe o `GoogleService-Info.plist` oficial.

## Bundle ID

Xcode / Flutter iOS:

`com.massive.massiveArms`

## Passos no Firebase Console

1. Project settings → Add app → iOS  
2. Bundle ID: `com.massive.massiveArms`  
3. Baixe `GoogleService-Info.plist`  
4. Substitua `ios/Runner/GoogleService-Info.plist`  
5. Atualize `lib/data/firebase/firebase_options.dart` → `ios.appId` com o `GOOGLE_APP_ID` do plist  

Ou rode:

```bash
flutterfire configure --project=massive-4f2f4
```

## Google Sign-In (URL scheme)

O `Info.plist` já inclui o `CFBundleURLTypes` com o client Web reverso:

`com.googleusercontent.apps.883844314360-4bblq3so310f1qklpoancv7t7k4diujf`

Se o Console gerar outro `REVERSED_CLIENT_ID` no plist iOS, atualize o URL scheme para coincidir.

## Notificações (timer de descanso)

No primeiro uso, o iOS pedirá permissão de notificação via `flutter_local_notifications`.

## Testar

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run -d <seu-iphone-ou-simulador>
```

O `main.dart` tolera falha de init do Firebase (app sobe offline). Com o plist oficial, Auth/Firestore devem inicializar normalmente.
