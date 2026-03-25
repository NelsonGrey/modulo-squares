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
  Future<void> logViewInstructions() async =>
      loggedEvents.add('view_instructions');

  @override
  Future<void> logViewLeaderboard() async =>
      loggedEvents.add('view_leaderboard');

  @override
  Future<void> logRestart({required int level}) async =>
      loggedEvents.add('restart');

  @override
  Future<void> logLevelStart({
    required int level,
    required int rows,
    required int cols,
  }) async => loggedEvents.add('level_start');

  @override
  Future<void> logLevelComplete({
    required int level,
    required int score,
  }) async => loggedEvents.add('level_complete');

  @override
  Future<void> logOutOfMoves({required int level, required int score}) async =>
      loggedEvents.add('out_of_moves');

  @override
  Future<void> logGameOverNoMoves({required int score}) async =>
      loggedEvents.add('game_over_no_moves');

  @override
  Future<void> logMove({required String type}) async =>
      loggedEvents.add('move');

  @override
  Future<void> logSpecialTilesInfo() async =>
      loggedEvents.add('view_special_tiles');

  @override
  Future<void> logMercySpawn({required int penalty}) async =>
      loggedEvents.add('mercy_spawn');

  @override
  Future<void> logAdImpression({
    String format = 'interstitial',
    String? trigger,
    int? levelNum,
  }) async => loggedEvents.add('ad_impression');

  @override
  Future<void> logAdDismissed({
    String format = 'interstitial',
    String? trigger,
    int? levelNum,
  }) async => loggedEvents.add('ad_dismissed');

  @override
  Future<void> logDailyStart({required int challengeId}) async =>
      loggedEvents.add('daily_start');

  @override
  Future<void> logDailySubmit({
    required int challengeId,
    required int score,
    required bool submitted,
  }) async => loggedEvents.add('daily_submit');

  @override
  Future<void> logDailyRankAvailable({
    required int challengeId,
    required bool rankAvailable,
    int? rank,
  }) async => loggedEvents.add('daily_rank_available');

  @override
  Future<void> logWeeklySubmit({
    required int weekId,
    required int score,
    required bool submitted,
  }) async => loggedEvents.add('weekly_submit');

  @override
  Future<void> logWeeklyRankAvailable({
    required int weekId,
    required bool rankAvailable,
    int? rank,
  }) async => loggedEvents.add('weekly_rank_available');

  @override
  Future<void> logWeeklyBadgeEarned({
    required int weekId,
    required String badge,
    required int rank,
  }) async => loggedEvents.add('weekly_badge_earned');

  @override
  Future<void> logLevelRetry({
    required int level,
    required bool isDaily,
  }) async => loggedEvents.add('level_retry');

  @override
  Future<void> logLevelFailReason({
    required int level,
    required String reason,
    required int score,
    required bool isDaily,
  }) async => loggedEvents.add('level_fail_reason');

  @override
  Future<void> logLevelStarResult({
    required int level,
    required int stars,
    required int score,
    required int mercySpawns,
    required bool isDaily,
  }) async => loggedEvents.add('level_star_result');
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
  Future<void> showInterstitial({
    String? trigger,
    int? levelNum,
    void Function()? onClosed,
  }) async {
    adShown = true;
    onClosed?.call();
  }
}

// Lightweight provider used to isolate ad cadence behavior in tests
// without depending on randomized board generation in nextLevel().
class _AdCadenceTestGameProvider extends GameProvider {
  _AdCadenceTestGameProvider({
    required super.initialState,
    required super.analyticsService,
    required super.adService,
  });

