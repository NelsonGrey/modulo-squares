import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modulo_squares/features/game/providers/game_provider.dart';
import 'package:modulo_squares/features/game/models/game_state.dart';
import 'package:modulo_squares/shared/models/game_board.dart' as game_board;
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:modulo_squares/features/game/instructions_screen.dart';
import 'package:modulo_squares/features/game/leaderboard_screen.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/features/game/widgets/game_level_info.dart';
import 'package:modulo_squares/features/game/widgets/game_score_display.dart';
import 'package:modulo_squares/features/game/widgets/game_grid.dart';
import 'package:modulo_squares/features/game/widgets/game_app_bar_actions.dart';
import 'package:modulo_squares/features/game/widgets/game_dialogs.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final analyticsService = getIt<AnalyticsService>();
        final adService = getIt<AdService>();

        final initialState = GameState(
          gameBoard: game_board.GameBoard(level: 1),
          level: 1,
          highScore: 0,
          remainingMoves: 20,
        );

        final provider = GameProvider(
          initialState: initialState,
          analyticsService: analyticsService,
          adService: adService,
        );

        // Initialize the provider
        provider.initialize().then((_) => provider.initializeGameBoard());

        return provider;
      },
      child: const _GameScreenContent(),
    );
  }
}

class _GameScreenContent extends StatefulWidget {
  const _GameScreenContent();

