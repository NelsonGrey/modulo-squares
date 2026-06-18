
# Testing Guide

This guide covers the testing strategy and practices for the Modulo Squares Flutter application, including unit tests, widget tests, integration tests, and testing best practices.

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Unit Testing](#unit-testing)
5. [Widget Testing](#widget-testing)
6. [Integration Testing](#integration-testing)
7. [Test Coverage](#test-coverage)
8. [Testing Best Practices](#testing-best-practices)
9. [CI/CD Integration](#cicd-integration)

## Testing Overview

The Modulo Squares project uses a comprehensive testing strategy to ensure code quality and prevent regressions:

- **Unit Tests**: Test individual functions, methods, and classes in isolation
- **Widget Tests**: Test UI components and their interactions
- **Integration Tests**: Test complete user flows and service integrations
- **Manual Testing**: Exploratory testing and edge case validation

### Testing Tools
- **Flutter Test Framework**: Built-in testing framework
- **Mockito**: Mocking framework for dependencies
- **Fake Firebase**: Testing utilities for Firebase services

## Test Structure

```
test/
├── models/                          # Unit tests for data models
│   └── game_board_test.dart        # GameBoard logic tests
├── widgets/                         # Widget tests
│   └── widget_test.dart            # Basic widget rendering tests
├── services/                        # Service integration tests
│   ├── cache_service_test.dart     # Cache service tests
│   ├── error_handler_test.dart     # Error handling tests
│   └── leaderboard_service_test.dart # Leaderboard service tests
└── integration_test/               # End-to-end tests (future)
    └── app_test.dart
```

### Test File Naming Convention
- Unit tests: `[class_name]_test.dart`
- Widget tests: `[widget_name]_test.dart`
- Integration tests: `[feature]_test.dart`

## Running Tests

### Basic Test Execution
```bash
# Run all tests
flutter test

# Run tests in verbose mode
flutter test -v

# Run tests with detailed reporting
flutter test --reporter=expanded
```

### Test Filtering
```bash
# Run specific test file
flutter test test/models/game_board_test.dart

# Run tests matching pattern
flutter test --name="GameBoard"

# Run tests in specific directory
flutter test test/models/
```

### Test Coverage
```bash
# Generate coverage report
flutter test --coverage

# View coverage in browser (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Platform-Specific Testing
```bash
# Run tests for specific platform
flutter test --platform=vm  # Default Dart VM

# Run tests with platform-specific code
flutter test --platform=chrome  # Web platform
```

## Unit Testing

Unit tests verify the correctness of individual functions and classes in isolation.

### Game Board Testing (`test/models/game_board_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/shared/models/game_board.dart';

void main() {
  group('GameBoard', () {
    late GameBoard board;

    setUp(() {
      board = GameBoard.initial();
    });

    test('should initialize with correct dimensions', () {
      expect(board.rows, equals(4));
      expect(board.cols, equals(4));
    });

    test('should populate randomly with correct number of tiles', () {
      final populated = board.populateRandomly(
        numbersToPlace: 8,
        maxCellValue: 9,
      );

      int nonEmptyCells = 0;
      for (int row = 0; row < board.rows; row++) {
        for (int col = 0; col < board.cols; col++) {
          if (populated.getValue(row, col) != null) {
            nonEmptyCells++;
          }
        }
      }

      expect(nonEmptyCells, equals(8));
    });

    test('should perform modulo move correctly', () {
      // Set up board: [8, 4, ., .]
      final board = GameBoard.withGrid([
        [8, 4, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      // Move 8 into 4: 4 % 8 = 4 (no change since 8 > 4)
      final result = board.moveCell(0, 0, 0, 1);

      expect(result.success, isTrue);
      expect(result.newBoard.getValue(0, 1), equals(4)); // 4 % 8 = 4
      expect(result.newBoard.getValue(0, 0), isNull);    // Source cleared
    });

    test('should detect board clear condition', () {
      final emptyBoard = GameBoard.withGrid([
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(emptyBoard.isBoardClear(), isTrue);

      final populatedBoard = GameBoard.withGrid([
        [null, null, null, null],
        [null, 1, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(populatedBoard.isBoardClear(), isFalse);
    });

    test('should detect valid moves', () {
      final board = GameBoard.withGrid([
        [8, 4, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(board.hasValidMoves(), isTrue);

      final noMovesBoard = GameBoard.withGrid([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(noMovesBoard.hasValidMoves(), isFalse);
    });
  });
}
```

### Service Testing (`test/services/leaderboard_service_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('LeaderboardService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late LeaderboardService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      service = LeaderboardService();

      // Setup mock behavior
      when(mockFirestore.collection('modulo_leaderboard'))
          .thenReturn(mockCollection);
    });

    test('should submit score successfully', () async {
      final mockDoc = MockDocumentReference();
      when(mockCollection.doc('Player1')).thenReturn(mockDoc);
      when(mockDoc.set(any, any)).thenAnswer((_) async => null);

      await expectLater(
        service.submitScore('Player1', 1000),
        completes,
      );

      verify(mockDoc.set({
        'score': 1000,
        'timestamp': anyNamed('timestamp'),
      }, any)).called(1);
    });
  });
}
```

## Widget Testing

Widget tests verify that UI components render correctly and respond to user interactions.

### Basic Widget Test (`test/widgets/widget_test.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/shared/widgets/grid_cell_widget.dart';

void main() {
  testWidgets('GridCellWidget displays value correctly', (WidgetTester tester) async {
    // Test empty cell
    await tester.pumpWidget(
      MaterialApp(
        home: GridCellWidget(
          value: null,
          isSelected: false,
          isPossibleTarget: false,
        ),
      ),
    );

    expect(find.text(''), findsOneWidget);
    expect(find.byType(Container), findsOneWidget);

    // Test cell with value
    await tester.pumpWidget(
      MaterialApp(
        home: GridCellWidget(
          value: 5,
          isSelected: false,
          isPossibleTarget: false,
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('GridCellWidget shows selection state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GridCellWidget(
          value: 3,
          isSelected: true,
          isPossibleTarget: false,
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;

    // Selected cells should have blue background
    expect(decoration.color, equals(Colors.blue.withOpacity(0.3)));
  });

  testWidgets('GridCellWidget handles tap gestures', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GridCellWidget(
          value: 7,
          isSelected: false,
          isPossibleTarget: false,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(GridCellWidget));
    expect(tapped, isTrue);
  });
}
```

### Game Screen Testing

```dart
testWidgets('GameScreen displays game grid', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(),
    ),
  );

  // Wait for initial game setup
  await tester.pumpAndSettle();

  // Verify grid is displayed
  expect(find.byType(GridView), findsOneWidget);

  // Verify cells are present (4x4 = 16 cells)
  expect(find.byType(GridCellWidget), findsNWidgets(16));

  // Verify app bar shows level
  expect(find.textContaining('Level'), findsOneWidget);
});

testWidgets('GameScreen handles cell selection', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(),
    ),
  );

  await tester.pumpAndSettle();

  // Find a cell with a value and tap it
  final cellFinder = find.byType(GridCellWidget).first;
  await tester.tap(cellFinder);

  // Verify selection state changed
  await tester.pump();
  // Add verification for selection visual feedback
});
```

## Integration Testing

Integration tests verify complete user flows and service integrations.

### Firebase Integration Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() async {
    // Initialize with fake Firestore
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Leaderboard Integration', () {
    test('should submit and retrieve scores', () async {
      final service = LeaderboardService.withFirestore(fakeFirestore);

      // Submit scores
      await service.submitScore('Alice', 1000);
      await service.submitScore('Bob', 800);
      await service.submitScore('Charlie', 1200);

      // Retrieve top scores
      final scores = await service.getTopScores(limit: 2).first;

      expect(scores.length, equals(2));
      expect(scores[0].playerName, equals('Charlie'));
      expect(scores[0].score, equals(1200));
      expect(scores[1].playerName, equals('Alice'));
      expect(scores[1].score, equals(1000));
    });
  });
}
```

## Test Coverage

### Coverage Goals
- **Models**: 90%+ coverage (critical business logic)
- **Services**: 80%+ coverage (external integrations)
- **Widgets**: 70%+ coverage (UI components)
- **Overall**: 75%+ coverage

### Coverage Report Analysis
```bash
# Generate detailed coverage report
flutter test --coverage --coverage-path=coverage/lcov.info

# View coverage by file
lcov --list coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html --legend
```

### Coverage Configuration
Add to `analysis_options.yaml`:
```yaml
coverage:
  exclude:
    - 'lib/main.dart'
    - 'lib/**/*.g.dart'  # Generated files
  threshold:
    functions: 80
    branches: 70
    lines: 80
```

## Testing Best Practices

### Test Organization
- **Arrange-Act-Assert**: Structure tests clearly
- **One Concept Per Test**: Each test should verify one behavior
- **Descriptive Names**: Use descriptive test and group names
- **Independent Tests**: Tests should not depend on each other

### Mocking Strategy
```dart
// Use Mockito for complex dependencies
class MockAuthService extends Mock implements AuthService {}

// Use fake implementations for Firebase
final fakeFirestore = FakeFirebaseFirestore();

// Use stub implementations for simple cases
class StubLeaderboardService implements LeaderboardService {
  @override
  Future<void> submitScore(String name, int score) async {
    // Stub implementation
  }
}
```

### Async Testing
```dart
test('should handle async operations', () async {
  // Use expectLater for Futures
  expectLater(
    service.submitScore('Test', 100),
    completes,
  );

  // Use pumpAndSettle for widget tests
  await tester.pumpAndSettle();
});
```

### Error Testing
```dart
test('should handle network errors gracefully', () async {
  // Setup mock to throw exception
  when(mockService.submitScore(any, any))
      .thenThrow(Exception('Network error'));

  // Verify error handling
  expect(
    () => service.submitScore('Test', 100),
    throwsA(isA<Exception>()),
  );
});
```

### Performance Testing
```dart
test('should render grid efficiently', () async {
  final stopwatch = Stopwatch()..start();

  await tester.pumpWidget(GameGrid(board: testBoard));

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

### Pre-commit Hooks
```bash
#!/bin/sh
# Run tests before commit
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

### Automated Testing Checklist
- [ ] All unit tests pass
- [ ] Widget tests pass on multiple screen sizes
- [ ] Integration tests pass
- [ ] Code coverage meets thresholds
- [ ] Linting passes
- [ ] No breaking changes in public APIs

## Manual Testing

### Functional Testing Checklist
- [ ] Game grid displays correctly on different screen sizes
- [ ] Cell selection and movement work as expected
- [ ] Modulo arithmetic calculations are correct
- [ ] Win/lose conditions trigger appropriate dialogs
- [ ] Leaderboard submission and retrieval work
- [ ] Ads display correctly (if enabled)
- [ ] Offline mode functions properly

### Edge Cases to Test
- [ ] Moving tiles when no valid moves exist
- [ ] Submitting empty or invalid leaderboard names
- [ ] Network failures during leaderboard operations
- [ ] App backgrounding during gameplay
- [ ] Device rotation during gameplay
- [ ] Low memory conditions

### Device Testing Matrix
| Device/OS | Screen Size | Status |
|-----------|-------------|--------|
| iPhone SE | 375x667 | ✅ |
| iPhone 12 | 390x844 | ✅ |
| iPad | 768x1024 | ✅ |
| Pixel 4 | 393x851 | ✅ |
| Samsung S21 | 360x800 | ✅ |

## Troubleshooting

### Common Test Issues

**Tests Fail Randomly**
- Check for async operations without proper awaits
- Ensure test isolation (no shared state between tests)

**Widget Tests Don't Find Widgets**
- Use `pumpAndSettle()` for async UI updates
- Check widget tree structure with `debugDumpApp()`

**Mock Setup Issues**
- Verify mock methods are properly stubbed
- Use `verify()` to check method calls

**Coverage Not Generated**
- Ensure `--coverage` flag is used
- Check that test files are in the correct directory

### Debugging Tests
```dart
// Print widget tree for debugging
debugDumpApp();

// Print specific widget details
final element = tester.element(find.byType(MyWidget));
print(element.widget);

// Pause test execution
await Future.delayed(Duration(seconds: 10));
```

This comprehensive testing guide ensures the Modulo Squares application maintains high quality and reliability through thorough automated and manual testing practices.

