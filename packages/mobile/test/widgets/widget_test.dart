import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:modulo_squares/features/game/game_screen.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/shared/widgets/grid_cell_widget.dart';
import 'package:modulo_squares/shared/models/game_board.dart';

void main() {
  setUpAll(() {
    // Setup service locator for tests
    setupServiceLocator();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen displays HUD and controls', (
    WidgetTester tester,
  ) async {
    // Increase the test surface to avoid overflow with the square grid + controls
    final view = tester.view;
    view.physicalSize = const Size(1200, 2200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', '')],
        home: GameScreen(),
      ),
    );
    // Allow initial async state (e.g., SharedPreferences load) to settle
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(ctx);
    expect(l10n, isNotNull);

    expect(find.text('Modulo Squares'), findsWidgets);
    expect(find.textContaining('Score:'), findsWidgets);
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Drop'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
  });

  group('GridCellWidget', () {
    testWidgets('displays normal tile with value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(tile: const Tile(value: 5), isSelected: false),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('displays obstacle tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(
              tile: const Tile(type: TileType.obstacle),
              isSelected: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('displays bonus tile with value and star', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(
              tile: const Tile(type: TileType.bonus, value: 10),
              isSelected: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows selected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(tile: const Tile(value: 3), isSelected: true),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      // The selected state changes the background color, but we can't easily test color in widget tests
      // We verify the widget builds without error and displays the correct content
    });

    testWidgets('displays empty tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(tile: const Tile(), isSelected: false),
          ),
        ),
      );

      // Empty tile should not display any text or icons
      expect(find.byType(Text), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('handles possible target state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(
              tile: const Tile(value: 7),
              isSelected: false,
              isPossibleTarget: true,
            ),
          ),
        ),
      );

      expect(find.text('7'), findsOneWidget);
      // isPossibleTarget doesn't change visual appearance in this implementation
    });

    testWidgets('handles just changed animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(
              tile: const Tile(value: 2),
              isSelected: false,
              justChanged: true,
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      // justChanged triggers animation but doesn't change static appearance
    });

    testWidgets('has correct layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCellWidget(
              tile: const Tile(type: TileType.bonus, value: 8),
              isSelected: false,
            ),
          ),
        ),
      );

      // Find the GridCellWidget specifically and check its descendants
      final gridCellFinder = find.byType(GridCellWidget);
      expect(gridCellFinder, findsOneWidget);

      // Verify the widget has the expected structure within the GridCellWidget
      final stackFinder = find.descendant(
        of: gridCellFinder,
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsOneWidget);

      final animatedContainerFinder = find.descendant(
        of: gridCellFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainerFinder, findsOneWidget);
    });
  });
}
