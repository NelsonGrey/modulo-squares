# Modulo Squares - Flutter Architecture & Design Patterns

## Architecture Overview

Modulo Squares follows a **Feature-Based Clean Architecture** pattern combined with modern Flutter best practices. This ensures scalability, testability, and maintainability.

### Architecture Principles

1. **Feature-Based Organization**: Code grouped by business features, not technical layers
2. **Clean Architecture**: Clear separation of concerns across layers
3. **Dependency Injection**: Services injected via GetIt for loose coupling
4. **Immutable Models**: Functional programming with immutable data structures
5. **Reactive UI**: Provider pattern for reactive state management
6. **Platform Agnostic**: Core logic separated from platform-specific code

---

## Project Structure

### Directory Hierarchy

```
packages/mobile/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   ├── firebase_options.dart    # Firebase configuration
│   │   │   └── app_config.dart          # App constants
│   │   ├── services/
│   │   │   ├── analytics_service.dart   # Firebase Analytics
│   │   │   ├── ad_service.dart          # AdMob integration
│   │   │   ├── purchase_service.dart    # IAP handling
│   │   │   ├── consent_service.dart     # GDPR/ATT
│   │   │   ├── cache_service.dart       # Local caching
│   │   │   ├── asset_service.dart       # Asset preloading
│   │   │   ├── leaderboard_service.dart # Firestore access
│   │   │   └── error_handler.dart       # Error handling
│   │   └── di/
│   │       └── service_locator.dart     # DI setup
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_gate.dart           # Authentication UI
│   │   │   └── auth_service.dart        # Auth logic
│   │   ├── game/
│   │   │   ├── models/
│   │   │   │   ├── game_state.dart      # Game session state
│   │   │   │   └── cell_position.dart   # Grid coordinates
│   │   │   ├── providers/
│   │   │   │   └── game_provider.dart   # State management
│   │   │   ├── widgets/
│   │   │   │   ├── game_grid.dart       # Grid widget
│   │   │   │   ├── game_cell.dart       # Cell widget
│   │   │   │   ├── game_score_display.dart
│   │   │   │   └── game_dialogs.dart    # Dialog widgets
│   │   │   ├── game_screen.dart         # Main game screen
│   │   │   └── instructions_screen.dart # Tutorial
│   │   ├── leaderboard/
│   │   │   ├── leaderboard_screen.dart  # Rankings UI
│   │   │   ├── models/
│   │   │   │   └── score_entry.dart
│   │   │   └── widgets/
│   │   │       └── leaderboard_list.dart
│   │   └── website/
│   │       └── website_screen.dart      # Web view
│   ├── shared/
│   │   ├── models/
│   │   │   ├── game_board.dart          # Core game model
│   │   │   ├── tile.dart                # Tile model
│   │   │   └── game_constants.dart      # Game constants
│   │   └── widgets/
│   │       ├── custom_button.dart
│   │       └── loading_indicator.dart
│   ├── l10n/
│   │   ├── app_localizations.dart       # Localization
│   │   ├── en.json
│   │   └── es.json
│   └── main.dart                        # App entry point
├── test/
│   ├── models/
│   │   └── game_board_test.dart
│   ├── services/
│   │   └── cache_service_test.dart
│   ├── widgets/
│   │   ├── widget_test.dart
│   │   └── game_grid_test.dart
│   └── integration/
│       ├── game_provider_integration_test.dart
│       └── game_screen_integration_test.dart
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Core Layers

### 1. Core Layer (`lib/core/`)

**Responsibility**: Application-wide services and configuration

#### Config Subpackage

```dart
// firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions currentPlatform => 
    defaultTargetPlatform == TargetPlatform.iOS 
      ? iOS 
      : android;
  
  static const FirebaseOptions iOS = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_IOS'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_IOS'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
    // ...
  );
}
```

#### Services Subpackage

Each service is a singleton responsible for one domain:

```dart
// analytics_service.dart
class AnalyticsService {
  static const _instance = AnalyticsService._();
  
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  factory AnalyticsService() => _instance;
  
  AnalyticsService._();
  
  // Event logging methods
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }
  
  Future<void> logLevelStart({required int level}) async {
    await _analytics.logEvent(
      name: 'level_start',
      parameters: {'level': level},
    );
  }
}
```

#### Dependency Injection

```dart
// di/service_locator.dart
void setupServiceLocator() {
  // Register singleton services
  getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  getIt.registerSingleton<AdService>(AdService());
  getIt.registerSingleton<PurchaseService>(PurchaseService());
  getIt.registerSingleton<ConsentService>(ConsentService());
  getIt.registerSingleton<CacheService>(CacheService());
  getIt.registerSingleton<AssetService>(AssetService());
  getIt.registerSingleton<LeaderboardService>(LeaderboardService());
}

