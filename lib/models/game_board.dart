import 'dart:math';

enum TileType { normal, locked, obstacle, multiplier, poison, freeze }

class Tile {
  final TileType type;
  final int? value;
  final bool frozen;

  const Tile({
    this.type = TileType.normal,
    this.value,
    this.frozen = false,
  });

  Tile copyWith({TileType? type, int? value, bool? frozen}) {
    return Tile(
      type: type ?? this.type,
      value: value ?? this.value,
      frozen: frozen ?? this.frozen,
    );
  }
}

class GameBoard {
  final int rows;
  final int cols;
  final int maxValue;
  final List<List<Tile>> grid;
  final int score;
  final int level;

  GameBoard._({
    required this.rows,
    required this.cols,
    required this.maxValue,
    required this.grid,
    this.score = 0,
    this.level = 1,
  });

  factory GameBoard({
    required int level,
  }) {
    final rows = 4 + ((level - 1) ~/ 3);
    final cols = 4 + ((level - 1) ~/ 3);
    final maxValue = 10 + (level - 1) * 5;
    final random = Random();
    List<List<Tile>> grid = List.generate(
        rows,
        (_) => List.generate(cols, (_) {
              // Randomly assign special tiles for challenge
              int roll = random.nextInt(100);
              if (roll < 5) return Tile(type: TileType.locked); // 5% locked
              if (roll < 10) return Tile(type: TileType.obstacle); // 5% obstacle
              if (roll < 15) return Tile(type: TileType.multiplier, value: random.nextInt(maxValue) + 1);
              if (roll < 18) return Tile(type: TileType.poison, value: random.nextInt(maxValue) + 1);
              if (roll < 20) return Tile(type: TileType.freeze, value: random.nextInt(maxValue) + 1);
              return Tile(type: TileType.normal, value: random.nextInt(maxValue) + 1);
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

    // Can't move locked, obstacle, or frozen tiles
    if (fromTile.type == TileType.locked || fromTile.type == TileType.obstacle || fromTile.frozen) return null;
    // Can't move into locked, obstacle, or frozen tiles
    if (toTile.type == TileType.locked || toTile.type == TileType.obstacle || toTile.frozen) return null;

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
        int result = toTile.value! % fromTile.value!;
        // Special tile effects
        int newScore = score + 1;
        TileType newType = toTile.type;
        bool newFrozen = false;
        if (toTile.type == TileType.multiplier) newScore += 4;
        if (toTile.type == TileType.poison) newScore -= 3;
        if (toTile.type == TileType.freeze) newFrozen = true;
        newGrid[newRow][newCol] = Tile(type: newType, value: result != 0 ? result : null, frozen: newFrozen);
        if (result != 0) {
          final rnd = Random();
          newGrid[row][col] = Tile(type: TileType.normal, value: rnd.nextInt(maxValue) + 1);
        } else {
          newGrid[row][col] = const Tile();
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
    if (fromTile.value == null || fromTile.type == TileType.locked || fromTile.type == TileType.obstacle || fromTile.frozen) return null;

    int curRow = row;
    int curCol = col;
    int nextRow = curRow + dRow;
    int nextCol = curCol + dCol;

    // Move through empty spaces until we either reach boundary or encounter a tile
    while (isInBounds(nextRow, nextCol)) {
      Tile nextTile = grid[nextRow][nextCol];
      if (nextTile.value == null && nextTile.type == TileType.normal && !nextTile.frozen) {
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
      if (toTile.value == null || toTile.type == TileType.locked || toTile.type == TileType.obstacle || toTile.frozen) return null;
      if (fromTile.value! <= toTile.value!) {
        final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
        int result = toTile.value! % fromTile.value!;
        int newScore = score + 1;
        TileType newType = toTile.type;
        bool newFrozen = false;
        if (toTile.type == TileType.multiplier) newScore += 4;
        if (toTile.type == TileType.poison) newScore -= 3;
        if (toTile.type == TileType.freeze) newFrozen = true;
        newGrid[nextRow][nextCol] = Tile(type: newType, value: result != 0 ? result : null, frozen: newFrozen);
        if (result != 0) {
          final rnd = Random();
          newGrid[row][col] = Tile(type: TileType.normal, value: rnd.nextInt(maxValue) + 1);
        } else {
          newGrid[row][col] = const Tile();
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
    if (toTile.value == null || toTile.type == TileType.locked || toTile.type == TileType.obstacle || toTile.frozen) {
      final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
      newGrid[curRow][curCol] = fromTile.copyWith();
      newGrid[row][col] = const Tile();
      return copyWith(grid: newGrid, score: score + 1);
    }

    if (fromTile.value! <= toTile.value!) {
      final newGrid = grid.map((r) => List<Tile>.from(r)).toList();
      int result = toTile.value! % fromTile.value!;
      int newScore = score + 1;
      TileType newType = toTile.type;
      bool newFrozen = false;
      if (toTile.type == TileType.multiplier) newScore += 4;
      if (toTile.type == TileType.poison) newScore -= 3;
      if (toTile.type == TileType.freeze) newFrozen = true;
      newGrid[nextRow][nextCol] = Tile(type: newType, value: result != 0 ? result : null, frozen: newFrozen);
      if (result != 0) {
        final rnd = Random();
        newGrid[row][col] = Tile(type: TileType.normal, value: rnd.nextInt(maxValue) + 1);
      } else {
        newGrid[row][col] = const Tile();
      }
      return copyWith(grid: newGrid, score: newScore);
    }

    return null;
  }

  bool isBoardClear() => grid.every((row) => row.every((cell) => cell.value == null));

  bool hasMoves() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        Tile current = grid[i][j];
        if (current.value == null || current.type == TileType.locked || current.type == TileType.obstacle || current.frozen) continue;

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
          if (neighbor.value == null && neighbor.type == TileType.normal && !neighbor.frozen) return true;
          if (neighbor.value != null &&
              current.value! <= neighbor.value! &&
              neighbor.type != TileType.locked &&
              neighbor.type != TileType.obstacle &&
              !neighbor.frozen) {
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
