import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:modulo_squares/core/services/gamertag_service.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/controllers/falling_game_loop_controller.dart';
import 'package:modulo_squares/features/game/leaderboard_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';
import 'package:modulo_squares/features/game/widgets/game_board.dart';
import 'package:modulo_squares/features/game/widgets/game_hud.dart';
import 'package:modulo_squares/features/game/widgets/game_settings_dialog.dart';
import 'package:modulo_squares/features/game/widgets/how_to_play_sheet.dart';
import 'package:modulo_squares/features/game/widgets/pause_overlay.dart';
import 'package:modulo_squares/features/game/widgets/pre_game_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The falling-mode game screen: a thin composition root over
/// [FallingGameLoopController] (the actual game loop -- timer, movement,
/// tile resolution) and a handful of presentation widgets ([GameHud],
/// [GameBoard], [PreGameOverlay], [PauseOverlay]).
///
/// This class owns exactly what the controller deliberately doesn't:
/// BuildContext-dependent side effects of a resolved tile (leaderboard
/// submission, the level-complete ad/snackbar), navigation (Settings,
/// Leaderboard, confirmation dialogs), player identity, theme, and
/// preference persistence. See [FallingGameLoopController]'s doc comment
/// for why that split exists.
class FallingModuloGameScreen extends StatefulWidget {
  const FallingModuloGameScreen({
    super.key,
    this.engine,
    this.expertDemo = false,
    this.playerNameOverride,
    this.leaderboardBuilder,
  });

  /// Optional deterministic engine used by tests and local store-media capture.
  /// The release entry point leaves this null and uses normal game randomness.
  final FallingModuloGameEngine? engine;

  /// Drives real left/right/drop actions toward the highest-scoring valid
  /// divisor. This is disabled by default and enabled only by the local store
  /// capture entry point when STORE_CAPTURE_EXPERT_DEMO is defined.
  final bool expertDemo;

  /// Local media/test hooks. Production entry points leave these null and use
  /// the authenticated player's gamertag plus the live leaderboard screen.
  final String? playerNameOverride;
  final WidgetBuilder? leaderboardBuilder;

  @override
  State<FallingModuloGameScreen> createState() =>
      _FallingModuloGameScreenState();
}

class _FallingModuloGameScreenState extends State<FallingModuloGameScreen> {
  static const Duration _expertDemoTick = Duration(milliseconds: 16);
  static const String _highScorePrefKey = 'fallingMode.highScore';
  static const String _difficultyPrefKey = 'fallingMode.difficulty';
  static const String _themePrefKey = 'fallingMode.theme';

  late final FallingGameLoopController _controller;
  Timer? _expertDemoTimer;
  Timer? _expertDemoStartTimer;
  String? _playerName;
  GameThemeId _themeId = GameThemeId.deepOcean;

  GameThemePalette get _theme => gameThemePalettes[_themeId]!;

  AdService? get _adServiceOrNull =>
      getIt.isRegistered<AdService>() ? getIt<AdService>() : null;

  PurchaseService? get _purchaseServiceOrNull =>
      getIt.isRegistered<PurchaseService>() ? getIt<PurchaseService>() : null;

