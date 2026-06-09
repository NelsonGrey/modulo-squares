# Modulo Squares - Game Mechanics & Rules

## Game Overview

**Modulo Squares** is a strategic puzzle game where players manipulate numbered tiles on a 4×4 grid using modulo arithmetic to clear the board and achieve level objectives.

**Objective**: Use mathematical operations to clear all tiles from the board in the minimum number of moves.

**Board Size**: 4×4 grid (16 cells total)

**Tile Values**: 0-9 (modulo 10)

---

## Core Game Rules

### Tile Types

1. **Empty Cell**: No value, can accept incoming tiles
2. **Numbered Cell**: Contains value 0-9
3. **Locked Cell** (future): Cannot be moved, obstacle
4. **Goal Cell** (future): Must match target value

### Turn Structure

Each player turn consists of:

1. **Select**: Choose a source tile
2. **Move**: Slide to an adjacent empty or occupied cell
3. **Operation Applied**: Modulo arithmetic evaluated
4. **Score Updated**: Points awarded based on result

---

## Movement Rules

### Valid Moves

Players can move tiles in four directions:
- **Up**: (row - 1, col)
- **Down**: (row + 1, col)
- **Left**: (row, col - 1)
- **Right**: (row, col + 1)

**Constraint**: Must move to an adjacent cell (Manhattan distance = 1)

### Invalid Moves

Cannot move:
- Outside grid boundaries
- Diagonally (only 4-directional movement)
- To locked cells
- When no valid moves remain

---

## Modulo Arithmetic Operations

### Basic Move Mechanic

When a numbered tile is moved to another cell:

**Formula**: `newValue = sourceValue % targetValue`

### Movement Scenarios

#### Scenario 1: Source to Empty Cell

```
Source tile: 5
Target cell: Empty

Action: Move 5 to empty cell
Result:
  - Source becomes empty
  - Target shows 5
  - Score: +5 points
```

#### Scenario 2: Source ≤ Target (Modulo Operation)

```
Source tile: 3
Target tile: 7

Action: Move 3 to target
Calculation: 7 % 3 = 1
Result:
  - Source becomes empty
  - Target becomes 1
  - Eliminated tiles: 0
  - Score: +10 points
```

#### Scenario 3: Source > Target (Zero Result)

```
Source tile: 8
Target tile: 3

Action: Move 8 to target
Calculation: 3 % 8 = 3 (modulo is smaller value)
Result:
  - Source becomes empty
  - Target shows 3
  - Score: +15 points (no elimination)
```

#### Scenario 4: Modulo Result = 0 (Clear)

```
Source tile: 4
Target tile: 8

Action: Move 4 to target
Calculation: 8 % 4 = 0
Result:
  - Source becomes empty
  - Target becomes empty (CLEARED!)
  - Score: +25 points (bonus for clearing)
```

### Special Case: Moving to Zero

```
Source tile: 7
Target tile: 0

Action: Move 7 to zero
Result:
  - Target remains 0 (0 % 7 = 0)
  - Source becomes empty
  - Score: +5 points
```

---

## Scoring System

### Base Points

| Action | Points |
|--------|--------|
| Move to empty | +5 |
| Modulo operation | +10 |
| Clear tile (result = 0) | +25 |
| Eliminate multiple tiles | +50 |

### Score Multipliers

| Condition | Multiplier | Description |
|-----------|-----------|-------------|
| Level 1-3 | 1x | Beginner multiplier |
| Level 4-6 | 1.2x | Intermediate bonus |
| Level 7-10 | 1.5x | Advanced multiplier |
| Level 11+ | 2x | Expert multiplier |

### Score Calculation Example

```
Level: 7 (multiplier: 1.5x)
Move: 8 % 4 = 0 (Clear operation)

Score = 25 points × 1.5 = 37 points
```

### High Score

- Stored as maximum single-game score
- Persisted locally via SharedPreferences
- Synced to leaderboard on submission

---

## Win Conditions

### Level Complete (Win)

**Condition**: All tiles cleared from the grid

```
Board state: 
[0, 0, 0, 0]
[0, 0, 0, 0]
[0, 0, 0, 0]
[0, 0, 0, 0]

Status: ✓ LEVEL COMPLETE
Reward: Show completion screen, ads, next level option
```

### Game Over (Lose)

**Condition 1**: No valid moves remain AND board not clear

