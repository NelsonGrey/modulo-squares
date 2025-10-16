import 'dart:math';

enum TileType { normal, obstacle, bonus }

/// Represents a tile on the game board with different types and values.
class Tile {
  /// The type of this tile (normal, obstacle, or bonus).
  final TileType type;

  /// The numerical value of this tile (null for obstacles).
  final int? value;

  const Tile({
    this.type = TileType.normal,
    this.value,
  });

  /// Creates a copy of this tile with optional property overrides.
  Tile copyWith({TileType? type, int? value}) {
    return Tile(
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Tile && runtimeType == other.runtimeType && type == other.type && value == other.value;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;

  @override
  String toString() => 'Tile(type: $type, value: $value)';
}

/// Represents the game board state for Modulo Squares.
/// The game involves moving numbered tiles on a grid using modulo arithmetic.
class GameBoard {
  /// Number of rows in the grid.
  final int rows;

  /// Number of columns in the grid.
  final int cols;

  /// Maximum value a tile can have.
  final int maxValue;

  /// 2D grid of tiles representing the current board state.
  final List<List<Tile>> grid;

  /// Current game score.
  final int score;

  /// Current game level.
  final int level;

  // Static random instance for better performance
  static final Random _random = Random();

  GameBoard._({
    required this.rows,
    required this.cols,
    required this.maxValue,
    required this.grid,
    this.score = 0,
    this.level = 1,
  });

  // For tests and custom setups: create a board from an explicit grid/state.
  factory GameBoard.fromGrid({
    required int rows,
    required int cols,
    required int maxValue,
    required List<List<Tile>> grid,
    int score = 0,
    int level = 1,
  }) {
    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid,
      score: score,
      level: level,
    );
  }

  factory GameBoard({
    required int level,
  }) {
    // Levels range from 1..10. Grid size starts at 4x4 and increases by 1 each level.
    final int clampedLevel = level < 1 ? 1 : (level > 10 ? 10 : level);
    final int size = 4 + (clampedLevel - 1); // L1:4, L2:5, ..., L10:13
    final rows = size;
    final cols = size;
    final maxValue = 10 + (clampedLevel - 1) * 5;
    List<List<Tile>> grid = List.generate(
        rows,
        (_) => List.generate(cols, (_) {
              // Randomly assign special tiles for challenge
              int roll = _random.nextInt(100);
              if (roll < 5) return Tile(type: TileType.obstacle); // 5% obstacle
              if (roll < 8) return Tile(type: TileType.bonus, value: _random.nextInt(maxValue) + 1); // 3% bonus
              return Tile(type: TileType.normal, value: _random.nextInt(maxValue) + 1);
            }));
    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid,
      score: 0,
      level: level,
    );
  }

