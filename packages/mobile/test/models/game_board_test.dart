import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/shared/models/game_board.dart';

void main() {
  group('GameBoard', () {
    test('initializes with correct size and non-null values', () {
      final board = GameBoard(level: 1);
      expect(board.grid.length, 4);
      expect(board.grid[0].length, 4);
      // All cells should be Tile, and most should have value != null
      expect(board.grid.expand((row) => row).where((cell) => cell.value != null || cell.type != TileType.normal).length, 16);
    });

    test('move returns null for out-of-bounds', () {
      final board = GameBoard(level: 1);
      expect(board.move(-1, 0, 1, 0), null);
      expect(board.move(0, -1, 0, 1), null);
      expect(board.move(4, 0, 1, 0), null);
      expect(board.move(0, 4, 0, 1), null);
    });

    test('reset clears score and reinitializes grid', () {
      var board = GameBoard(level: 1);
      board = board.copyWith(score: 5);
      board = board.reset();
      expect(board.score, 0);
      expect(board.grid.length, 4);
      expect(board.grid[0].length, 4);
    });

    test('isBoardClear returns true only if all cells are empty', () {
      var board = GameBoard(level: 1);
      board = board.copyWith(
        grid: [
          [const Tile(), const Tile()],
          [const Tile(), const Tile()],
        ],
      );
      expect(board.isBoardClear(), true);

      board = board.copyWith(
        grid: [
          [const Tile(value: 1), const Tile()],
          [const Tile(), const Tile()],
        ],
      );
      expect(board.isBoardClear(), false);
    });

    test('hasMoves returns true if a move is possible', () {
      // Positive case: an empty adjacent cell allows a move
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 4), Tile(value: 2)],
          [Tile(), Tile()],
        ],
      );
      expect(board.hasMoves(), true);

      // Negative case: obstacles block all possible moves
      board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 5), Tile(type: TileType.obstacle)],
          [Tile(type: TileType.obstacle), Tile(value: 2)],
        ],
      );
      expect(board.hasMoves(), false);
    });

    test('move handles special tiles correctly', () {
      // Test bonus tile
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 2), Tile(type: TileType.bonus)],
          [Tile(), Tile()],
        ],
      );
      final result = board.move(0, 0, 0, 1);
      expect(result?.score, greaterThan(0)); // Bonus should increase score

      // Test obstacle tile blocks movement
      board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 2), Tile(type: TileType.obstacle)],
          [Tile(), Tile()],
        ],
      );
      final obstacleResult = board.move(0, 0, 0, 1);
      expect(obstacleResult, null); // Should not be able to move through obstacle
    });

    test('slide moves tile through empty spaces', () {
      var board = GameBoard.fromGrid(
        rows: 1,
        cols: 4,
        maxValue: 10,
        grid: const [
          [Tile(value: 2), Tile(), Tile(), Tile(value: 4)],
        ],
      );

      // Slide right from position 0 - should move through empty spaces
      final result = board.slide(0, 0, 0, 1);
      expect(result, isNotNull); // Should successfully move
      expect(result?.grid[0][0].value, null); // Original position should be empty
      expect(result?.score, board.score + 1); // Should get 1 point for moving
    });

    test('mercySpawnHelperTile adds helper tile when only one tile remains', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 5), Tile()],
          [Tile(), Tile()],
        ],
      );

      final result = board.mercySpawnHelperTile();
      expect(result, isNotNull);
      expect(result?.score, board.score - 5); // Should have score penalty
      // Should have spawned another tile with value 5
      final spawnedTiles = result!.grid.expand((row) => row).where((tile) => tile.value == 5).toList();
      expect(spawnedTiles.length, 2);
    });

    test('mercySpawnHelperTile returns null when multiple tiles exist', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 5), Tile(value: 3)],
          [Tile(), Tile()],
        ],
      );

      final result = board.mercySpawnHelperTile();
      expect(result, null); // Should not spawn when multiple tiles exist
    });

    test('nonEmptyTileCount returns correct count', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: const [
          [Tile(value: 2), Tile()],
          [Tile(value: 4), Tile()],
        ],
      );

      expect(board.nonEmptyTileCount(), 2);
    });

    test('level progression works correctly', () {
      var board = GameBoard(level: 1);
      expect(board.level, 1);

      // Advance to next level
      board = board.copyWith(level: 2);
      expect(board.level, 2);
    });

    test('copyWith preserves immutability', () {
      final original = GameBoard(level: 1);
      final modified = original.copyWith(score: 10, level: 2);

      expect(original.score, 0);
      expect(original.level, 1);
      expect(modified.score, 10);
      expect(modified.level, 2);
    });

    test('isInBounds works correctly', () {
      final board = GameBoard(level: 1);

      expect(board.isInBounds(0, 0), true);
      expect(board.isInBounds(3, 3), true);
      expect(board.isInBounds(-1, 0), false);
      expect(board.isInBounds(0, -1), false);
      expect(board.isInBounds(4, 0), false);
      expect(board.isInBounds(0, 4), false);
    });
  });
}