```
Board state:
[1, 2, 3, 4]
[5, 6, 7, 8]
[9, 0, 0, 0]
[0, 0, 0, 0]

No adjacent empty cells available
No tiles can move to create new combinations
Status: ✗ GAME OVER - NO VALID MOVES
```

**Condition 2**: Out of moves

```
Starting moves: 20 + (level - 1) × 2
Current moves used: 20
Remaining: 0

Status: ✗ OUT OF MOVES
```

### Mercy Spawn

**Trigger**: Only 1 tile remains on board AND moves available

**Action**: 
1. Automatically spawn 1-2 helper tiles
2. Penalty: -5 points
3. Allow player to continue

**Purpose**: Prevent unwinnable states and extend gameplay

---

## Difficulty Progression

### Level-Based Difficulty

| Level | Starting Tiles | Max Value | Moves | Difficulty |
|-------|----------------|-----------|-------|-----------|
| 1 | 6-8 | 5 | 20 | Tutorial |
| 2-3 | 8-9 | 6 | 22-24 | Easy |
| 4-6 | 10-11 | 7 | 26-30 | Medium |
| 7-10 | 12-13 | 8 | 32-38 | Hard |
| 11+ | 14+ | 9 | 40+ | Expert |

### Algorithm: Board Generation

```dart
GameBoard populateRandomly({
  required int numbersToPlace,
  required int maxCellValue,
  int? level
}) {
  // 1. Start with empty 4×4 grid
  // 2. Randomly select `numbersToPlace` cells
  // 3. Fill with random values: 0 to maxCellValue
  // 4. Ensure at least one valid move possible
  // 5. Return populated GameBoard
  
  // Ensures solvable game states
}
```

### Difficulty Scaling

**Formula**: `nextLevelDifficulty = currentDifficulty + 0.15`

- Gradual increase prevents difficulty spikes
- Player skill progression matched to level curve
- Adjustments based on win rate analytics

---

## Game Mechanics Details

### Move Validation Algorithm

```dart
bool isValidMove(int sourceRow, int sourceCol, 
                 int targetRow, int targetCol) {
  // 1. Check bounds
  if (!isInBounds(targetRow, targetCol)) return false;
  
  // 2. Check adjacency (Manhattan distance = 1)
  if ((sourceRow - targetRow).abs() + 
      (sourceCol - targetCol).abs() != 1) return false;
  
  // 3. Check source has value
  if (grid[sourceRow][sourceCol] == null) return false;
  
  // 4. Allow move to empty or occupied cell
  return true;
}
```

### Move Execution Algorithm

```dart
GameBoard moveCell(int fromRow, int fromCol, 
                   int toRow, int toCol) {
  final sourceValue = grid[fromRow][fromCol];
  final targetValue = grid[toRow][toCol];
  
  if (targetValue == null) {
    // Move to empty cell
    grid[toRow][toCol] = sourceValue;
    grid[fromRow][fromCol] = null;
  } else {
    // Modulo operation
    final result = targetValue % sourceValue;
    grid[toRow][toCol] = result == 0 ? null : result;
    grid[fromRow][fromCol] = null;
  }
  
  updateScore();
  return this;
}
```

### Board State Queries

```dart
// Check if board is clear
bool isBoardClear() => 
  grid.every((row) => row.every((cell) => cell == null));

// Check if valid moves exist
bool hasValidMoves() {
  for (int r = 0; r < 4; r++) {
    for (int c = 0; c < 4; c++) {
      if (grid[r][c] != null) {
        // Check all 4 adjacent cells
        if (isValidMove(r, c, r-1, c)) return true;
        if (isValidMove(r, c, r+1, c)) return true;
        if (isValidMove(r, c, r, c-1)) return true;
        if (isValidMove(r, c, r, c+1)) return true;
      }
    }
  }
  return false;
}

// Count non-empty tiles
int nonEmptyTileCount() => 
  grid.expand((row) => row)
      .where((cell) => cell != null)
      .length;
```

---

## Special Mechanics (Future)

### Power-Up Tiles

#### Multiplier Tile (⚡)
- **Effect**: 4x score multiplier on next move
- **Rarity**: 1 per 20 generates
- **Visual**: Golden highlight

