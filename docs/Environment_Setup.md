# Environment Setup

**Updated**: 2026-07-20

## Required tools

| Tool | Repository expectation |
|---|---|
| Flutter | `3.44.2` in CI |
| Dart | `>=3.7.0 <4.0.0` from `pubspec.yaml` |
| Node.js | `>=20`; `.nvmrc` pins `20.3.2` |
| npm | compatible with Node 20 and lockfiles |
| Firebase CLI | install from root dev dependency or globally |
| Ruby | `3.2.2` for mobile Fastlane |
| Xcode/CocoaPods | required for iOS |
| Android Studio/JDK | required for Android |

## Install dependencies

```bash
nvm use
npm install
npm --prefix packages/firebase-utils install

cd packages/mobile
flutter pub get
cd ../..
```

The Functions package is private and not installed by the public root setup.

## Configuration files

Tracked templates/examples:

- `.env.example`
- `.env.automation.example`
- `.env.automation.development.example`
- `packages/mobile/android/local.properties.example`

Sensitive `.env*`, signing files, local Firebase state, Pods, build output, and `packages/functions` are ignored. Never copy secret values into documentation or commits.

## Firebase environments

| Short name | Project |
|---|---|
| `dev` | `modulo-squares-dev` |
| `staging` | `modulo-squares-staging` |
| `prod` | `modulo-squares-prod` |

Switch native mobile config:

```bash
./scripts/switch-mobile-configs.sh dev
./scripts/switch-mobile-configs.sh staging
./scripts/switch-mobile-configs.sh prod
```

The script updates the active Android/iOS Google service files. Confirm the selected project before building or deploying.

## Run locally

### Flutter native

```bash
cd packages/mobile
flutter devices
flutter run -d <device-id>
```

### React website

```bash
cd packages/web
npm run dev
```

### Firebase emulators

Rules can be emulated from the public repository. Functions emulation requires the private checkout at `packages/functions`.

```bash
firebase emulators:start --project modulo-squares-dev
```

## Private Functions checkout

Authorized developers can clone the matching branch:

```bash
git clone --branch develop \
  https://github.com/NelsonGrey/modulo-squares-functions.git \
  packages/functions
```

Run `git -C packages/functions status --short --branch` separately because it is an independent repository. The public root ignores the entire directory.

## iOS

Use `scripts/ios-local-dev.sh` and the iOS signing documents for certificate/Match setup. The bundle ID is `com.modulosquares.app.ios`. Release IAP/Sign in with Apple testing requires a properly signed device/TestFlight build.

## Android

The application ID is defined in `packages/mobile/android/app/build.gradle.kts`. Create `local.properties` from the example and configure signing for release builds. Android is not currently built in CI.

## Baseline validation

```bash
npm run lint
npm run check
npm run build:web

cd packages/mobile
flutter doctor -v
flutter analyze
flutter test
```

## Common pitfalls

- Root Functions commands fail when the private checkout is absent.
- Flutter web is not the deployed marketing site; use `packages/web`.
- Old docs may name archived workflow files or self-hosted runners.
- Firebase API keys are tracked client configuration, but they still require console-side restrictions and rules/App Check.
- Do not infer App Store, Firebase console, DNS, or analytics configuration solely from local files.