  @override
  void nextLevel() {
    // Intentionally no-op for cadence-focused testing.
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

    final initialState = GameState(
      gameBoard: GameBoard(level: 1),
      level: 1,
      highScore: 100,
      remainingMoves: 20,
    );

    gameProvider = GameProvider(
      initialState: initialState,
      analyticsService: mockAnalytics,
      adService: mockAdService,
    );

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

    test('ad service shows ads every second level completion', () async {
      final adCadenceProvider = _AdCadenceTestGameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 1),
          level: 1,
          highScore: 100,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );
      await adCadenceProvider.initialize();

      expect(mockAdService.adShown, false);

      // First completion: no interstitial
      bool firstCallbackCalled = false;
      adCadenceProvider.completeLevel(() {
        firstCallbackCalled = true;
      });

      // Wait for async operation
      await Future.delayed(Duration.zero);

      expect(mockAdService.adShown, false);
      expect(firstCallbackCalled, true);

      // Second completion: should show interstitial
      bool secondCallbackCalled = false;
      adCadenceProvider.completeLevel(() {
        secondCallbackCalled = true;
      });
      await Future.delayed(Duration.zero);

      expect(mockAdService.adShown, true);
      expect(secondCallbackCalled, true);
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

    test('level progression triggers analytics and completion callbacks', () {
      // Start a level to trigger analytics
      gameProvider.initializeGameBoard();
      expect(mockAnalytics.loggedEvents, contains('level_start'));

      // Simulate level completion
      bool adCallbackCalled = false;
      gameProvider.completeLevel(() {
        adCallbackCalled = true;
      });

      expect(mockAdService.adShown, false);
      expect(adCallbackCalled, true);
    });

    test('restart callback runs even when ad is throttled', () {
      bool restartCallbackCalled = false;
      gameProvider.restartWithAd(() {
        restartCallbackCalled = true;
      });

      expect(mockAdService.adShown, false);
      expect(restartCallbackCalled, true);
    });

    test('level completion calculates stars and tracks best result', () async {
      final deterministicBoard = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 9,
        grid: [
          [Tile(value: 2), Tile(value: 4)],
          [Tile(), Tile()],
        ],
        level: 1,
      );

      final provider = GameProvider(
        initialState: GameState(
          gameBoard: deterministicBoard,
          level: 1,
          highScore: 0,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      provider.handleTap(0, 0);
      provider.handleTap(0, 1);
      await Future.delayed(Duration.zero);

      expect(provider.isLevelComplete, true);
      expect(provider.lastCompletedStars, 3);
      expect(provider.bestStarsForLevel(1), 3);
      expect(provider.bestScoreForLevel(1), provider.gameBoard.score);
      expect(provider.lastCompletionImprovedBest, true);
    });

    test('best stars persist across provider instances', () async {
      final deterministicBoard = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 9,
        grid: [
          [Tile(value: 2), Tile(value: 4)],
          [Tile(), Tile()],
        ],
        level: 1,
      );

      final firstProvider = GameProvider(
        initialState: GameState(
          gameBoard: deterministicBoard,
          level: 1,
          highScore: 0,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      firstProvider.handleTap(0, 0);
      firstProvider.handleTap(0, 1);
      await Future.delayed(const Duration(milliseconds: 10));

      final secondProvider = GameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 1),
          level: 1,
          highScore: 0,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      await secondProvider.initialize();

      expect(secondProvider.bestStarsForLevel(1), 3);
      expect(secondProvider.bestScoreForLevel(1), isNotNull);
    });

    test('daily challenge mode starts with deterministic challenge id', () {
      final provider = GameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 1),
          level: 1,
          highScore: 0,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      provider.startDailyChallenge(date: DateTime(2026, 3, 7));

      expect(provider.isDailyChallengeMode, true);
      expect(provider.activeDailyChallengeId, 20260307);
      expect(provider.remainingMoves, 14);
      expect(provider.dailyModifierLabel, 'Low Moves');
    });

    test('daily challenge replay keeps same challenge id', () {
      final provider = GameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 1),
          level: 1,
          highScore: 0,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      provider.startDailyChallenge(date: DateTime(2026, 3, 7));
      final firstChallengeId = provider.activeDailyChallengeId;
      provider.nextLevel();

      expect(provider.isDailyChallengeMode, true);
      expect(provider.activeDailyChallengeId, firstChallengeId);
    });

    test('exiting daily challenge returns to normal level mode', () {
      final provider = GameProvider(
        initialState: GameState(
          gameBoard: GameBoard(level: 3),
          level: 3,
          highScore: 0,
          remainingMoves: 20,
        ),
        analyticsService: mockAnalytics,
        adService: mockAdService,
      );

      provider.startDailyChallenge(date: DateTime(2026, 3, 7));
      provider.exitDailyChallengeMode();

      expect(provider.isDailyChallengeMode, false);
      expect(provider.activeDailyChallengeId, isNull);
      expect(provider.level, 3);
    });
  });
}
