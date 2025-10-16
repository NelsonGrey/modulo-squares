# Modulo Squares

A Firebase-powered puzzle game built with Flutter, featuring in-app purchases, ads, and cross-platform support.

## 🎮 Game Concept

Modulo Squares is a strategic puzzle game played on a 4x4 grid where players move numbered tiles to clear the board using modulo arithmetic. The core mechanic involves moving tiles into adjacent squares - when a tile's value is less than or equal to the target square's value, a modulo operation occurs, potentially clearing tiles and advancing the game.

**Objective:** Clear the entire board of numbers to win!

## 🏗️ Project Structure

```
modulo-flutter-project/
├── packages/
│   ├── app/                    # Main Flutter application
│   │   ├── lib/               # Flutter source code
│   │   │   ├── core/          # Application core (services, config)
│   │   │   ├── features/      # Feature-based architecture
│   │   │   │   ├── auth/      # Authentication feature
│   │   │   │   ├── game/      # Game feature
│   │   │   │   └── leaderboard/# Leaderboard feature
│   │   │   ├── shared/        # Shared components
│   │   │   ├── l10n/          # Localization
│   │   │   └── main.dart      # App entry point
│   │   ├── android/           # Android platform code
│   │   ├── ios/               # iOS platform code
│   │   ├── web/               # Web platform code
│   │   └── test/              # Unit and widget tests
│   └── shared/               # Shared utilities (future use)
├── firebase.json             # Firebase configuration
├── .firebaserc              # Firebase project configuration
├── analysis_options.yaml    # Dart/Flutter linting rules
└── pubspec.yaml             # Flutter dependencies
```

## 🚀 Features

- **Cross-Platform**: iOS, Android, and Web support
- **Firebase Integration**: Authentication, Firestore, Analytics
- **Monetization**: AdMob ads and in-app purchases
- **Game Mechanics**: Modulo arithmetic, special tiles, progressive difficulty
- **Leaderboards**: Global high scores with Firebase
- **Offline Play**: Local gameplay with cloud sync
- **Privacy Compliant**: App Tracking Transparency, consent management

## 🛠️ Tech Stack

- **Framework**: Flutter 3.32.0
- **Language**: Dart
- **Backend**: Firebase (Auth, Firestore, Analytics, Functions)
- **Ads**: Google AdMob with consent management
- **Purchases**: In-app purchases for ad removal
- **State Management**: Provider pattern with feature-based architecture
- **Architecture**: Clean Architecture with dependency injection

## Development

### Prerequisites
- Flutter 3.32.0+
- Node.js 18+
- Firebase CLI
- Android Studio (for Android development)
- Xcode (for iOS development)

### Setup
```bash
# Install root dependencies
npm install

# Install functions dependencies
npm run install:all

# Login to Firebase
firebase login
```

### Development Commands
```bash
# Run Flutter app
cd packages/mobile && flutter run

# Run functions locally
firebase emulators:start

# Test Flutter app
npm run test:app

# Deploy all services
npm run deploy:all
```

### Building
```bash
# Build Android APK
npm run build:app

# Build web app
cd packages/mobile && flutter build web
```

## 📦 Packages

### App (`packages/mobile/`)
The main Flutter application with cross-platform support.

**Key Components:**
- **Core Services**: AdMob, Analytics, Leaderboard, Purchase, Asset management
- **Features**: Authentication (Google/Apple/Anonymous), Game logic, Leaderboards
- **UI**: Game screen, Login screen, Leaderboard screen with responsive design
- **Platform Support**: iOS, Android, Web with platform-specific optimizations

### Shared (`packages/shared/`)
Shared utilities and common code (currently minimal, designed for future expansion).

## 🏗️ Architecture

This project follows a **feature-based clean architecture** with clear separation of concerns:

```
lib/
├── core/                          # Application-wide services and configuration
│   ├── config/                    # App configuration (AdMob, Firebase)
│   ├── di/                        # Dependency injection setup
│   └── services/                  # Core services (ads, analytics, leaderboard)
├── features/                      # Feature-based architecture
│   ├── auth/                      # Authentication feature
│   │   ├── data/                  # Data layer (repositories, datasources)
│   │   ├── domain/                # Domain layer (entities, usecases)
│   │   ├── login_screen.dart      # UI layer
│   │   └── profile_screen.dart
│   ├── game/                      # Game feature
│   │   ├── game_screen.dart       # Main game UI
│   │   ├── game_state.dart        # Game state management
│   │   ├── providers/             # State providers
│   │   └── widgets/               # Game-specific widgets
│   └── leaderboard/               # Leaderboard feature
│       └── leaderboard_screen.dart
├── shared/                        # Shared components across features
│   ├── models/                    # Common data models
│   └── widgets/                   # Reusable UI components
├── l10n/                          # Localization files
└── main.dart                      # App entry point
```