  @override
  State<_GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<_GameScreenContent>
    with GameDialogs {
  late final AnalyticsService _analyticsService;
  bool _isTerminalDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = getIt<AnalyticsService>();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final purchaseService = getIt<PurchaseService>();

    _handleTerminalGameStates(gameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          GameAppBarActions(
            onShowLeaderboard: () => _showLeaderboardDialog(context),
            onShowInstructions: () => _showInstructions(context),
            onShowSpecialTilesInfo: () => _showSpecialTilesInfo(context),
            onShowPurchaseDialog:
                () => _showPurchaseDialog(context, purchaseService),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLevelInfo(gameProvider),
          const SizedBox(height: 20),
          _buildScoreDisplay(gameProvider),
          const SizedBox(height: 20),
          _buildGrid(context, gameProvider),
          const SizedBox(height: 40),
          _buildActionButtons(context, gameProvider),
        ],
      ),
    );
  }

  void _handleTerminalGameStates(GameProvider gameProvider) {
    if (_isTerminalDialogOpen) return;

    if (gameProvider.isLevelComplete) {
      _isTerminalDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isTerminalDialogOpen = false;
          return;
        }
        _showLevelCompleteDialog(context, gameProvider);
      });
      return;
    }

    if (gameProvider.isGameOver) {
      _isTerminalDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isTerminalDialogOpen = false;
          return;
        }
        _showGameOverDialog(context, gameProvider);
      });
    }
  }

  void _showLevelCompleteDialog(
    BuildContext context,
    GameProvider gameProvider,
  ) {
    final int levelNum = gameProvider.level;
    final int score = gameProvider.gameBoard.score;
    final int stars = gameProvider.lastCompletedStars ?? 1;
    final bool isDaily = gameProvider.isDailyChallengeMode;
    final int? challengeId = gameProvider.activeDailyChallengeId;
    final int bestStars =
        isDaily
            ? (gameProvider.dailyBestStarsForChallenge(challengeId ?? 0) ??
                stars)
            : (gameProvider.bestStarsForLevel(levelNum) ?? stars);
    final int bestScore =
        isDaily
            ? (gameProvider.dailyBestScoreForChallenge(challengeId ?? 0) ??
                score)
            : (gameProvider.bestScoreForLevel(levelNum) ?? score);
    final String nextLabel = isDaily ? 'Replay Daily Challenge' : 'Next Level';
    final String bestLabel =
        isDaily
            ? 'Best Daily Result: ${_formatStars(bestStars)}'
            : 'Best for Level $levelNum: ${_formatStars(bestStars)}';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.youWin),
          content: Text(
            '${AppLocalizations.of(context)!.winMessage(score)}\n\n'
            'Stars: ${_formatStars(stars)}\n'
            'Par target hit: ${gameProvider.lastCompletionHitPar ? 'Yes' : 'No'}\n'
            'Elite target hit: ${gameProvider.lastCompletionHitElite ? 'Yes' : 'No'}\n'
            '$bestLabel\n'
            'Best Score: $bestScore'
            '${gameProvider.lastCompletionImprovedBest ? '\nNew personal best!' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String? submissionFeedback;
                if (isDaily && challengeId != null) {
                  final playerName = _currentPlayerName();
                  final submitted = await LeaderboardService.submitDailyScore(
                    context,
                    challengeId,
                    playerName,
                    score,
                  );
                  _analyticsService.logDailySubmit(
                    challengeId: challengeId,
                    score: score,
                    submitted: submitted,
                  );

                  final rank =
                      submitted
                          ? await LeaderboardService.getDailyRank(
                            challengeId,
                            playerName,
                          )
                          : null;
                  _analyticsService.logDailyRankAvailable(
                    challengeId: challengeId,
                    rankAvailable: rank != null,
                    rank: rank,
                  );

                  if (!submitted) {
                    submissionFeedback =
                        'Could not submit daily score. Please try again.';
                  } else if (rank != null) {
                    submissionFeedback =
                        'Daily score submitted. Current rank: #$rank';
                  } else {
                    submissionFeedback = 'Daily score submitted.';
                  }
                } else {
                  final playerName = _currentPlayerName();
                  await LeaderboardService.submitScore(
                    context,
                    playerName,
                    score,
                  );

                  final weekId = LeaderboardService.currentWeekId();
                  final weeklySubmitted =
                      await LeaderboardService.submitWeeklyScore(
                        context,
                        weekId,
                        playerName,
                        score,
                      );
                  _analyticsService.logWeeklySubmit(
                    weekId: weekId,
                    score: score,
                    submitted: weeklySubmitted,
                  );

                  if (weeklySubmitted) {
                    final rank = await LeaderboardService.getWeeklyRank(
                      weekId,
                      playerName,
                    );
                    _analyticsService.logWeeklyRankAvailable(
                      weekId: weekId,
                      rankAvailable: rank != null,
                      rank: rank,
                    );
                    if (rank != null) {
                      final badge = LeaderboardService.weeklyBadgeForRank(rank);
                      _analyticsService.logWeeklyBadgeEarned(
                        weekId: weekId,
                        badge: badge,
                        rank: rank,
                      );
                      submissionFeedback =
                          'Weekly ladder rank: #$rank ($badge badge)';
                    }
                  }
                }
                Navigator.of(dialogContext).pop();
                if (submissionFeedback != null && mounted) {
                  _showDailySubmissionFeedback(submissionFeedback);
                }
                gameProvider.completeLevel(() {});
              },
              child: Text(nextLabel),
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isTerminalDialogOpen = false;
        });
      } else {
        _isTerminalDialogOpen = false;
      }
    });
  }

  String _formatStars(int stars) {
    final int clamped = stars.clamp(1, 3);
    return '$clamped/3';
  }

  void _showGameOverDialog(BuildContext context, GameProvider gameProvider) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.gameOver),
          content: Text(
            AppLocalizations.of(
              context,
            )!.gameOverMessage(gameProvider.gameBoard.score),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                gameProvider.restartWithAd(() => gameProvider.restartLevel());
              },
              child: Text(AppLocalizations.of(context)!.playAgain),
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isTerminalDialogOpen = false;
        });
      } else {
        _isTerminalDialogOpen = false;
      }
    });
  }

  Widget _buildLevelInfo(GameProvider gameProvider) {
    return GameLevelInfo(
      level: gameProvider.level,
      remainingMoves: gameProvider.remainingMoves,
      parMoves: gameProvider.currentParMoves,
      eliteMoves: gameProvider.currentEliteMoves,
      dailyModifierLabel:
          gameProvider.isDailyChallengeMode
              ? gameProvider.dailyModifierLabel
              : null,
    );
  }

  Widget _buildScoreDisplay(GameProvider gameProvider) {
    return GameScoreDisplay(
      currentScore: gameProvider.gameBoard.score,
      highScore: gameProvider.highScore,
    );
  }

  Widget _buildGrid(BuildContext context, GameProvider gameProvider) {
    return GameGrid(
      gameBoard: gameProvider.gameBoard,
      selectedCell: gameProvider.selectedCell,
      onTap: gameProvider.handleTap,
      onSlide: gameProvider.handleSlide,
      onTileEffectInfo: (tile) => _showTileEffectInfo(context, tile),
    );
  }

  Widget _buildRestartButton(BuildContext context, GameProvider gameProvider) {
    return ElevatedButton(
      onPressed:
          () => gameProvider.restartWithAd(() => gameProvider.restartLevel()),
      child: Text(AppLocalizations.of(context)!.restart),
    );
  }

  Widget _buildActionButtons(BuildContext context, GameProvider gameProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRestartButton(context, gameProvider),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            if (gameProvider.isDailyChallengeMode) {
              gameProvider.exitDailyChallengeMode();
            } else {
              gameProvider.startDailyChallenge();
            }
          },
          child: Text(
            gameProvider.isDailyChallengeMode
                ? 'Exit Daily'
                : 'Daily Challenge',
          ),
        ),
      ],
    );
  }

  void _showLeaderboardDialog(BuildContext context) {
    _analyticsService.logViewLeaderboard();
    final provider = context.read<GameProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LeaderboardScreen(
              playerName: _currentPlayerName(),
              challengeId: provider.activeDailyChallengeId,
              startOnDaily: provider.isDailyChallengeMode,
            ),
      ),
    );
  }

  String _currentPlayerName() {
    final user = _safeCurrentUser();
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      final shortUid = uid.length <= 8 ? uid : uid.substring(0, 8);
      return 'Player-$shortUid';
    }
    return 'Anonymous';
  }

  User? _safeCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  void _showDailySubmissionFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showInstructions(BuildContext context) {
    _analyticsService.logViewInstructions();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstructionsScreen()));
  }

  void _showSpecialTilesInfo(BuildContext context) {
    _analyticsService.logSpecialTilesInfo();
    showSpecialTilesInfo(context);
  }

  void _showPurchaseDialog(
    BuildContext context,
    PurchaseService purchaseService,
  ) {
    showPurchaseDialog(context, purchaseService);
  }

  void _showTileEffectInfo(BuildContext context, game_board.Tile tile) {
    String effect = '';
    switch (tile.type) {
      case game_board.TileType.obstacle:
        effect = 'Obstacle tile blocks movement.';
        break;
      case game_board.TileType.bonus:
        effect = 'Bonus tile has special scoring behavior.';
        break;
      case game_board.TileType.normal:
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(effect), duration: const Duration(seconds: 2)),
    );
  }
}
