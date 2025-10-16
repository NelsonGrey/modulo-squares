import 'package:flutter/material.dart';
import 'package:modulo/shared/models/game_board.dart';
import 'package:modulo/shared/models/cell_position.dart';
import 'package:modulo/shared/widgets/grid_cell_widget.dart';

class GameGrid extends StatelessWidget {
  final GameBoard gameBoard;
  final CellPosition? selectedCell;
  final void Function(int row, int col) onTap;
  final void Function(int row, int col, int dRow, int dCol) onSlide;
  final void Function(Tile tile) onTileEffectInfo;

  const GameGrid({
    super.key,
    required this.gameBoard,
    required this.selectedCell,
    required this.onTap,
    required this.onSlide,
    required this.onTileEffectInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Game board with ${gameBoard.rows} rows and ${gameBoard.cols} columns',
      hint: 'Tap cells to select them, then tap adjacent cells to move tiles',
      child: GestureDetector(
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond;
          if (velocity.distanceSquared > 1000) {
            final direction = _getSwipeDirection(velocity);
            if (direction != null && selectedCell != null) {
              onSlide(selectedCell!.row, selectedCell!.col, direction.$1, direction.$2);
            }
          }
        },
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gameBoard.cols,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: gameBoard.rows * gameBoard.cols,
          itemBuilder: (context, index) {
            final row = index ~/ gameBoard.cols;
            final col = index % gameBoard.cols;
            final tile = gameBoard.grid[row][col];
            final isSelected = selectedCell != null && selectedCell!.row == row && selectedCell!.col == col;

            return Semantics(
              label: _getTileAccessibilityLabel(tile, row, col),
              hint: _getTileAccessibilityHint(tile, isSelected),
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () => onTap(row, col),
                onLongPress: tile.type != TileType.normal ? () => onTileEffectInfo(tile) : null,
                child: GridCellWidget(
                  tile: tile,
                  isSelected: isSelected,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  (int, int)? _getSwipeDirection(Offset velocity) {
    if (velocity.dx.abs() > velocity.dy.abs()) {
      // Horizontal swipe
      return velocity.dx > 0 ? (0, 1) : (0, -1); // Right : Left
    } else {
      // Vertical swipe
      return velocity.dy > 0 ? (1, 0) : (-1, 0); // Down : Up
    }
  }

  String _getTileAccessibilityLabel(Tile tile, int row, int col) {
    final position = 'Row ${row + 1}, Column ${col + 1}';
    switch (tile.type) {
      case TileType.normal:
        return tile.value != null ? '$position: Number ${tile.value}' : '$position: Empty';
      case TileType.obstacle:
        return '$position: Obstacle tile';
      case TileType.bonus:
        return '$position: Bonus tile';
    }
  }

  String _getTileAccessibilityHint(Tile tile, bool isSelected) {
    if (isSelected) {
      return 'Selected. Swipe or tap adjacent cell to move.';
    }

    switch (tile.type) {
      case TileType.normal:
        return tile.value != null ? 'Tap to select this number tile' : 'Empty cell';
      case TileType.obstacle:
        return 'Obstacle tile blocks movement. Long press for more info.';
      case TileType.bonus:
        return 'Bonus tile gives extra points. Long press for more info.';
    }
  }
}