  GameBoard copyWith({
    List<List<Tile>>? grid,
    int? score,
    int? level,
  }) {
    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid ?? this.grid,
      score: score ?? this.score,
      level: level ?? this.level,
    );
  }

  bool isInBounds(int row, int col) => row >= 0 && row < rows && col >= 0 && col < cols;

  GameBoard? move(int row, int col, int dRow, int dCol) {
    if (!isInBounds(row, col)) return null;
    int newRow = row + dRow;
    int newCol = col + dCol;
    if (!isInBounds(newRow, newCol)) return null;

    Tile fromTile = grid[row][col];
    Tile toTile = grid[newRow][newCol];

    // Can't move obstacle tiles; can't enter obstacles
    if (fromTile.type == TileType.obstacle) return null;
    if (toTile.type == TileType.obstacle) return null;

    // Move rules:
    // - If target is empty, move the source value into the target.
    // - If source <= target, replace target with (target % source). If result == 0 the cell becomes empty.
    // - Otherwise the move is invalid.
    if (fromTile.value != null) {
      if (toTile.value == null) {
        final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
        newGrid[newRow][newCol] = fromTile.copyWith();
        newGrid[row][col] = const Tile();
        return copyWith(grid: newGrid, score: score + 1);
      }

      if (fromTile.value! <= toTile.value!) {
        final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
        final int sourceVal = fromTile.value!;
        final int targetVal = toTile.value!;
        final int remainder = targetVal % sourceVal;
        // Base score +1; bonus tile grants +5 extra on collision
        int newScore = score + 1 + (toTile.type == TileType.bonus ? 5 : 0);
        TileType newType = toTile.type;

        if (remainder == 0) {
          // Modulo achieved: both tiles become empty
          newGrid[newRow][newCol] = Tile(type: newType, value: null);
          newGrid[row][col] = const Tile();
        } else {
          // Not zero: source respawns; target becomes (target+source)*remainder
          final int newValue = (targetVal + sourceVal) * remainder;
          newGrid[newRow][newCol] = Tile(type: newType, value: newValue);
          newGrid[row][col] = Tile(type: TileType.normal, value: _random.nextInt(maxValue) + 1);
        }
        return copyWith(grid: newGrid, score: newScore);
      }
    }
    return null;
  }

  GameBoard? slide(int row, int col, int dRow, int dCol) {
    if (!isInBounds(row, col)) return null;
    if (dRow == 0 && dCol == 0) return null;

    Tile fromTile = grid[row][col];
    if (fromTile.value == null || fromTile.type == TileType.obstacle) return null;

    int curRow = row;
    int curCol = col;
    int nextRow = curRow + dRow;
    int nextCol = curCol + dCol;

    // Move through empty spaces until we either reach boundary or encounter a tile
    while (isInBounds(nextRow, nextCol)) {
      Tile nextTile = grid[nextRow][nextCol];
      if (nextTile.value == null && nextTile.type == TileType.normal) {
        curRow = nextRow;
        curCol = nextCol;
        nextRow = curRow + dRow;
        nextCol = curCol + dCol;
      } else {
        break;
      }
    }

    // If we couldn't move at all (no empty space and adjacent tile exists), handle single-step collision
    if (curRow == row && curCol == col) {
      if (!isInBounds(nextRow, nextCol)) return null;
      Tile toTile = grid[nextRow][nextCol];
      if (toTile.value == null || toTile.type == TileType.obstacle) return null;
      if (fromTile.value! <= toTile.value!) {
        final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
        final int sourceVal = fromTile.value!;
        final int targetVal = toTile.value!;
        final int remainder = targetVal % sourceVal;
        int newScore = score + 1 + (toTile.type == TileType.bonus ? 5 : 0);
        TileType newType = toTile.type;

        if (remainder == 0) {
          newGrid[nextRow][nextCol] = Tile(type: newType, value: null);
          newGrid[row][col] = const Tile();
        } else {
          final int newValue = (targetVal + sourceVal) * remainder;
          newGrid[nextRow][nextCol] = Tile(type: newType, value: newValue);
          newGrid[row][col] = Tile(type: TileType.normal, value: _random.nextInt(maxValue) + 1);
        }
        return copyWith(grid: newGrid, score: newScore);
      }
      return null;
    }

    // We moved through empties to (curRow,curCol). Check next cell:
    if (!isInBounds(nextRow, nextCol)) {
      final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1);
    }

    Tile toTile = grid[nextRow][nextCol];
    // If next is blocked (locked/obstacle/frozen), settle at cur
    if (toTile.type == TileType.obstacle) {
      final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1);
    }

    // Handle empty next cell
    if (toTile.value == null) {
      final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1);
    }

    if (fromTile.value! <= toTile.value!) {
      final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
      final int sourceVal = fromTile.value!;
      final int targetVal = toTile.value!;
      final int remainder = targetVal % sourceVal;
      int newScore = score + 1 + (toTile.type == TileType.bonus ? 5 : 0);
      TileType newType = toTile.type;
      if (remainder == 0) {
        newGrid[nextRow][nextCol] = Tile(type: newType, value: null);
        newGrid[row][col] = const Tile();
      } else {
        final int newValue = (targetVal + sourceVal) * remainder;
        newGrid[nextRow][nextCol] = Tile(type: newType, value: newValue);
        newGrid[row][col] = Tile(type: TileType.normal, value: _random.nextInt(maxValue) + 1);
      }
      return copyWith(grid: newGrid, score: newScore);
    }

    return null;
  }

  bool isBoardClear() => grid.every((row) => row.every((cell) => cell.value == null));

  // Count tiles that currently have a value.
  int nonEmptyTileCount() {
    int count = 0;
    for (final r in grid) {
      for (final t in r) {
        if (t.value != null) count++;
      }
    }
    return count;
  }

  // If exactly one tile remains, spawn a helper tile with the same value into an empty cell.
  // Returns a new board with score penalty applied, or null if not applicable.
  GameBoard? mercySpawnHelperTile({int scorePenalty = 5}) {
    // Find the single remaining tile.
    int? sr;
    int? sc;
    int? v;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final t = grid[i][j];
        if (t.value != null) {
          if (sr != null) {
            // More than one tile found; not applicable
            return null;
          }
          sr = i;
          sc = j;
          v = t.value;
        }
      }
    }
    if (sr == null || sc == null || v == null) return null; // zero tiles or invalid

    // Try adjacent empty normal cell first (up, down, left, right)
    final dirs = const [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    int tr = -1;
    int tc = -1;
    for (final d in dirs) {
      final r = sr + d[0];
      final c = sc + d[1];
      if (isInBounds(r, c)) {
        final t = grid[r][c];
        if (t.value == null && t.type == TileType.normal) {
          tr = r;
          tc = c;
          break;
        }
      }
    }
    // If no adjacent, pick any empty normal cell.
    if (tr == -1) {
      outer:
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          final t = grid[i][j];
          if (t.value == null && t.type == TileType.normal) {
            tr = i;
            tc = j;
            break outer;
          }
        }
      }
    }
    if (tr == -1 || tc == -1) return null; // No place to spawn

    final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
    final int vv = v;
    newGrid[tr][tc] = Tile(type: TileType.normal, value: vv);
    return copyWith(grid: newGrid, score: score - scorePenalty);
  }

  bool hasMoves() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        Tile current = grid[i][j];
        if (current.value == null || current.type == TileType.obstacle) continue;

        for (var dir in [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ]) {
          int ni = i + dir[0];
          int nj = j + dir[1];

          if (!isInBounds(ni, nj)) continue;
          Tile neighbor = grid[ni][nj];
          // Empty normal cell adjacent
          if (neighbor.value == null && neighbor.type == TileType.normal) return true;
          // Colliding into a tile
          if (neighbor.value != null && current.value! <= neighbor.value! && neighbor.type != TileType.obstacle) {
            return true;
          }
        }
      }
    }
    return false;
  }

  GameBoard reset() {
    return GameBoard(level: level);
  }
}
