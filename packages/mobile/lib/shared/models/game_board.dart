import 'dart:math';

enum TileType { normal, obstacle, bonus }

/// Represents a tile on the game board with different types and values.
class Tile {
  /// The type of this tile (normal, obstacle, or bonus).
  final TileType type;

  /// The numerical value of this tile (null for obstacles).
  final int? value;

  const Tile({this.type = TileType.normal, this.value});

  /// Creates a copy of this tile with optional property overrides.
  Tile copyWith({TileType? type, int? value}) {
    return Tile(type: type ?? this.type, value: value ?? this.value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tile &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value;

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

  /// Current chain length of clear collisions (remainder == 0).
  final int comboStreak;

  // Static random instance for better performance
  static final Random _random = Random();

  GameBoard._({
    required this.rows,
    required this.cols,
    required this.maxValue,
    required this.grid,
    this.score = 0,
    this.level = 1,
    this.comboStreak = 0,
  });

  // For tests and custom setups: create a board from an explicit grid/state.
  factory GameBoard.fromGrid({
    required int rows,
    required int cols,
    required int maxValue,
    required List<List<Tile>> grid,
    int score = 0,
    int level = 1,
    int comboStreak = 0,
  }) {
    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid,
      score: score,
      level: level,
      comboStreak: comboStreak,
    );
  }

  factory GameBoard({
    required int level,
    int? emptyChanceOverride,
    int? obstacleChanceOverride,
    int? bonusChanceOverride,
    int solveDepth = 10,
  }) {
    final int clampedLevel = level < 1 ? 1 : level;
    final int size = (clampedLevel + 1).clamp(2, 6);
    final int rows = size;
    final int cols = size;
    const int maxValue = 9;

    // Standard mode boards are intended to start filled.
    final int emptyChance = (emptyChanceOverride ?? 0).clamp(0, 25);
    final int obstacleChance = (obstacleChanceOverride ??
            min(12, max(0, clampedLevel - 3)))
        .clamp(0, 25);
    final int bonusChance =
        (bonusChanceOverride ?? min(10, 1 + (clampedLevel ~/ 3))).clamp(0, 20);
    final int effectiveSolveDepth = size <= 4 ? solveDepth : 0;

    List<List<Tile>> grid = _generateProceduralGrid(
      rng: _random,
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      emptyChance: emptyChance,
      obstacleChance: obstacleChance,
      bonusChance: bonusChance,
      solveDepth: effectiveSolveDepth,
    );

    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid,
      score: 0,
      level: clampedLevel,
      comboStreak: 0,
    );
  }

