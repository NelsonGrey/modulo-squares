# Modulo Squares mobile app

Flutter application for the falling-number Modulo Squares game.

## Requirements

- Flutter `3.44.2` recommended by CI
- Dart `>=3.7.0 <4.0.0`
- Xcode/CocoaPods for iOS
- Android Studio/JDK for Android
- Ruby `3.2.2` for Fastlane

## Commands

```bash
flutter pub get
flutter analyze
flutter test --coverage
flutter run
flutter build ios --release --no-codesign
flutter build appbundle --release
```

Run `../../scripts/switch-mobile-configs.sh dev|staging|prod` before an environment-specific native build.

`lib/features/game/game_screen.dart` is the gameplay entry point and delegates to `FallingModuloGameScreen`. The older `GameBoard`/`GameProvider` implementation remains as legacy/reference code and tests.

See [the root README](../../README.md), [Game Mechanics](../../docs/Game_Mechanics.md), and [Testing](../../docs/Testing.md).
