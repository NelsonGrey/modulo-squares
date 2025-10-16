# Modulo Squares - Developer Guide

This guide provides information for developers looking to contribute to or understand the technical aspects of the Modulo Squares project.

## 1. Introduction

*   Brief overview of the project (can reference `README.md` for game concept).
*   Purpose of this developer guide.

## 2. Development Environment Setup

*   **Flutter SDK:**
    *   Link to official Flutter installation guide.
    *   Recommended Flutter version/channel (e.g., stable).
*   **IDE Setup:**
    *   Recommended IDEs (VS Code, Android Studio).
    *   Essential plugins/extensions (e.g., Flutter, Dart for VS Code).
*   **Platform Specific Setup:**
    *   iOS (Xcode, CocoaPods).
    *   Android (Android Studio, Android SDK, NDK if applicable).
*   **Cloning and Initial Setup:**
    *   `git clone <repository-url>`
    *   `flutter pub get`
    *   Running the app: `flutter run`
    *   Checking project health: `flutter doctor`

## 3. Project Architecture

*   **Overall Structure:**
    *   Brief explanation of the `lib/` subdirectories (`models`, `screens`, `widgets`, `main.dart`).
    *   Mention any other important directories (e.g., `assets`, `test`).
*   **State Management:**
    *   Current approach (e.g., `setState` for local widget state).
    *   (If applicable) Plans or considerations for more advanced state management (Provider, Riverpod, BLoC) as the app grows.
*   **Key Components & Responsibilities:**
    *   `main.dart`: App initialization, root widget (`ModuloApp`), theme.
    *   `models/game_board.dart`: Core game logic, data representation, rules engine.
    *   `screens/game_screen.dart`: Main UI, user interaction handling, orchestrates `GameBoard`.
    *   `widgets/grid_cell_widget.dart`: UI for individual grid cells.
*   **Data Flow:**
    *   How user input translates to game state changes.
    *   How `GameBoard` updates propagate to the UI.

## 4. Coding Conventions & Style

*   **Dart & Flutter Style:**
    *   Adherence to the official Dart style guide.
    *   Effective Dart guidelines.
    *   Flutter linting rules (e.g., using `flutter_lints` or a custom `analysis_options.yaml`).
*   **Naming Conventions:**
    *   `UpperCamelCase` for classes and enums.
    *   `lowerCamelCase` for variables, methods, and parameters.
    *   `snake_case` for file names (e.g., `game_screen.dart`).
*   **Comments:**
    *   Use `//` for single-line comments.
    *   Use `///` for documentation comments (for classes, methods, etc.) that can be processed by `dart doc`.
*   **Widget Structure:**
    *   Prefer `const` constructors where possible.
    *   Break down large `build` methods into smaller private methods or separate widgets.

## 5. Testing

*   **Types of Tests:**
    *   **Unit Tests:** For testing individual functions, methods, or classes (especially in `models/game_board.dart`).
        *   Location: `test/unit_tests/`
    *   **Widget Tests:** For testing individual widgets in isolation.
        *   Location: `test/widget_tests/`
    *   **Integration Tests (Planned/Future):** For testing complete app flows.
        *   Location: `test_driver/` or `integration_test/`
*   **Running Tests:**
    *   `flutter test` (for unit and widget tests).
    *   `flutter test integration_test` (if using the `integration_test` package).
*   **Writing Tests:**
    *   Brief guidelines on how to add new tests.

## 6. Version Control (Git)

*   **Branching Strategy (Example):**
    *   `main` (or `master`): Production-ready code.
    *   `develop`: Integration branch for features.
    *   Feature branches: `feature/<feature-name>` (e.g., `feature/add-animations`).
    *   Bugfix branches: `fix/<issue-description>` (e.g., `fix/incorrect-modulo-calc`).
*   **Commit Messages:**
    *   Follow conventional commit message format (e.g., `feat: Implement new game mechanic`).
*   **Pull Requests (PRs):**
    *   Guidelines for creating PRs (e.g., link to issue, clear description, self-review).

## 7. Building and Releasing

*   **Android:**
    *   Generating a signed APK/AAB: `flutter build apk --release`, `flutter build appbundle --release`.
    *   Key store management.
*   **iOS:**
    *   Building for release: `flutter build ipa --release`.
    *   Code signing and provisioning profiles.
*   **Version Numbering:**
    *   How `pubspec.yaml` version (`version: 1.0.0+1`) is handled.

## 8. Debugging

*   **Flutter DevTools:** Overview of using DevTools for layout inspection, performance profiling, etc.
*   **Logging:** Using `print()` for simple debugging or a more robust logging package.
*   **Breakpoints:** Using IDE debuggers.