  factory GameBoard.dailyChallenge({
    required int seed,
    int difficulty = 6,
    int? emptyChanceOverride,
    int? obstacleChanceOverride,
    int? bonusChanceOverride,
    int solveDepth = 12,
  }) {
    const int rows = 4;
    const int cols = 4;
    const int maxValue = 9;

    final rng = Random(seed);
    final int clampedDifficulty = difficulty.clamp(1, 20);
    final int emptyChance =
        (emptyChanceOverride ?? max(10, 22 - clampedDifficulty)).clamp(6, 55);
    final int obstacleChance = (obstacleChanceOverride ??
            (5 + (clampedDifficulty >= 10 ? 1 : 0)))
        .clamp(0, 25);
    final int bonusChance = (bonusChanceOverride ?? 3).clamp(0, 20);

    final grid = _generateProceduralGrid(
      rng: rng,
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      emptyChance: emptyChance,
      obstacleChance: obstacleChance,
      bonusChance: bonusChance,
      solveDepth: solveDepth,
    );

    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid,
      score: 0,
      level: clampedDifficulty,
      comboStreak: 0,
    );
  }

  static List<List<Tile>> _generateProceduralGrid({
    required Random rng,
    required int rows,
    required int cols,
    required int maxValue,
    required int emptyChance,
    required int obstacleChance,
    required int bonusChance,
    int solveDepth = 10,
  }) {
    for (int attempt = 0; attempt < 25; attempt++) {
      List<List<Tile>> grid = List.generate(
        rows,
        (_) => List.generate(cols, (_) {
          final int roll = rng.nextInt(100);
          if (roll < emptyChance) return const Tile();
          if (roll < emptyChance + obstacleChance) {
            return const Tile(type: TileType.obstacle);
          }
          if (roll < emptyChance + obstacleChance + bonusChance) {
            return Tile(type: TileType.bonus, value: rng.nextInt(maxValue) + 1);
          }
          return Tile(type: TileType.normal, value: rng.nextInt(maxValue) + 1);
        }),
      );

      if (!_hasPotentialMove(grid, rows, cols)) {
        grid = _seedGuaranteedMove(grid, rows, cols, maxValue, rng);
      }

      final candidate = GameBoard._(
        rows: rows,
        cols: cols,
        maxValue: maxValue,
        grid: grid,
      );

      if (solveDepth <= 0 ||
          candidate._isLikelySolvable(maxDepth: solveDepth)) {
        return grid;
      }
    }

    // Fallback: return a board that at least has a guaranteed first move.
    final fallback = _seedGuaranteedMove(
      List.generate(
        rows,
        (_) =>
            List.generate(cols, (_) => Tile(value: rng.nextInt(maxValue) + 1)),
      ),
      rows,
      cols,
      maxValue,
      rng,
    );
    return fallback;
  }

  GameBoard copyWith({
    List<List<Tile>>? grid,
    int? score,
    int? level,
    int? comboStreak,
  }) {
    return GameBoard._(
      rows: rows,
      cols: cols,
      maxValue: maxValue,
      grid: grid ?? this.grid,
      score: score ?? this.score,
      level: level ?? this.level,
      comboStreak: comboStreak ?? this.comboStreak,
    );
  }

  bool isInBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  static bool _hasPotentialMove(List<List<Tile>> grid, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final current = grid[i][j];
        if (current.value == null || current.type == TileType.obstacle) {
          continue;
        }

        for (final dir in const [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ]) {
          final ni = i + dir[0];
          final nj = j + dir[1];
          if (ni < 0 || ni >= rows || nj < 0 || nj >= cols) continue;

          final neighbor = grid[ni][nj];
          if (neighbor.type == TileType.obstacle) continue;
          if (neighbor.value == null) return true;
          if (current.value! <= neighbor.value!) return true;
        }
      }
    }

    return false;
  }

  static List<List<Tile>> _seedGuaranteedMove(
    List<List<Tile>> input,
    int rows,
    int cols,
    int maxValue,
    Random rng,
  ) {
    final seeded = input.map((row) => List<Tile>.from(row)).toList();

    if (rows < 1 || cols < 2) return seeded;

    final int row = rng.nextInt(rows);
    final int col = rng.nextInt(cols - 1);
    final int source = (rng.nextInt(maxValue) + 1).clamp(1, maxValue);
    final int factor = rng.nextInt(2) + 2;
    final int target = (source * factor).clamp(1, maxValue);

    seeded[row][col] = Tile(type: TileType.normal, value: source);
    seeded[row][col + 1] = Tile(type: TileType.normal, value: target);

    return seeded;
  }

  GameBoard _applyDeterministicCollision({
    required int sourceRow,
    required int sourceCol,
    required int targetRow,
    required int targetCol,
    required Tile sourceTile,
    required Tile targetTile,
  }) {
    final newGrid = List.generate(rows, (i) => List<Tile>.from(grid[i]));
    final int sourceVal = sourceTile.value!;
    final int targetVal = targetTile.value!;
    final int remainder = targetVal % sourceVal;

    int nextCombo = remainder == 0 ? comboStreak + 1 : 0;
    int comboBonus =
        remainder == 0 ? (nextCombo > 1 ? (nextCombo - 1).clamp(0, 3) : 0) : 0;

    int nextScore = score + 1 + comboBonus;
    if (targetTile.type == TileType.bonus) {
      nextScore += 2;
    }

    if (remainder == 0) {
      newGrid[targetRow][targetCol] = Tile(type: targetTile.type, value: null);
    } else {
      newGrid[targetRow][targetCol] = Tile(
        type: targetTile.type,
        value: remainder,
      );
    }

    newGrid[sourceRow][sourceCol] = const Tile();
    return copyWith(grid: newGrid, score: nextScore, comboStreak: nextCombo);
  }

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

    // Deterministic move rules:
    // - If target is empty, move source into target.
    // - If source <= target, replace target with (target % source); if result is 0 the target clears.
    // - Source always clears after a collision.
    // - Otherwise the move is invalid.
    if (fromTile.value != null) {
      if (toTile.value == null) {
        final newGrid = List.generate(rows, (i) => List<Tile>.from(grid[i]));
        newGrid[newRow][newCol] = fromTile.copyWith();
        newGrid[row][col] = const Tile();
        return copyWith(grid: newGrid, score: score + 1, comboStreak: 0);
      }

      if (fromTile.value! <= toTile.value!) {
        return _applyDeterministicCollision(
          sourceRow: row,
          sourceCol: col,
          targetRow: newRow,
          targetCol: newCol,
          sourceTile: fromTile,
          targetTile: toTile,
        );
      }
    }
    return null;
  }

  GameBoard? slide(int row, int col, int dRow, int dCol) {
    if (!isInBounds(row, col)) return null;
    if (dRow == 0 && dCol == 0) return null;

    Tile fromTile = grid[row][col];
    if (fromTile.value == null || fromTile.type == TileType.obstacle) {
      return null;
    }

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
        return _applyDeterministicCollision(
          sourceRow: row,
          sourceCol: col,
          targetRow: nextRow,
          targetCol: nextCol,
          sourceTile: fromTile,
          targetTile: toTile,
        );
      }
      return null;
    }

    // We moved through empties to (curRow,curCol). Check next cell:
    if (!isInBounds(nextRow, nextCol)) {
      final newGrid = List.generate(rows, (i) => List<Tile>.from(grid[i]));
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1, comboStreak: 0);
    }

    Tile toTile = grid[nextRow][nextCol];
    // If next is blocked (locked/obstacle/frozen), settle at cur
    if (toTile.type == TileType.obstacle) {
      final newGrid = List.generate(rows, (i) => List<Tile>.from(grid[i]));
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1, comboStreak: 0);
    }

    // Handle empty next cell
    if (toTile.value == null) {
      final newGrid = List.generate(rows, (i) => List<Tile>.from(grid[i]));
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1, comboStreak: 0);
    }

    if (fromTile.value! <= toTile.value!) {
      return _applyDeterministicCollision(
        sourceRow: row,
        sourceCol: col,
        targetRow: nextRow,
        targetCol: nextCol,
        sourceTile: fromTile,
        targetTile: toTile,
      );
    }

    return null;
  }

  bool isBoardClear() =>
      grid.every((row) => row.every((cell) => cell.value == null));

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
    if (sr == null || sc == null || v == null) {
      return null; // zero tiles or invalid
    }

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
        if (current.value == null || current.type == TileType.obstacle) {
          continue;
        }

        for (var dir in [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ]) {
          int ni = i + dir[0];
          int nj = j + dir[1];

          if (!isInBounds(ni, nj)) continue;
          Tile neighbor = grid[ni][nj];
          // Empty normal cell adjacent
          if (neighbor.value == null && neighbor.type == TileType.normal) {
            return true;
          }
          // Colliding into a tile
          if (neighbor.value != null &&
              current.value! <= neighbor.value! &&
              neighbor.type != TileType.obstacle) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isLikelySolvable({required int maxDepth}) {
    if (isBoardClear()) return true;
    if (maxDepth <= 0) return false;

    final seen = <String>{};
    return _searchLikelySolve(this, maxDepth, seen);
  }

  static bool _searchLikelySolve(GameBoard board, int depth, Set<String> seen) {
    if (board.isBoardClear()) return true;
    if (depth == 0) return false;

    final key = board._stateKey();
    if (!seen.add('$depth|$key')) return false;

    for (int i = 0; i < board.rows; i++) {
      for (int j = 0; j < board.cols; j++) {
        final tile = board.grid[i][j];
        if (tile.value == null || tile.type == TileType.obstacle) {
          continue;
        }
        for (final dir in const [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ]) {
          final next = board.move(i, j, dir[0], dir[1]);
          if (next != null && _searchLikelySolve(next, depth - 1, seen)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  String _stateKey() {
    final buffer = StringBuffer();
    for (final row in grid) {
      for (final tile in row) {
        buffer
          ..write(tile.type.index)
          ..write(':')
          ..write(tile.value ?? '_')
          ..write('|');
      }
    }
    return buffer.toString();
  }

  GameBoard reset() {
    return GameBoard(level: level);
  }
}