// Usage in features
final analytics = getIt<AnalyticsService>();
```

### 2. Features Layer (`lib/features/`)

**Responsibility**: Business logic and UI for specific features

#### Feature Structure (Game Feature Example)

```
game/
├── models/
│   ├── game_state.dart      # Immutable state model
│   └── cell_position.dart   # Supporting models
├── providers/
│   └── game_provider.dart   # ChangeNotifier for state
├── widgets/
│   ├── game_grid.dart       # Composition of cells
│   ├── game_cell.dart       # Individual cell UI
│   └── dialogs.dart         # Dialog definitions
└── game_screen.dart         # Entry point screen
```

#### Game Model (Immutable)

```dart
// models/game_state.dart
class GameState {
  final GameBoard gameBoard;
  final int level;
  final int highScore;
  final int remainingMoves;
  final CellPosition? selectedCell;
  final bool isGameOver;
  final bool isLevelComplete;

  const GameState({
    required this.gameBoard,
    required this.level,
    required this.highScore,
    required this.remainingMoves,
    this.selectedCell,
    this.isGameOver = false,
    this.isLevelComplete = false,
  });

  // Immutable copy with selective updates
  GameState copyWith({
    GameBoard? gameBoard,
    int? level,
    int? highScore,
    int? remainingMoves,
    CellPosition? selectedCell,
    bool? isGameOver,
    bool? isLevelComplete,
  }) {
    return GameState(
      gameBoard: gameBoard ?? this.gameBoard,
      level: level ?? this.level,
      highScore: highScore ?? this.highScore,
      remainingMoves: remainingMoves ?? this.remainingMoves,
      selectedCell: selectedCell ?? this.selectedCell,
      isGameOver: isGameOver ?? this.isGameOver,
      isLevelComplete: isLevelComplete ?? this.isLevelComplete,
    );
  }

  // Equality override for state comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameState &&
        other.gameBoard == gameBoard &&
        other.level == level &&
        other.highScore == highScore &&
        other.remainingMoves == remainingMoves &&
        other.selectedCell == selectedCell &&
        other.isGameOver == isGameOver &&
        other.isLevelComplete == isLevelComplete;
  }

  @override
  int get hashCode => Object.hash(
    gameBoard,
    level,
    highScore,
    remainingMoves,
    selectedCell,
    isGameOver,
    isLevelComplete,
  );
}
```

#### State Provider (ChangeNotifier)

```dart
// providers/game_provider.dart
class GameProvider extends ChangeNotifier {
  GameState _gameState;
  final AnalyticsService _analyticsService;
  final AdService _adService;

  GameProvider({
    required GameState initialState,
    required AnalyticsService analyticsService,
    required AdService adService,
  })  : _gameState = initialState,
        _analyticsService = analyticsService,
        _adService = adService;

  // Public getters for immutable state
  GameState get gameState => _gameState;
  GameBoard get gameBoard => _gameState.gameBoard;
  int get level => _gameState.level;
  int get highScore => _gameState.highScore;
  int get remainingMoves => _gameState.remainingMoves;
  CellPosition? get selectedCell => _gameState.selectedCell;
  bool get isGameOver => _gameState.isGameOver;
  bool get isLevelComplete => _gameState.isLevelComplete;

  // Public action methods
  void handleTap(int row, int col) {
    if (_gameState.selectedCell == null) {
      // Select cell
      _gameState = _gameState.copyWith(selectedCell: CellPosition(row, col));
    } else {
      // Attempt move
      final int dRow = row - _gameState.selectedCell!.row;
      final int dCol = col - _gameState.selectedCell!.col;
      
      if ((dRow.abs() == 1 && dCol == 0) || 
          (dRow == 0 && dCol.abs() == 1)) {
        _move(_gameState.selectedCell!.row, 
              _gameState.selectedCell!.col, dRow, dCol);
      }
      
      _gameState = _gameState.copyWith(selectedCell: null);
    }
    notifyListeners();
  }

  // Private implementation methods
  void _move(int row, int col, int dRow, int dCol) {
    if (_gameState.remainingMoves <= 0) return;

    final newBoard = _gameState.gameBoard.move(row, col, dRow, dCol);
    if (newBoard != null) {
      _gameState = _gameState.copyWith(
        gameBoard: newBoard,
        remainingMoves: _gameState.remainingMoves - 1,
      );
      
      _analyticsService.logMove(type: 'tap');
      _checkWinLose();
    }
  }

