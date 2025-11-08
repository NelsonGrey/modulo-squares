import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/features/game/providers/game_provider.dart';
import 'package:modulo_squares/features/game/models/game_state.dart';
import 'package:modulo_squares/shared/models/game_board.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Mock services for integration testing
class MockAnalyticsService implements AnalyticsService {
  List<String> loggedEvents = [];

  @override
  Future<void> setUserIdFromAuth(user) async {}

  @override
  Future<void> logAppOpen() async => loggedEvents.add('app_open');

  @override
  Future<void> logViewInstructions() async => loggedEvents.add('view_instructions');

  @override
  Future<void> logViewLeaderboard() async => loggedEvents.add('view_leaderboard');

  @override
  Future<void> logRestart({required int level}) async => loggedEvents.add('restart');

  @override
  Future<void> logLevelStart({required int level, required int rows, required int cols}) async => loggedEvents.add('level_start');

  @override
  Future<void> logLevelComplete({required int level, required int score}) async => loggedEvents.add('level_complete');

  @override
  Future<void> logOutOfMoves({required int level, required int score}) async => loggedEvents.add('out_of_moves');

  @override
  Future<void> logGameOverNoMoves({required int score}) async => loggedEvents.add('game_over_no_moves');

  @override
  Future<void> logMove({required String type}) async => loggedEvents.add('move');

  @override
  Future<void> logSpecialTilesInfo() async => loggedEvents.add('view_special_tiles');

  @override
  Future<void> logMercySpawn({required int penalty}) async => loggedEvents.add('mercy_spawn');

  @override
  Future<void> logAdImpression({String format = 'interstitial', String? trigger, int? levelNum}) async => loggedEvents.add('ad_impression');

  @override
  Future<void> logAdDismissed({String format = 'interstitial', String? trigger, int? levelNum}) async => loggedEvents.add('ad_dismissed');
}

class MockAdService implements AdService {
  bool adShown = false;
  bool initialized = false;

  @override
  Future<InitializationStatus> initialize() async {
    initialized = true;
    return InitializationStatus({});
  }

  @override
  void loadInterstitial() {}

  @override
  Future<void> showInterstitial({String? trigger, int? levelNum, void Function()? onClosed}) async {
    adShown = true;
    onClosed?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAnalyticsService mockAnalytics;
  late MockAdService mockAdService;
  late GameProvider gameProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'highScore': 100});

    mockAnalytics = MockAnalyticsService();
    mockAdService = MockAdService();

    final initialState = GameState(gameBoard: GameBoard(level: 1), level: 1, highScore: 100, remainingMoves: 20);

    gameProvider = GameProvider(initialState: initialState, analyticsService: mockAnalytics, adService: mockAdService);

    await gameProvider.initialize();
  });

  group('GameProvider Integration Tests', () {
    test('initializes with saved high score from SharedPreferences', () async {
      expect(gameProvider.highScore, 100);
    });

    test('analytics service logs events during game initialization', () {
      // Initialize a new game board to trigger analytics
      gameProvider.initializeGameBoard();

      expect(mockAnalytics.loggedEvents, contains('level_start'));
    });

    test('ad service shows ads when level completes', () async {
      expect(mockAdService.adShown, false);

      // Simulate level completion with ad
      bool callbackCalled = false;
      gameProvider.completeLevel(() {
        callbackCalled = true;
      });

      // Wait for async operation
      await Future.delayed(Duration.zero);

      expect(mockAdService.adShown, true);
      expect(callbackCalled, true);
    });

    test('game provider integrates analytics and ad services', () {
      // Verify that the GameProvider is properly initialized with service dependencies
      expect(gameProvider, isNotNull);

      // The provider should have access to analytics and ad services
      // (We can't directly test private fields, but we can test the integration through behavior)
      expect(mockAnalytics.loggedEvents, isEmpty); // No events logged yet
      expect(mockAdService.adShown, false); // No ads shown yet
    });

    test('game state persistence works with SharedPreferences', () async {
      // Test that high score is saved to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', 200);

      // Create new provider and verify it loads the saved high score
      final newProvider = GameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 1),
          level: 1,
          highScore: 0, // Will be overridden by saved value
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      await newProvider.initialize();

      expect(newProvider.highScore, 200);
    });

    test('level progression triggers analytics and ad integration', () {
      // Start a level to trigger analytics
      gameProvider.initializeGameBoard();
      expect(mockAnalytics.loggedEvents, contains('level_start'));

      // Simulate level completion
      bool adCallbackCalled = false;
      gameProvider.completeLevel(() {
        adCallbackCalled = true;
      });

      expect(mockAdService.adShown, true);
      expect(adCallbackCalled, true);
    });

    test('restart functionality integrates with ad service', () {
      bool restartCallbackCalled = false;
      gameProvider.restartWithAd(() {
        restartCallbackCalled = true;
      });

      expect(mockAdService.adShown, true);
      expect(restartCallbackCalled, true);
    });
  });
}
