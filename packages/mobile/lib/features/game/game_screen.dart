import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modulo_squares/features/game/providers/game_provider.dart';
import 'package:modulo_squares/features/game/models/game_state.dart';
import 'package:modulo_squares/shared/models/game_board.dart' as game_board;
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:modulo_squares/features/game/instructions_screen.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/features/game/widgets/game_level_info.dart';
import 'package:modulo_squares/features/game/widgets/game_score_display.dart';
import 'package:modulo_squares/features/game/widgets/game_grid.dart';
import 'package:modulo_squares/features/game/widgets/game_app_bar_actions.dart';
import 'package:modulo_squares/features/game/widgets/game_dialogs.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/ad_service.dart';

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

class _GameScreenContentState extends State<_GameScreenContent> with GameDialogs {
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = getIt<AnalyticsService>();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final purchaseService = getIt<PurchaseService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        actions: [
          GameAppBarActions(
            onShowLeaderboard: () => _showLeaderboardDialog(context),
            onShowInstructions: () => _showInstructions(context),
            onShowSpecialTilesInfo: () => _showSpecialTilesInfo(context),
            onShowPurchaseDialog: () => _showPurchaseDialog(context, purchaseService),
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
          _buildRestartButton(context, gameProvider),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(GameProvider gameProvider) {
    return GameLevelInfo(
      level: gameProvider.level,
      remainingMoves: gameProvider.remainingMoves,
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
      onPressed: () => gameProvider.restartWithAd(() => gameProvider.restartLevel()),
      child: Text(AppLocalizations.of(context).restart),
    );
  }

  void _showLeaderboardDialog(BuildContext context) {
    _analyticsService.logViewLeaderboard();
    showLeaderboardDialog(context);
  }

  void _showInstructions(BuildContext context) {
    _analyticsService.logViewInstructions();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InstructionsScreen()),
    );
  }

  void _showSpecialTilesInfo(BuildContext context) {
    _analyticsService.logSpecialTilesInfo();
    showSpecialTilesInfo(context);
  }

  void _showPurchaseDialog(BuildContext context, PurchaseService purchaseService) {
    showPurchaseDialog(context, purchaseService);
  }

  void _showTileEffectInfo(BuildContext context, game_board.Tile tile) {
    String effect = '';
    switch (tile.type) {
      case game_board.TileType.obstacle:
        effect = AppLocalizations.of(context).obstacleTooltip;
        break;
      case game_board.TileType.bonus:
        effect = AppLocalizations.of(context).bonusTooltip;
        break;
      case game_board.TileType.normal:
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(effect),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