## 9. Future Development & Roadmap

*   Reference the "Future Enhancements" section in `README.md`.
*   Any specific architectural considerations for upcoming features.

## 10. Contact & Contribution

*   How to get in touch (e.g., GitHub issues).
*   Reiterate contribution guidelines from `README.md`.

# Modulo Squares - Developer Guide

This comprehensive guide provides technical information for developers working on the Modulo Squares Flutter project, including architecture, implementation details, and development workflows.

## Table of Contents

1. [Introduction](#1-introduction)
2. [Development Environment Setup](#2-development-environment-setup)
3. [Project Architecture](#3-project-architecture)
4. [Core Game Logic](#4-core-game-logic)
5. [UI Implementation](#5-ui-implementation)
6. [Services & Integrations](#6-services--integrations)
7. [Testing](#7-testing)
8. [Building & Deployment](#8-building--deployment)
9. [Debugging](#9-debugging)
10. [Contributing](#10-contributing)

## 1. Introduction

**Modulo Squares** is a strategic puzzle game built with Flutter, featuring Firebase backend integration, AdMob monetization, and cross-platform support. Players move numbered tiles on a 4x4 grid using modulo arithmetic to clear the board.

### Key Technologies
- **Flutter 3.32.0** - Cross-platform UI framework
- **Firebase** - Backend services (Auth, Firestore, Analytics)
- **Google AdMob** - Advertising and monetization
- **Clean Architecture** - Feature-based code organization
- **Provider Pattern** - State management

## 2. Development Environment Setup

### Prerequisites
- **Flutter SDK**: 3.32.0+ ([Installation Guide](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: Included with Flutter
- **Android Studio**: For Android development and device emulation
- **Xcode**: 15.0+ for iOS development (macOS only)
- **Firebase CLI**: For backend deployment and emulation

### IDE Setup
**Recommended: Visual Studio Code**
- Install Flutter and Dart extensions
- Enable Flutter hot reload
- Configure linting and formatting

**Alternative: Android Studio**
- Flutter plugin pre-installed
- Advanced Android/iOS debugging tools

### Project Setup
```bash
# Clone repository
git clone <repository-url>
cd modulo-flutter-project

# Navigate to app package
cd packages/mobile

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
```

### Firebase Configuration
1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Anonymous, Google, Apple)
3. Enable Firestore Database
4. Enable Firebase Analytics
5. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

## 3. Project Architecture

### Overall Structure
```
packages/mobile/
├── lib/
│   ├── core/                    # Application-wide code
│   │   ├── config/             # Configuration files
│   │   ├── di/                 # Dependency injection
│   │   └── services/           # Core services
│   ├── features/               # Feature-based modules
│   │   ├── auth/               # Authentication
│   │   ├── game/               # Game logic & UI
│   │   └── leaderboard/        # Leaderboard
│   ├── shared/                 # Shared components
│   │   ├── models/            # Data models
│   │   └── widgets/           # Reusable widgets
│   ├── l10n/                  # Localization
│   └── main.dart              # App entry point
├── android/                    # Android platform code
├── ios/                       # iOS platform code
├── web/                       # Web platform code
└── test/                      # Test files
```

### Architecture Principles

#### Feature-Based Organization
- Code organized by business features (auth, game, leaderboard)
- Each feature contains its own data, domain, and UI layers
- Promotes maintainability and team collaboration

#### Clean Architecture Layers
```
Feature/
├── data/                      # Data access layer
│   ├── datasources/          # External data sources
│   ├── models/               # Data transfer objects
│   └── repositories/         # Repository implementations
├── domain/                    # Business logic layer
│   ├── entities/             # Business entities
│   ├── repositories/         # Abstract repositories
│   └── usecases/             # Business use cases
└── [feature]_screen.dart     # UI layer
```

#### Dependency Injection
- **GetIt** for service locator pattern
- Centralized dependency registration in `core/di/service_locator.dart`
- Enables easy testing and mocking

#### State Management
- **Provider** pattern for widget-level state
- **ChangeNotifier** for reactive UI updates
- Immutable models with `copyWith` pattern

## 4. Core Game Logic

### Game Board Model (`lib/shared/models/game_board.dart`)

The `GameBoard` class encapsulates all game rules and state management:

#### Key Properties
```dart
class GameBoard {
  final List<List<int?>> grid;        // 4x4 game grid
  final int rows = 4;
  final int cols = 4;
  final int level;                    // Current difficulty level
  final int score;                    // Current game score
  final int remainingMoves;           // Moves left in current level
  final bool isFrozen;               // Special tile effect
}
```

#### Core Methods

**Initialization:**
```dart
GameBoard populateRandomly({
  required int numbersToPlace,
  required int maxCellValue,
  int? level
})
```
- Fills grid with random numbers based on difficulty
- Ensures solvable game states

**Move Logic:**
```dart
GameBoard moveCell(int fromRow, int fromCol, int toRow, int toCol)
```
- Validates move legality (adjacent cells only)
- Applies modulo arithmetic: `target % source`
- Updates score and special effects
- Returns new immutable `GameBoard` instance

**Game State Checks:**
```dart
bool isBoardClear()           // All cells empty?
bool hasValidMoves()          // Any possible moves remaining?
bool isGameOver()            // No moves and board not clear?
```

### Modulo Arithmetic Rules

1. **Basic Move**: Source ≤ Target
   - `newValue = target % source`
   - If `newValue == 0`, target becomes empty
   - Source always becomes empty

2. **Empty Target**: Source moves to empty cell
   - Simple value transfer
   - No modulo operation

3. **Special Tiles**: Extended rules for power-ups
   - Multiplier: `score += value * 4`
   - Poison: `score -= 3`
   - Freeze: `frozen = true` (skip next turn)

### Game Flow
1. **Level Start**: `populateRandomly()` with level-based difficulty
2. **Player Move**: `moveCell()` with validation and scoring
3. **Win Check**: `isBoardClear()` → advance level
4. **Lose Check**: `!hasValidMoves() && !isBoardClear()` → game over

## 5. UI Implementation

### Game Screen (`lib/features/game/game_screen.dart`)

The main game interface manages the complete game experience:

#### State Management
```dart
class _GameScreenState extends State<GameScreen> {
  late GameBoard _gameBoard;
  int? _selectedRow, _selectedCol;
  int _currentLevel = 1;
  int _highScore = 0;
}
```

#### Key Methods

**Initialization:**
```dart
@override
void initState() {
  super.initState();
  _startNewGame();
}

void _startNewGame() {
  _gameBoard = GameBoard.initial().populateRandomly(
    numbersToPlace: 8 + (_currentLevel * 2),
    maxCellValue: 6 + _currentLevel,
    level: _currentLevel,
  );
  _selectedRow = _selectedCol = null;
  setState(() {});
}
```

**Cell Interaction:**
```dart
void _handleCellTap(int row, int col) {
  setState(() {
    if (_selectedRow == null) {
      // Select cell if it contains a number
      if (_gameBoard.getValue(row, col) != null) {
        _selectedRow = row;
        _selectedCol = col;
      }
    } else if (_selectedRow == row && _selectedCol == col) {
      // Deselect if tapping same cell
      _selectedRow = _selectedCol = null;
    } else {
      // Attempt move
      final moveResult = _gameBoard.moveCell(_selectedRow!, _selectedCol!, row, col);
      if (moveResult.success) {
        _gameBoard = moveResult.newBoard;
        if (_gameBoard.isBoardClear()) {
          _showWinDialog();
        }
      }
      _selectedRow = _selectedCol = null; // Always deselect after move attempt
    }
  });
}
```

#### UI Layout
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Modulo Squares - Level $_currentLevel'),
      actions: [_buildAppBarActions()],
    ),
    body: Column(
      children: [
        _buildGameInfo(),
        Expanded(child: _buildGameGrid()),
        _buildGameControls(),
      ],
    ),
  );
}
```

### Grid Cell Widget (`lib/shared/widgets/grid_cell_widget.dart`)

Renders individual grid cells with visual feedback:

```dart
class GridCellWidget extends StatelessWidget {
  final int? value;
  final bool isSelected;
  final bool isPossibleTarget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            value?.toString() ?? '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) return Colors.blue.withOpacity(0.3);
    if (isPossibleTarget) return Colors.green.withOpacity(0.2);
    return Colors.white;
  }
}
```

## 6. Services & Integrations

### Firebase Services

#### Authentication (`lib/core/services/auth_service.dart`)
- Anonymous authentication for quick play
- Google Sign-In for Android/iOS
- Apple Sign-In for iOS
- Automatic user profile creation

#### Leaderboard Service (`lib/core/services/leaderboard_service.dart`)
```dart
class LeaderboardService {
  static const String collectionName = 'modulo_leaderboard';

  Future<void> submitScore(String playerName, int score) async {
    final doc = FirebaseFirestore.instance.collection(collectionName).doc(playerName);
    await doc.set({
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<LeaderboardEntry>> getTopScores({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc))
            .toList());
  }
}
```

#### Analytics Service (`lib/core/services/analytics_service.dart`)
- Game events tracking (level start/complete, moves, ads)
- User engagement metrics
- Crash reporting integration

### AdMob Integration (`lib/core/services/ad_service.dart`)

#### Configuration
```dart
class AdMobConfig {
  static const String iosAppId = 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy';
  static const String androidAppId = 'ca-app-pub-xxxxxxxxxxxxxxxx~zzzzzzzzzz';

  static String get interstitialAdUnitId {
    if (Platform.isIOS) return iosInterstitialId;
    return androidInterstitialId;
  }
}
```

#### Ad Display Logic
- Interstitial ads shown on level completion
- Rewarded ads for bonus features (future)
- Consent management with UMP SDK

### Purchase Service (`lib/core/services/purchase_service.dart`)
- In-app purchases for ad removal
- Restore purchases functionality
- Receipt validation

## 7. Testing

### Test Structure
```
test/
├── models/                    # Unit tests for models
│   └── game_board_test.dart
├── widgets/                   # Widget tests
│   └── widget_test.dart
├── services/                  # Service integration tests
│   ├── leaderboard_service_test.dart
│   └── cache_service_test.dart
└── integration_test/          # End-to-end tests (future)
```

### Unit Testing Game Logic
```dart
void main() {
  group('GameBoard', () {
    test('should initialize with correct dimensions', () {
      final board = GameBoard.initial();
      expect(board.rows, equals(4));
      expect(board.cols, equals(4));
    });

    test('should perform modulo move correctly', () {
      final board = GameBoard.initial();
      // Set up specific board state
      final result = board.moveCell(0, 0, 0, 1);
      expect(result.success, isTrue);
      // Verify modulo arithmetic applied correctly
    });
  });
}
```

### Widget Testing
```dart
void main() {
  testWidgets('GameScreen displays grid correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: GameScreen()));

    // Verify grid appears
    expect(find.byType(GridView), findsOneWidget);

    // Verify cells are tappable
    await tester.tap(find.byType(GridCellWidget).first);
    await tester.pump();

    // Verify selection state
    // Add more interaction tests...
  });
}
```

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/game_board_test.dart

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## 8. Building & Deployment

### Development Builds
```bash
# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Enable hot reload
flutter run --debug
```

### Production Builds

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release

# Open Xcode for distribution
open ios/Runner.xcworkspace
```

#### Web
```bash
# Build for web
flutter build web

# Serve locally
flutter run -d chrome
```

### Code Signing

#### Android
- Create keystore: `keytool -genkey -v -keystore modulo_keystore.jks`
- Configure `android/local.properties` with signing credentials
- Update `android/app/build.gradle.kts` signing config

#### iOS
- Create App ID in Apple Developer portal
- Configure provisioning profiles
- Set up code signing in Xcode

## 9. Debugging

### Flutter DevTools
```bash
# Launch DevTools
flutter pub global run devtools
flutter pub global run devtools --serve
```

### Common Debugging Techniques

#### Game Logic Debugging
```dart
void _debugPrintBoard() {
  for (int row = 0; row < _gameBoard.rows; row++) {
    final rowValues = List.generate(
      _gameBoard.cols,
      (col) => _gameBoard.getValue(row, col)?.toString() ?? '.'
    );
    debugPrint(rowValues.join(' '));
  }
}
```

#### Performance Profiling
- Use Flutter DevTools Performance tab
- Monitor frame rendering times
- Identify expensive operations in game logic

#### Firebase Debugging
```bash
# Enable Analytics debug mode
adb shell setprop debug.firebase.analytics.app <package-name>

# View Firestore locally
firebase emulators:start --only firestore
```

### Error Handling
- Wrap Firebase operations in try-catch blocks
- Use `FirebaseCrashlytics` for error reporting
- Implement graceful fallbacks for network failures

## 10. Contributing

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` for consistent formatting
- Run `flutter analyze` before committing

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes with tests
# Run tests and analysis

# Commit changes
git commit -m "feat: add new feature"

# Push and create PR
git push origin feature/new-feature
```

### Pull Request Guidelines
- Include clear description of changes
- Reference related issues
- Ensure all tests pass
- Update documentation if needed
- Request review from maintainers

### Areas for Contribution
- UI/UX improvements
- New special tile types
- Enhanced animations
- Sound effects
- Additional test coverage
- Performance optimizations

---

This guide provides comprehensive information for developing and maintaining the Modulo Squares application. For specific implementation details, refer to the inline code documentation and tests.