### Architecture Principles

- **Feature-based**: Code organized by business features rather than technical layers
- **Clean Architecture**: Separation between data, domain, and presentation layers
- **Dependency Injection**: Services injected using GetIt for testability
- **Immutable Models**: Game state managed with immutable data structures
- **Platform Agnostic**: Core logic separated from platform-specific code

## 🚀 Getting Started

### Prerequisites
- Flutter 3.32.0+
- Dart SDK
- Android Studio (for Android development)
- Xcode 15+ (for iOS development)
- Firebase CLI (for backend deployment)

### Firebase Setup

1. **Create Firebase Project**: Visit [console.firebase.google.com](https://console.firebase.google.com)
2. **Enable Services**:
   - Authentication (Anonymous, Google, Apple sign-in)
   - Firestore Database
   - Firebase Analytics
3. **Add Apps**: Register Android and iOS apps in Firebase console
4. **Download Config Files**:
   - `google-services.json` → `packages/mobile/android/app/`
   - `GoogleService-Info.plist` → `packages/mobile/ios/Runner/`

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd modulo-flutter-project

# Install Flutter dependencies
cd packages/app
flutter pub get

# Run the app
flutter run
```

### Development Commands

```bash
# Run on specific platform
flutter run -d ios        # iOS simulator/device
flutter run -d android    # Android emulator/device
flutter run -d chrome     # Web browser

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/game_board_test.dart

# Run integration tests (if available)
flutter test integration_test
```

## 📱 Building for Production

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS
flutter build ios --release

# Open Xcode for distribution
open ios/Runner.xcworkspace
```

### Web
```bash
# Build for web
flutter build web
```

## 🚀 Deployment

The project uses GitHub Actions for CI/CD with three Firebase environments:

- **DEV**: `modulo-squares-dev` (develop branch)
- **STAGING**: `modulo-squares-staging` (staging branch)
- **PROD**: `modulo-squares-prod` (main branch)

### Environment URLs
- **DEV**: https://modulo-squares-dev.web.app
- **STAGING**: https://modulo-squares-staging.web.app
- **PROD**: https://modulo-squares-prod.web.app

### Automatic Deployments
- Push to `develop` → Deploys to DEV
- Push to `staging` → Deploys to STAGING
- Push to `main` → Deploys to PROD + creates release

### Manual Deployments
```bash
# Deploy to development
./scripts/deploy.sh dev

# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh prod
```

For detailed CI/CD setup instructions, see [CI_CD_SETUP.md](CI_CD_SETUP.md).

### Mobile App Releases
When pushing to `main`, the CI pipeline automatically builds and creates GitHub releases with:
- Android APK and AAB files
- iOS build artifacts

## 📊 Analytics & Monitoring

The app includes comprehensive Firebase Analytics tracking:
- User engagement and retention metrics
- Game progression and difficulty analysis
- Ad performance monitoring
- Crash reporting and error tracking

## 🔮 Future Enhancements

- Enhanced animations and visual effects
- Sound effects and haptic feedback
- Daily challenges and tournaments
- Social features (friend leaderboards, achievements)
- Cloud save functionality
- Advanced analytics and A/B testing
- More special tile types and power-ups

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` file for more information.

---

**Project by:** Mark Nelson

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Flutter SDK: Install Flutter
*   An editor like VS Code or Android Studio with Flutter plugins.
*   Firebase project: Set up a Firebase project for authentication, Firestore, and Analytics.

### Firebase Setup

1.  Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
2.  Enable Authentication with Anonymous sign-in
3.  Enable Firestore Database
4.  Enable Google Analytics
5.  Add Android and iOS apps to your Firebase project
6.  Download and place the configuration files:
    - `google-services.json` in `android/app/`
    - `GoogleService-Info.plist` in `ios/Runner/`

### Installation

1.  Clone the repo:
    ```sh
    git clone <your-repository-url>
    ```
2.  Navigate to the project directory:
    ```sh
    cd modulo-flutter-project
    ```
3.  Install dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the app:
    ```sh
    flutter run
    ```

### Testing

Run the test suite:
```sh
flutter test
```

Run with code coverage:
```sh
flutter test --coverage
```

## Future Enhancements

*   Enhanced animations for tile movements and value changes.
*   Sound effects and haptic feedback.
*   More special tile types and power-ups.
*   Daily challenges and tournaments.
*   Social features (friend leaderboards, achievements).
*   Cloud save functionality for cross-device progress.
*   Advanced analytics and player behavior insights.
*   A/B testing framework for game balance.
*   Offline mode with local leaderboards.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` file for more information (you'll need to create this file if you want one).

---

Project by: Mark Nelson