```
Example:
Move multiplier tile (8) to normal tile (3)
Normal calculation: 3 % 8 = 3, +10 points
With multiplier: +10 × 4 = +40 points
````

#### Poison Tile (☠️)
- **Effect**: Next tile moved loses points
- **Damage**: -3 points per tile moved
- **Duration**: 2 moves

```
Example:
Activation: Move 5 to poison tile
Result: +10 - 3 = +7 points
Next 2 moves: Each deducts 3 points
```

#### Freeze Tile (❄️)
- **Effect**: Skip next turn
- **Recovery**: Mandatory pass
- **Strategic use**: Block difficult board states

```
Example:
Move 7 to freeze tile (6)
Result: Create frozen state for 1 turn
Next turn: Must skip (can't move)
```

---

## Game State Management

### Session State Variables

```dart
class GameState {
  final GameBoard gameBoard;        // Current grid
  final int level;                  // Current level
  final int highScore;              // Best single score
  final int remainingMoves;         // Moves left
  final CellPosition? selectedCell;  // Selected tile
  final bool isGameOver;            // Game ended?
  final bool isLevelComplete;       // Level won?
}
```

### State Transitions

```
Initial State
    ↓
[Game Running]
├─ Player selects tile
├─ Player moves tile
├─ Modulo operation applied
├─ Score updated
├─ Win/Lose check
└─ Repeat
    ↓
[Win State] → Show completion UI → Load next level
    ↓
[Lose State] → Show game over UI → Retry/Menu
```

---

## Tutorial & Onboarding

### Tutorial Levels

**Level 1: Learn Movement**
- Single tile on board
- Empty spaces highlighted
- Objective: Move tile to empty cell
- Educational tooltip: Explain movement

**Level 2: Learn Modulo**
- Two tiles: 5 and 3
- Objective: Move 5 onto 3, see 3 % 5 = 3
- Educational tooltip: Explain modulo arithmetic
- Highlight result change

**Level 3: Learn Clearing**
- Two tiles: 4 and 8
- Objective: Move 4 onto 8, see 8 % 4 = 0 (clear!)
- Educational tooltip: Explain clearing mechanic
- Celebrate first clear

### Difficulty Ramp

- Levels 1-3: Tutorial with hints
- Levels 4-6: Guided with tips
- Levels 7+: Full difficulty

---

## Examples & Walkthroughs

### Example Game Session

**Setup**: Level 2

```
Board:
[2] [0] [3] [5]
[7] [0] [0] [4]
[0] [6] [0] [1]
[8] [9] [2] [0]

Moves Available: 22
Score: 0
```

**Move 1**: 2 → empty (middle top)
```
Result:
[0] [2] [3] [5]
[7] [0] [0] [4]
[0] [6] [0] [1]
[8] [9] [2] [0]

Score: +5 (move to empty)
```

**Move 2**: 3 → 2
```
Calculation: 2 % 3 = 2
Result:
[0] [2] [3] [5]
[7] [0] [0] [4]
[0] [6] [0] [1]
[8] [9] [2] [0]

Score: +5 + 10 = +15
```

**Move 3**: 4 → empty (right side)
```
Result:
[0] [2] [3] [5]
[7] [0] [0] [0]
[0] [6] [0] [1]
[8] [9] [2] [4]

Score: +15 + 5 = +20
```

**... continues until board clear or out of moves**

---

## Accessibility

### Color-Blind Friendly

- Numbers displayed on tiles (not just colors)
- High contrast color scheme
- Patterns in addition to colors

### Input Accessibility

- Support for both tap and keyboard input
- Voice control (future)
- Haptic feedback for actions

### Visual Aids

- Grid lines for clarity
- Highlight selected tiles
- Animation for moves
- Sound effects (toggleable)

---

## Balance & Testing

### Designer Metrics

- **Win Rate Target**: 60-70% at each level
- **Average Moves to Win**: 50-70% of available moves
- **Time to Complete**: 2-5 minutes per level
- **Difficulty Curve**: +15% difficulty per level

### A/B Testing

The game uses Firebase Analytics to:
1. Track level completion rates
2. Identify difficulty spikes
3. Measure average session length
4. Analyze player dropoff points

### Balancing Adjustments

Based on analytics:
- Increase level moves if win rate < 40%
- Decrease initial tiles if level takes > 6 min
- Adjust multiplier if score variance too high

---

## Related Documentation

- [System Architecture](SYSTEM_ARCHITECTURE.md)
- [Database Schema](DATABASE_SCHEMA.md)
- [Developer Guide](DEVELOPER_GUIDE.md)
- [Product Design](PRODUCT_DESIGN.md)