  @override
  void initState() {
    super.initState();
    _controller = FallingGameLoopController(
      engine: widget.engine ?? FallingModuloGameEngine(),
      onTileResolved: _handleTileResolved,
    );
    _controller.addListener(_onControllerChanged);
    _loadPreferences();
    _loadPlayerName();

    if (widget.expertDemo) {
      _expertDemoTimer = Timer.periodic(
        _expertDemoTick,
        (_) => _driveExpertDemo(),
      );
      _expertDemoStartTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted || _controller.hasStarted) return;
        _controller.toggleRunning();
      });
    }
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final highScore = prefs.getInt(_highScorePrefKey) ?? 0;
    final difficulty = _difficultyFromName(prefs.getString(_difficultyPrefKey));
    final themeId = _themeIdFromName(prefs.getString(_themePrefKey));

    if (!mounted) return;
    _controller.loadPersisted(highScore: highScore, difficulty: difficulty);
    setState(() => _themeId = themeId);
  }

  static GameDifficulty _difficultyFromName(String? name) {
    return GameDifficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => GameDifficulty.normal,
    );
  }

  static GameThemeId _themeIdFromName(String? name) {
    return GameThemeId.values.firstWhere(
      (t) => t.name == name,
      orElse: () => GameThemeId.deepOcean,
    );
  }

  Future<void> _loadPlayerName() async {
    if (widget.playerNameOverride != null) {
      setState(() => _playerName = widget.playerNameOverride);
      return;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final tag = await GamertagService.getGamertag(uid);
      if (!mounted) return;
      setState(() => _playerName = tag);
    } catch (_) {
      // Firebase not initialized in test environment.
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _expertDemoTimer?.cancel();
    _expertDemoStartTimer?.cancel();
    super.dispose();
  }

  // Runs on its own timer (rather than as a hook inside the controller's own
  // tick) so the production game loop stays entirely free of this
  // test/capture-only concept -- it only ever touches the controller's
  // public API, exactly as a real player's input would.
  void _driveExpertDemo() {
    if (!widget.expertDemo ||
        !_controller.isRunning ||
        _controller.isSpawnDelayActive) {
      return;
    }

    final state = _controller.state;
    final targetLane =
        _controller.engine.highestDivisorBucketIndex(state) ??
        state.currentLane;
    if (state.currentLane < targetLane) {
      _controller.moveRight();
      return;
    }
    if (state.currentLane > targetLane) {
      _controller.moveLeft();
      return;
    }

    // Let the falling tile visibly enter the board before making a crisp,
    // deliberate drop. All scoring and combo changes still flow through the
    // production engine's normal resolution path.
    if (_controller.dropProgress >= 0.10) {
      _controller.resolveCurrentTile();
    }
  }

  // The context-dependent side effects of a resolved tile: leaderboard
  // submission, high-score persistence, and the level-complete ad/snackbar.
  // The controller reports *that* a tile resolved and how; everything here
  // needs BuildContext (ads, ScaffoldMessenger) or a service call the
  // controller has no business making itself.
  void _handleTileResolved(TileResolutionOutcome outcome) {
    _persistHighScore();

    final playerName = _playerName;
    // Never write to the live leaderboard from the local media-capture /
    // test entry point: playerNameOverride is set only there, and
    // production always leaves it null and uses the authenticated player's
    // gamertag.
    if (widget.playerNameOverride == null &&
        outcome.isNewHighScore &&
        playerName != null &&
        playerName.isNotEmpty) {
      unawaited(
        LeaderboardService.submitScore(
          context,
          playerName,
          _controller.state.score,
        ),
      );
    }

    if (outcome.result.resolution.leveledUp) {
      // The engine only ever increments the level by exactly one per
      // resolve, so the level just completed is always the new level minus
      // one.
      final completedLevel = _controller.state.level - 1;
      unawaited(
        _showInterstitialTransition(trigger: 'level_complete', onClosed: () {}),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Level $completedLevel complete!')));
    }
  }

  Future<void> _persistDifficulty(GameDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyPrefKey, difficulty.name);
  }

  Future<void> _persistTheme(GameThemeId themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, themeId.name);
  }

  Future<void> _persistHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScorePrefKey, _controller.highScore);
  }

  Future<void> _confirmNewRun(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Start a new run?'),
            content: const Text(
              'Your current score and progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('New Run'),
              ),
            ],
          ),
    );
    if (confirmed == true) _controller.startNewRun();
  }

  Future<void> _showInterstitialTransition({
    required String trigger,
    required VoidCallback onClosed,
  }) async {
    final adService = _adServiceOrNull;
    if (adService == null) {
      onClosed();
      return;
    }

    await adService.showInterstitial(
      trigger: trigger,
      levelNum: _controller.state.level,
      onClosed: onClosed,
    );
  }

  Future<void> _openLeaderboard() async {
    // Settings and Leaderboard don't stop the game loop just by pushing a
    // route/dialog on top of it -- unlike the dedicated Pause button,
    // neither otherwise touches the controller's running state, so the drop
    // timer, deficit, and score would otherwise keep advancing behind
    // either screen.
    _controller.pause();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            widget.leaderboardBuilder ??
            (_) => LeaderboardScreen(playerName: _playerName ?? ''),
      ),
    );
  }

  Future<void> _openSettingsDialog() async {
    _controller.pause();
    await showGameSettingsDialog(
      context: context,
      difficulty: _controller.state.difficulty,
      getHighScore: () => _controller.highScore,
      purchaseService: _purchaseServiceOrNull,
      onSaveDifficulty: (difficulty) {
        _controller.setDifficulty(difficulty);
        _persistDifficulty(difficulty);
      },
      onHighScoreReset: () {
        if (mounted) _controller.resetHighScore();
      },
      highScorePrefKey: _highScorePrefKey,
      themeId: _themeId,
      onSaveTheme: (themeId) {
        setState(() => _themeId = themeId);
        _persistTheme(themeId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final isRunning = _controller.isRunning;

    return Scaffold(
      backgroundColor: _theme.pageBg,
      appBar: AppBar(
        title: const Text('Modulo Squares'),
        backgroundColor: _theme.appBarBg,
        foregroundColor: _theme.appBarFg,
        actions: [
          if (isRunning)
            IconButton(
              tooltip: 'Pause',
              onPressed: _controller.toggleRunning,
              icon: const Icon(Icons.pause),
            ),
          IconButton(
            tooltip: 'Leaderboard',
            onPressed: _openLeaderboard,
            icon: const Icon(Icons.leaderboard),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          // Only vertical padding here -- the board below gets its own,
          // narrower horizontal inset so it reads wider than its siblings,
          // which keep the standard 16px margin applied individually below.
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GameHud(
                  state: state,
                  highScore: _controller.highScore,
                  isRunning: isRunning,
                  isSpawnDelayActive: _controller.isSpawnDelayActive,
                  effectiveDropIntervalMs: _controller.effectiveDropIntervalMs,
                  theme: _theme,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameBoard(
                        state: state,
                        theme: _theme,
                        dropProgress: _controller.dropProgress,
                        resultBurstText: _controller.resultBurstText,
                        resultBurstPositive: _controller.resultBurstPositive,
                        resultBurstBonus: _controller.resultBurstBonus,
                      ),
                      if (!isRunning && !_controller.hasStarted)
                        PreGameOverlay(
                          theme: _theme,
                          onStart: _controller.toggleRunning,
                          onShowHowToPlay: () => showHowToPlaySheet(context),
                        ),
                      if (!isRunning && _controller.hasStarted)
                        PauseOverlay(
                          level: state.level,
                          score: state.score,
                          onResume:
                              () => _showInterstitialTransition(
                                trigger: 'resume_from_pause',
                                onClosed: _controller.toggleRunning,
                              ),
                          onNewGame: () => _confirmNewRun(context),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  key: const Key('drop-progress-indicator'),
                  value: _controller.dropProgress,
                  backgroundColor: _theme.progressTrack,
                  valueColor: AlwaysStoppedAnimation(_theme.progressFill),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ConstrainedBox(
                        // minHeight, not a fixed height: Material 3's .icon
                        // buttons switch from a Row to a Column layout at
                        // large accessibility text scales, which needs more
                        // vertical space than the baseline 72.
                        constraints: const BoxConstraints(minHeight: 72),
                        child: FilledButton.tonalIcon(
                          onPressed: isRunning ? _controller.moveLeft : null,
                          icon: const Icon(Icons.chevron_left, size: 32),
                          label: const Text(
                            'Left',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _theme.buttonTonalBg,
                            foregroundColor: _theme.buttonTonalFg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 72),
                        child: FilledButton.icon(
                          onPressed:
                              (isRunning && !_controller.isSpawnDelayActive)
                                  ? _controller.resolveCurrentTile
                                  : null,
                          icon: const Icon(
                            Icons.vertical_align_bottom,
                            size: 28,
                          ),
                          label: const Text(
                            'Drop',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _theme.buttonPrimaryBg,
                            foregroundColor: _theme.buttonPrimaryFg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 72),
                        child: FilledButton.tonalIcon(
                          onPressed: isRunning ? _controller.moveRight : null,
                          icon: const Icon(Icons.chevron_right, size: 32),
                          iconAlignment: IconAlignment.end,
                          label: const Text(
                            'Right',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _theme.buttonTonalBg,
                            foregroundColor: _theme.buttonTonalFg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