  void _checkWinLose() {
    if (_gameState.gameBoard.isBoardClear()) {
      _gameState = _gameState.copyWith(isLevelComplete: true);
      _analyticsService.logLevelComplete(
        level: _gameState.level,
        score: _gameState.gameBoard.score,
      );
      return;
    }

    if (_gameState.remainingMoves <= 0 && 
        !_gameState.gameBoard.isBoardClear()) {
      _gameState = _gameState.copyWith(isGameOver: true);
      _analyticsService.logGameOver(score: _gameState.gameBoard.score);
    }
  }
}
```

### 3. Shared Layer (`lib/shared/`)

**Responsibility**: Cross-feature models and components

#### GameBoard (Core Game Logic)

```dart
// shared/models/game_board.dart
class GameBoard {
  final List<List<int?>> grid;
  final int rows = 4;
  final int cols = 4;
  final int level;
  final int score;
  final int remainingMoves;
  final bool isFrozen;

  const GameBoard({
    required this.grid,
    required this.level,
    this.score = 0,
    this.remainingMoves = 20,
    this.isFrozen = false,
  });

  // Factory for initialization
  factory GameBoard({
    required int level,
  }) {
    // Generate empty grid
    final grid = List.generate(4, (_) => List<int?>.filled(4, null));
    
    // Populate with difficulty
    return GameBoard._(
      grid: grid,
      level: level,
    ).populateRandomly(
      numbersToPlace: 8 + level ~/ 2,
      maxCellValue: min(9, 4 + level ~/ 2),
      level: level,
    );
  }

  // Core operations
  GameBoard? move(int fromRow, int fromCol, int toRow, int toCol) {
    if (!isValidMove(fromRow, fromCol, toRow, toCol)) {
      return null;
    }

    final sourceValue = grid[fromRow][fromCol];
    if (sourceValue == null) return null;

    final newGrid = _copyGrid();
    final targetValue = newGrid[toRow][toCol];

    if (targetValue == null) {
      // Move to empty cell
      newGrid[toRow][toCol] = sourceValue;
      newGrid[fromRow][fromCol] = null;
    } else {
      // Modulo operation
      final result = targetValue % sourceValue;
      newGrid[toRow][toCol] = result == 0 ? null : result;
      newGrid[fromRow][fromCol] = null;
    }

    return _copyWith(grid: newGrid);
  }

  // State queries
  bool isBoardClear() => 
    grid.every((row) => row.every((cell) => cell == null));

  bool hasValidMoves() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null &&
            (isValidMove(r, c, r - 1, c) ||
             isValidMove(r, c, r + 1, c) ||
             isValidMove(r, c, r, c - 1) ||
             isValidMove(r, c, r, c + 1))) {
          return true;
        }
      }
    }
    return false;
  }

  // Utility methods
  bool isValidMove(int fromRow, int fromCol, 
                   int toRow, int toCol) {
    if (!_inBounds(toRow, toCol)) return false;
    if ((fromRow - toRow).abs() + 
        (fromCol - toCol).abs() != 1) return false;
    return grid[fromRow][fromCol] != null;
  }

  bool _inBounds(int row, int col) => 
    row >= 0 && row < rows && col >= 0 && col < cols;

  List<List<int?>> _copyGrid() => 
    List.from(grid.map((row) => List<int?>.from(row)));

  GameBoard _copyWith({required List<List<int?>> grid}) =>
    GameBoard(
      grid: grid,
      level: level,
      score: score,
      remainingMoves: remainingMoves,
      isFrozen: isFrozen,
    );
}
```

---

## State Management Pattern

### Provider Pattern Overview

```dart
// Provider setup in GameScreen
ChangeNotifierProvider<GameProvider>(
  create: (context) {
    final provider = GameProvider(
      initialState: GameState(...),
      analyticsService: getIt<AnalyticsService>(),
      adService: getIt<AdService>(),
    );
    provider.initialize();
    return provider;
  },
  child: _GameScreenContent(),
)
```

### Reactive Widget Building

```dart
// Consume state with Consumer
Consumer<GameProvider>(
  builder: (context, gameProvider, child) {
    return GameGrid(
      gameBoard: gameProvider.gameBoard,
      onTap: gameProvider.handleTap,
      selectedCell: gameProvider.selectedCell,
    );
  },
)

// Or with selector for specific fields
Selector<GameProvider, int>(
  selector: (_, provider) => provider.remainingMoves,
  builder: (context, moves, _) {
    return Text('Moves: $moves');
  },
)
```

---

## Data Flows

### Game Session Flow

```
1. GameScreen created
   ↓
2. GameProvider initialized
   - Load high score from cache
   - Initialize analytics
   - Setup ad service
   ↓
3. initializeGameBoard()
   - Generate board
   - Reset state
   - Log level_start event
   ↓
4. Game screen rendered with GameState
   ↓
5. User interaction (handleTap)
   ↓
6. GameProvider updates _gameState
   ↓
7. notifyListeners() triggers rebuilds
   ↓
