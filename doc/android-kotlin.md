# Android — Kotlin built-in (AGP 9+)

## Estado atual

O app já usa o DSL moderno:

```kotlin
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
```

Porém `android.builtInKotlin` permanece `false` porque plugins Flutter
(ex.: `cloud_firestore`, `firebase_auth`, `google_sign_in_android`) ainda aplicam
`org.jetbrains.kotlin.android`. Com `builtInKotlin=true` o build falha.

Guia Flutter: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

## Quando ativar

1. Confirme que os plugins Firebase/Google Sign-In migraram (changelog / pub.dev).
2. Remova `id("org.jetbrains.kotlin.android")` de `android/app/build.gradle.kts`.
3. Em `android/gradle.properties` defina:

```properties
android.builtInKotlin=true
```

4. Rode `flutter clean && flutter build apk --debug`.

Até lá, mantenha `android.builtInKotlin=false` e `android.newDsl=false`.
