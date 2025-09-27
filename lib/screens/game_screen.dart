import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo/models/game_board.dart';
import 'package:modulo/models/cell_position.dart';
import 'package:modulo/widgets/grid_cell_widget.dart';
import 'package:modulo/leaderboard_service.dart';
import 'package:modulo/l10n/app_localizations.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameBoard gameBoard;
  int level = 1;
  int highScore = 0;
  int remainingMoves = 40;
  CellPosition? selectedCell;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initializeGameBoard();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void _initializeGameBoard() {
    setState(() {
      gameBoard = GameBoard(level: level);
      selectedCell = null;
      remainingMoves = 20 + (level - 1) * 2;
    });
  }

  void _handleTap(int row, int col) {
    setState(() {
      if (selectedCell == null) {
        selectedCell = CellPosition(row, col);
      } else {
        final int dRow = row - selectedCell!.row;
        final int dCol = col - selectedCell!.col;
        if ((dRow.abs() == 1 && dCol == 0) || (dRow == 0 && dCol.abs() == 1)) {
          _move(selectedCell!.row, selectedCell!.col, dRow, dCol);
        }
        selectedCell = null;
      }
    });
  }

  void _move(int row, int col, int dRow, int dCol) {
    setState(() {
      if (remainingMoves <= 0) return;
      final newBoard = gameBoard.move(row, col, dRow, dCol);
      if (newBoard != null) {
        gameBoard = newBoard;
        remainingMoves--;
        if (gameBoard.score > highScore) {
          highScore = gameBoard.score;
          _saveHighScore();
        }
        _checkWinLose();
      }
    });
  }

  void _slide(int row, int col, int dRow, int dCol) {
    setState(() {
      if (remainingMoves <= 0) return;
      final newBoard = gameBoard.slide(row, col, dRow, dCol);
      if (newBoard != null) {
        gameBoard = newBoard;
        remainingMoves--;
        if (gameBoard.score > highScore) {
          highScore = gameBoard.score;
          _saveHighScore();
        }
        _checkWinLose();
      }
    });
  }

  void _checkWinLose() {
    if (gameBoard.isBoardClear()) {
      setState(() {
        level++;
      });
      _showEndDialog(
        'Level Complete!',
        'You cleared the board! Proceeding to level $level.',
        false,
      );
      return;
    }
    if (remainingMoves <= 0) {
      _showEndDialog(
        'Out of Moves',
        'No more moves left. Try again!',
        false,
      );
      return;
    }
    if (!gameBoard.hasMoves()) {
      _showEndDialog(
        AppLocalizations.of(context).gameOver,
        AppLocalizations.of(context).gameOverMessage(gameBoard.score),
        true,
      );
    }
  }

  void _showEndDialog(String title, String message, bool showLeaderboardOption) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLeaderboardDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).globalLeaderboard),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: LeaderboardService.getTopScores(10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context).noScoresYet),
                  );
                }
                final scores = snapshot.data!;
                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (_, index) {
                    final item = scores[index];
                    return ListTile(
                      leading: Text('#${index + 1}'),
                      title: Text(item['name']),
                      trailing: Text(item['score'].toString()),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        );
      },
    );
  }

  void _showTileEffectInfo(Tile tile) {
    String effect = '';
    switch (tile.type) {
      case TileType.locked:
        effect = 'Locked: Cannot be moved or entered.';
        break;
      case TileType.obstacle:
        effect = 'Obstacle: Blocks movement.';
        break;
      case TileType.multiplier:
        effect = 'Multiplier: Bonus points!';
        break;
      case TileType.poison:
        effect = 'Poison: Subtracts points!';
        break;
      case TileType.freeze:
        effect = 'Freeze: Tile is frozen!';
        break;
      case TileType.normal:
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(effect),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSpecialTilesInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Special Tiles'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.grey),
                title: const Text('Locked'),
                subtitle: const Text('Cannot be moved or entered.'),
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.black87),
                title: const Text('Obstacle'),
                subtitle: const Text('Blocks movement.'),
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.green),
                title: const Text('Multiplier'),
                subtitle: const Text('Gives bonus points when activated.'),
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Poison'),
                subtitle: const Text('Subtracts points when activated.'),
              ),
              ListTile(
                leading: const Icon(Icons.ac_unit, color: Colors.blue),
                title: const Text('Freeze'),
                subtitle: const Text('Freezes the tile when activated.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelInfo() {
    return Column(
      children: [
        Text('Level: $level', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Moves left: $remainingMoves', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gameBoard.cols,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ gameBoard.cols;
          final col = index % gameBoard.cols;
          Offset? dragStart;
          final tile = gameBoard.grid[row][col];
          return GestureDetector(
            onTap: () {
              _handleTap(row, col);
              if (tile.type != TileType.normal) {
                _showTileEffectInfo(tile);
              }
            },
            onPanStart: (details) {
              dragStart = details.localPosition;
            },
            onPanUpdate: (details) {
              // no-op
            },
            onPanEnd: (details) {
              if (dragStart == null) return;
              final velocity = details.velocity.pixelsPerSecond;
              int dRow = 0;
              int dCol = 0;
              if (velocity.distanceSquared > 1000) {
                if (velocity.dx.abs() > velocity.dy.abs()) {
                  dCol = velocity.dx > 0 ? 1 : -1;
                } else {
                  dRow = velocity.dy > 0 ? 1 : -1;
                }
              } else {
                return;
              }
              _slide(row, col, dRow, dCol);
            },
            child: GridCellWidget(
              tile: tile,
              isSelected: selectedCell?.row == row && selectedCell?.col == col,
            ),
          );
        },
        itemCount: gameBoard.rows * gameBoard.cols,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: _showLeaderboardDialog,
            tooltip: AppLocalizations.of(context).showLeaderboard,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showSpecialTilesInfo,
            tooltip: 'Special Tiles Info',
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLevelInfo(),
          const SizedBox(height: 20),
          Text(
            '${AppLocalizations.of(context).score} ${gameBoard.score} ${AppLocalizations.of(context).highScore} $highScore',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Center(child: _buildGrid()),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _initializeGameBoard,
            child: Text('Restart'),
          ),
        ],
      ),
    );
  }
}