8. Consumers rebuild with new state
   ↓
9. Win/Lose condition checked
```

### Score Submission Flow

```
User completes level
   ↓
Collect score, level, timestamp
   ↓
Call Cloud Function (submitScore)
   ↓
Function validates and stores in Firestore
   ↓
Return confirmation to client
   ↓
Update GameProvider state
   ↓
Show success dialog
   ↓
Sync to leaderboard
```

---

## Testing Strategy

### Unit Testing (Game Logic)

```dart
// test/models/game_board_test.dart
void main() {
  group('GameBoard', () {
    test('should initialize with correct dimensions', () {
      final board = GameBoard(level: 1);
      expect(board.rows, equals(4));
      expect(board.cols, equals(4));
    });

    test('should execute modulo move correctly', () {
      var grid = List.generate(4, (_) => List<int?>.filled(4, null));
      grid[0][0] = 8;
      grid[0][1] = 3;

      final board = GameBoard(
        grid: grid,
        level: 1,
      );

      final result = board.move(0, 0, 0, 1);
      expect(result?.grid[0][1], equals(3)); // 3 % 8 = 3
      expect(result?.grid[0][0], isNull);
    });

    test('should clear tiles when modulo returns 0', () {
      var grid = List.generate(4, (_) => List<int?>.filled(4, null));
      grid[0][0] = 4;
      grid[0][1] = 8;

      final board = GameBoard(grid: grid, level: 1);
      final result = board.move(0, 0, 0, 1);

      expect(result?.grid[0][1], isNull); // 8 % 4 = 0
      expect(result?.isBoardClear(), isFalse);
    });
  });
}
```

### Widget Testing

```dart
// test/widgets/game_grid_test.dart
void main() {
  testWidgets('GameGrid renders correctly', (WidgetTester tester) async {
    final board = GameBoard(level: 1);
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameGrid(
            gameBoard: board,
            onTap: (row, col) => tapCount++,
            selectedCell: null,
          ),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsWidgets);
    
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(tapCount, equals(1));
  });
}
```

### Integration Testing

```dart
// test/integration/game_provider_integration_test.dart
void main() {
  group('GameProvider Integration Tests', () {
    late GameProvider gameProvider;
    late MockAnalyticsService mockAnalytics;

    setUp(() async {
      mockAnalytics = MockAnalyticsService();
      gameProvider = GameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 1),
          level: 1,
          highScore: 100,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: MockAdService(),
      );
      await gameProvider.initialize();
    });

    test('initializes with saved high score', () {
      expect(gameProvider.highScore, 100);
    });

    test('state updates trigger listeners', () async {
      var notified = false;
      gameProvider.addListener(() => notified = true);

      gameProvider.handleTap(0, 0);

      expect(notified, true);
    });
  });
}
```

---

## Performance Optimization

### Widget Optimization

1. **Use Const Constructors**: Prevent unnecessary rebuilds
   ```dart
   const GameCell(value: 5, onTap: handleTap)
   ```

2. **Selector for Specific State**: Rebuild only when needed
   ```dart
   Selector<GameProvider, GameBoard>(
     selector: (_, p) => p.gameBoard,
     builder: (_, board, __) => GameGrid(board: board),
   )
   ```

3. **Lazy Loading**: Load assets on demand
   ```dart
   getIt<AssetService>().preloadAssets()
   ```

### State Management Optimization

- Immutable models prevent accidental mutations
- `copyWith` creates new instances only when needed
- Provider pattern reduces widget tree depth
- Selective rebuilds via Consumer/Selector

### Memory Optimization

- Cache game boards in memory
- Release resources in `dispose()`
- Lazy initialize expensive services
- Stream cleanup in providers

---

## Best Practices

### Code Organization

✅ **DO**:
- One type per file
- Logical grouping by feature
- Clear public/private boundaries
- Self-documenting code

❌ **DON'T**:
- Mix concerns in a single file
- Deep nesting (>3 levels)
- God classes (>500 lines)
- Unclear naming

### State Management

✅ **DO**:
- Keep state immutable
- Use `copyWith` for updates
- Separate UI logic from business logic
- Test state independently

❌ **DON'T**:
- Mutate state directly
- Mix UI and business logic
- Pass context through providers
- Create overly complex state structures

### Testing

✅ **DO**:
- Test business logic independently
- Mock external dependencies
- Test edge cases
- Keep tests focused

❌ **DON'T**:
- Test framework code
- Create brittle widget tests
- Mock unnecessarily
- Test multiple concerns in one test

---

## Related Documentation

- [System Architecture](SYSTEM_ARCHITECTURE.md)
- [Game Mechanics](GAME_MECHANICS.md)
- [Testing Guide](TESTING.md)
- [Developer Guide](DEVELOPER_GUIDE.md)
