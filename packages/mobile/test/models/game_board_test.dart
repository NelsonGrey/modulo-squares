import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/shared/models/game_board.dart';

void main() {
  group('GameBoard', () {
    test('initializes with correct size and non-null values', () {
      final board = GameBoard(level: 1);
      expect(board.grid.length, 2);
      expect(board.grid[0].length, 2);
      // All cells should be Tile instances
      expect(board.grid.expand((row) => row).length, 4);
      // Board generation should include at least one playable numbered tile
      expect(
        board.grid
            .expand((row) => row)
            .where((cell) => cell.value != null)
            .isNotEmpty,
        true,
      );
    });

    test('move returns null for out-of-bounds', () {
      final board = GameBoard(level: 1);
      expect(board.move(-1, 0, 1, 0), null);
      expect(board.move(0, -1, 0, 1), null);
      expect(board.move(2, 0, 1, 0), null);
      expect(board.move(0, 2, 0, 1), null);
    });

    test('reset clears score and reinitializes grid', () {
      var board = GameBoard(level: 1);
      board = board.copyWith(score: 5);
      board = board.reset();
      expect(board.score, 0);
      expect(board.grid.length, 2);
      expect(board.grid[0].length, 2);
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
      expect(
        obstacleResult,
        null,
      ); // Should not be able to move through obstacle
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
      expect(
        result?.grid[0][0].value,
        null,
      ); // Original position should be empty
      expect(result?.score, board.score + 1); // Should get 1 point for moving
    });

    test(
      'mercySpawnHelperTile adds helper tile when only one tile remains',
      () {
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
        final spawnedTiles =
            result!.grid
                .expand((row) => row)
                .where((tile) => tile.value == 5)
                .toList();
        expect(spawnedTiles.length, 2);
      },
    );

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
      expect(board.isInBounds(1, 1), true);
      expect(board.isInBounds(-1, 0), false);
      expect(board.isInBounds(0, -1), false);
      expect(board.isInBounds(2, 0), false);
      expect(board.isInBounds(0, 2), false);
    });

    test('level affects board size and keeps max value stable', () {
      final board1 = GameBoard(level: 1);
      expect(board1.rows, 2);
      expect(board1.cols, 2);
      expect(board1.maxValue, 9);

      final board2 = GameBoard(level: 2);
      expect(board2.rows, 3);
      expect(board2.cols, 3);
      expect(board2.maxValue, 9);

      final board3 = GameBoard(level: 3);
      expect(board3.rows, 4);
      expect(board3.cols, 4);
      expect(board3.maxValue, 9);

      final board10 = GameBoard(level: 10);
      expect(board10.rows, 6);
      expect(board10.cols, 6);
      expect(board10.maxValue, 9);
    });

    test('level is clamped to minimum only', () {
      final boardLow = GameBoard(level: 0);
      expect(boardLow.level, 1); // Should clamp to minimum of 1

      final boardHigh = GameBoard(level: 15);
      expect(boardHigh.level, 15); // Higher levels are supported
    });

    test('daily challenge board is deterministic for the same seed', () {
      final boardA = GameBoard.dailyChallenge(seed: 20260307);
      final boardB = GameBoard.dailyChallenge(seed: 20260307);

      expect(boardA.grid, boardB.grid);
      expect(boardA.level, boardB.level);
      expect(boardA.rows, 4);
      expect(boardA.cols, 4);
    });

    test('daily challenge board changes for different seeds', () {
      final boardA = GameBoard.dailyChallenge(seed: 20260307);
      final boardB = GameBoard.dailyChallenge(seed: 20260308);

      expect(boardA.grid == boardB.grid, false);
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
      expect(
        result?.score,
        board.score + 3,
      ); // Base +1 plus bonus target reward
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
      expect(
        result?.grid[0][0].value,
        null,
      ); // Source also becomes empty on perfect division
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
      expect(result?.grid[0][1].value, 7 % 3); // Deterministic modulo result
      expect(result?.grid[0][0].value, null); // Source clears after collision
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
      expect(
        result?.grid[0][3].value,
        null,
      ); // Perfect division: target becomes empty
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
          [
            Tile(value: 2),
            Tile(),
            Tile(type: TileType.obstacle),
            Tile(),
            Tile(),
          ],
        ],
      );

      final result = board.slide(0, 0, 0, 1); // Slide right
      expect(result, isNotNull);
      expect(
        result?.grid[0][1].value,
        2,
      ); // Should stop before obstacle at position 1
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
      final tilesWith5 =
          result!.grid
              .expand((row) => row)
              .where((tile) => tile.value == 5)
              .toList();
      expect(tilesWith5.length, 2);
    });

    test(
      'mercySpawnHelperTile spawns in any empty cell if no adjacent available',
      () {
        var board = GameBoard.fromGrid(
          rows: 3,
          cols: 3,
          maxValue: 10,
          grid: [
            [
              Tile(type: TileType.obstacle),
              Tile(type: TileType.obstacle),
              Tile(type: TileType.obstacle),
            ],
            [
              Tile(type: TileType.obstacle),
              Tile(value: 3),
              Tile(type: TileType.obstacle),
            ],
            [
              Tile(type: TileType.obstacle),
              Tile(type: TileType.obstacle),
              Tile(type: TileType.obstacle),
            ],
          ],
        );

        final result = board.mercySpawnHelperTile();
        expect(result, null); // No empty normal cells available
      },
    );

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

      expect(
        board.hasMoves(),
        true,
      ); // Can slide 2 through empty spaces to collide with 4
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

      expect(
        board.hasMoves(),
        false,
      ); // 5 > 3 so can't collide, obstacles block movement
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

    test('GameBoard grows grid size with level and caps at 6x6', () {
      final board = GameBoard(level: 25);
      expect(board.rows, 6);
      expect(board.cols, 6);
      expect(board.grid.length, 6);
      expect(board.grid[0].length, 6);
    });

    test('move preserves target tile type after collision', () {
      var board = GameBoard.fromGrid(
        rows: 2,
        cols: 2,
        maxValue: 10,
        grid: [
          [Tile(value: 2), Tile(type: TileType.bonus, value: 5)],
          [Tile(), Tile()],
        ],
      );

      final result = board.move(0, 0, 0, 1);
      expect(result, isNotNull);
      expect(result?.grid[0][1].type, TileType.bonus);
    });
  });
}
