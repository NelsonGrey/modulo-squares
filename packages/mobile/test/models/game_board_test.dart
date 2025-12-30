import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/shared/models/game_board.dart';

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
        grid: [
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
        grid: [
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
        grid: [
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
        grid: [
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
        grid: [
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
        grid: [
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
        grid: [
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
        grid: [
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

    test('level affects board size and max value', () {
      final board1 = GameBoard(level: 1);
      expect(board1.rows, 4);
      expect(board1.cols, 4);
      expect(board1.maxValue, 10);

      final board2 = GameBoard(level: 2);
      expect(board2.rows, 5);
      expect(board2.cols, 5);
      expect(board2.maxValue, 15);

      final board10 = GameBoard(level: 10);
      expect(board10.rows, 13);
      expect(board10.cols, 13);
      expect(board10.maxValue, 55);
    });

    test('level is clamped between 1 and 10', () {
      final boardLow = GameBoard(level: 0);
      expect(boardLow.level, 1); // Should clamp to minimum of 1

      final boardHigh = GameBoard(level: 15);
      expect(boardHigh.level, 10); // Should clamp to maximum of 10
    });

    test('move handles bonus tile collision correctly', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(type: TileType.bonus, value: 4)],
          [Tile(), Tile()],
        ],
      );

      final result = board.move(0, 0, 0, 1);
      expect(result, isNotNull);
      expect(result?.score, board.score + 1); // Base +1
    });

    test('move handles modulo zero result (perfect division)', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(value: 4)],
          [Tile(), Tile()],
        ],
      );

      final result = board.move(0, 0, 0, 1);
      expect(result, isNotNull);
      expect(result?.grid[0][1].value, null); // Target becomes empty
      expect(result?.grid[0][0].value, null); // Source also becomes empty on perfect division
      expect(result?.score, board.score + 1);
    });

    test('move handles non-zero modulo result', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 3), Tile(value: 7)],
          [Tile(), Tile()],
        ],
      );

      final result = board.move(0, 0, 0, 1);
      expect(result, isNotNull);
      expect(result?.grid[0][1].value, (7 + 3) * (7 % 3)); // (10) * 1 = 10
      expect(result?.grid[0][0].value, isNotNull); // Source respawns
      expect(result?.score, board.score + 1);
    });

    test('move prevents invalid moves (source > target)', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 5), Tile(value: 3)],
          [Tile(), Tile()],
        ],
      );

      final result = board.move(0, 0, 0, 1);
      expect(result, null); // Should not allow move
    });

    test('slide moves through multiple empty spaces', () {
      var board = GameBoard.fromGrid(
        rows: 1,
        cols: 5,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(), Tile(), Tile(), Tile()],
        ],
      );

      final result = board.slide(0, 0, 0, 1); // Slide right
      expect(result, isNotNull);
      expect(result?.grid[0][4].value, 2); // Should move to last position
      expect(result?.grid[0][0].value, null); // Original position empty
      expect(result?.score, board.score + 1);
    });

    test('slide stops at boundary when sliding through empties', () {
      var board = GameBoard.fromGrid(
        rows: 1,
        cols: 4,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(), Tile(), Tile()],
        ],
      );

      final result = board.slide(0, 0, 0, 1); // Slide right to boundary
      expect(result, isNotNull);
      expect(result?.grid[0][3].value, 2); // Should move to last position
      expect(result?.grid[0][0].value, null);
      expect(result?.score, board.score + 1);
    });

    test('slide handles collision after moving through empties', () {
      var board = GameBoard.fromGrid(
        rows: 1,
        cols: 5,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(), Tile(), Tile(value: 6), Tile()],
        ],
      );

      final result = board.slide(0, 0, 0, 1); // Slide right
      expect(result, isNotNull);
      expect(result?.grid[0][3].value, null); // Perfect division: target becomes empty
      expect(result?.grid[0][0].value, null); // Source also becomes empty
      expect(result?.score, board.score + 1);
    });

    test('slide cannot move obstacles', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(type: TileType.obstacle), Tile()],
          [Tile(), Tile()],
        ],
      );

      final result = board.slide(0, 0, 0, 1);
      expect(result, null);
    });

    test('slide stops at obstacles', () {
      var board = GameBoard.fromGrid(
        rows: 1,
        cols: 5,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(), Tile(type: TileType.obstacle), Tile(), Tile()],
        ],
      );

      final result = board.slide(0, 0, 0, 1); // Slide right
      expect(result, isNotNull);
      expect(result?.grid[0][1].value, 2); // Should stop before obstacle at position 1
      expect(result?.grid[0][0].value, null);
      expect(result?.score, board.score + 1);
    });

    test('mercySpawnHelperTile spawns adjacent to single tile', () {
      var board = GameBoard.fromGrid(
        rows: 3,
        cols: 3,
        maxValue: 10,
        grid: [
          [Tile(), Tile(), Tile()],
          [Tile(), Tile(value: 5), Tile()],
          [Tile(), Tile(), Tile()],
        ],
      );

      final result = board.mercySpawnHelperTile();
      expect(result, isNotNull);
      expect(result?.score, board.score - 5); // Penalty applied

      // Should have two tiles with value 5 now
      final tilesWith5 = result!.grid.expand((row) => row).where((tile) => tile.value == 5).toList();
      expect(tilesWith5.length, 2);
    });

    test('mercySpawnHelperTile spawns in any empty cell if no adjacent available', () {
      var board = GameBoard.fromGrid(
        rows: 3,
        cols: 3,
        maxValue: 10,
        grid: [
          [Tile(type: TileType.obstacle), Tile(type: TileType.obstacle), Tile(type: TileType.obstacle)],
          [Tile(type: TileType.obstacle), Tile(value: 3), Tile(type: TileType.obstacle)],
          [Tile(type: TileType.obstacle), Tile(type: TileType.obstacle), Tile(type: TileType.obstacle)],
        ],
      );

      final result = board.mercySpawnHelperTile();
      expect(result, null); // No empty normal cells available
    });

    test('hasMoves detects moves through empty spaces', () {
      var board = GameBoard.fromGrid(
        rows: 3,
        cols: 3,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(), Tile()],
          [Tile(), Tile(), Tile()],
          [Tile(), Tile(), Tile(value: 4)],
        ],
      );

      expect(board.hasMoves(), true); // Can slide 2 through empty spaces to collide with 4
    });

    test('hasMoves returns false when no valid moves exist', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 5), Tile(type: TileType.obstacle)],
          [Tile(type: TileType.obstacle), Tile(value: 3)],
        ],
      );

      expect(board.hasMoves(), false); // 5 > 3 so can't collide, obstacles block movement
    });

    test('hasMoves considers bonus tiles as valid collision targets', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(type: TileType.bonus, value: 6)],
          [Tile(), Tile()],
        ],
      );

      expect(board.hasMoves(), true); // Can collide with bonus tile
    });

    test('Tile equality and hashCode work correctly', () {
      const tile1 = Tile(value: 5);
      const tile2 = Tile(value: 5);
      const tile3 = Tile(value: 3);
      const tile4 = Tile(type: TileType.obstacle);

      expect(tile1 == tile2, true);
      expect(tile1 == tile3, false);
      expect(tile1 == tile4, false);
      expect(tile1.hashCode == tile2.hashCode, true);
    });

    test('Tile copyWith creates correct copies', () {
      const original = Tile(value: 5, type: TileType.normal);
      final copy1 = original.copyWith(value: 10);
      final copy2 = original.copyWith(type: TileType.bonus);

      expect(copy1.value, 10);
      expect(copy1.type, TileType.normal);
      expect(copy2.value, 5);
      expect(copy2.type, TileType.bonus);
    });

    test('GameBoard handles large grids correctly', () {
      final board = GameBoard(level: 10); // 13x13 grid
      expect(board.rows, 13);
      expect(board.cols, 13);
      expect(board.grid.length, 13);
      expect(board.grid[0].length, 13);
    });

    test('move preserves tile types during respawn', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(value: 4)],
          [Tile(), Tile()],
        ],
      );

      final result = board.move(0, 0, 0, 1);
      expect(result, isNotNull);
      expect(result?.grid[0][0].type, TileType.normal); // Respawned tile should be normal type
    });
  });
}
