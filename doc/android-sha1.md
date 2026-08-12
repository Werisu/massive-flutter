# Android — SHA-1 / Google Sign-In

Para o login Google funcionar de forma estável no Android (debug e release), o Firebase precisa dos fingerprints SHA do keystore.

## 1. Obter SHA-1 (debug)

No Windows (PowerShell), a partir da pasta do projeto:

```powershell
cd android
.\gradlew.bat signingReport
```

Procure `Variant: debug` → `SHA1:`.

Ou com keytool (JDK):

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## 2. Obter SHA-1 (release)

Use o keystore de publicação (Play App Signing / seu `.jks`):

```powershell
keytool -list -v -keystore "CAMINHO\seu-release.jks" -alias SEU_ALIAS
```

No Play Console: **Setup → App integrity → App signing** também mostra o SHA-1 do certificado de assinatura da Play.

## 3. Cadastrar no Firebase

1. Firebase Console → Project settings → Your apps → Android  
2. Package name: `space.manus.massive.arms.t20260324141650`  
3. Add fingerprint → cole SHA-1 (debug e release)  
4. Baixe de novo o `google-services.json` se o Console pedir e substitua em `android/app/`

## 4. Conferir OAuth

Em Google Cloud Console (mesmo projeto):

- OAuth client Android com o package + SHA-1  
- OAuth client Web (tipo 3) usado como `serverClientId` no app

O client Web atual no código:

`883844314360-4bblq3so310f1qklpoancv7t7k4diujf.apps.googleusercontent.com`

## 5. Testar

```bash
flutter clean
flutter run
```

Faça login com a mesma conta Google do histórico na nuvem.
