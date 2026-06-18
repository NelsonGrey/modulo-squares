# Modulo Squares - Database Schema & Data Models

## Overview

Modulo Squares uses Cloud Firestore for all persistent data storage. This document provides a comprehensive guide to the database schema, relationships, and access patterns.

## Database Structure

### Root Collections

#### 1. modulo_leaderboard

**Purpose**: Store global high scores and game completion records.

**Access Level**: Public read, authenticated write only.

**Schema**:

```typescript
{
  // Document ID: auto-generated
  userId: string;              // User ID from Firebase Auth
  userEmail: string;           // User email (or 'anonymous')
  score: number;               // Final score for the level
  level: number;               // Level completed (1+)
  timestamp: Timestamp;        // Server-side timestamp (auto)
}
```

**Indexes**:
- `score DESC` - For leaderboard sorting
- `level DESC` - Group by difficulty
- `timestamp DESC` - Time-based ranking
- `userId + timestamp` - User's personal history

**Example Document**:

```json
{
  "userId": "user123",
  "userEmail": "player@example.com",
  "score": 4250,
  "level": 7,
  "timestamp": "2025-02-16T10:30:00Z"
}
```

**Write Operations**:
- Create: Always allowed for authenticated users
- Update: Not allowed (immutable record)
- Delete: Not allowed (immutable record)

**Query Examples**:
```javascript
// Global leaderboard (top 100)
db.collection('modulo_leaderboard')
  .orderBy('score', 'desc')
  .limit(100)

// User's scores
db.collection('modulo_leaderboard')
  .where('userId', '==', 'user123')
  .orderBy('timestamp', 'desc')

// Level-based leaderboard
db.collection('modulo_leaderboard')
  .where('level', '==', 5)
  .orderBy('score', 'desc')
  .limit(50)
```

---

#### 2. purchases

**Purpose**: Store user in-app purchase history and transaction records.

**Access Level**: Each user can only read/write their own data.

**Schema**:

```typescript
// Document ID: userId
{
  userId: string;              // User ID (doc ID, matches Auth)
  items: Array<{
    productId: string;         // SKU identifier
    type: string;              // 'subscription' | 'one-time'
    purchaseToken: string;     // Transaction ID (provider)
    price: number;             // Purchase amount (cents)
    currency: string;          // ISO 4217 currency code
    purchasedAt: Timestamp;    // Purchase timestamp
    isConsumable: boolean;      // True if consumable item
    isAcknowledged: boolean;   // Receipt acknowledged
  }>;
  totalSpent: number;          // Cumulative spending (cents)
  lastPurchaseAt: Timestamp;   // Most recent purchase
  paymentProvider: string;     // 'google_play' | 'app_store' | 'stripe'
}
```

**Example Document**:

```json
{
  "userId": "user123",
  "items": [
    {
      "productId": "remove_ads",
      "type": "one-time",
      "purchaseToken": "abc123def456",
      "price": 299,
      "currency": "USD",
      "purchasedAt": "2025-02-10T15:20:00Z",
      "isConsumable": false,
      "isAcknowledged": true
    },
    {
      "productId": "premium_monthly",
      "type": "subscription",
      "purchaseToken": "xyz789",
      "price": 699,
      "currency": "USD",
      "purchasedAt": "2025-02-01T10:00:00Z",
      "isConsumable": false,
      "isAcknowledged": true
    }
  ],
  "totalSpent": 998,
  "lastPurchaseAt": "2025-02-10T15:20:00Z",
  "paymentProvider": "google_play"
}
```

**Query Examples**:
```javascript
// Get user's purchases
db.collection('purchases').doc(userId).get()

// Check if user has 'remove_ads'
const purchase = await db.collection('purchases').doc(userId).get();
const hasRemoveAds = purchase.data()?.items?.some(
  item => item.productId === 'remove_ads'
);
```

---

#### 3. user_profiles

**Purpose**: Store user profile information and preferences.

**Access Level**: Each user can only read/write their own profile.

**Schema**:

```typescript
// Document ID: userId
{
  userId: string;                    // User ID (doc ID)
  displayName: string;               // Account display name
  avatar: string;                    // Avatar URL or emoji
  bio: string;                       // User bio/description
  language: string;                  // Language preference
  soundEnabled: boolean;             // Audio preferences
  analyticsOptIn: boolean;           // Data collection consent
  privacyLevel: 'public' | 'friends' | 'private';  // Profile visibility
  createdAt: Timestamp;              // Account creation date
  lastLoginAt: Timestamp;            // Last login date
  totalLogins: number;               // Login count
}
```

**Example Document**:

```json
{
  "userId": "user123",
  "displayName": "PuzzleChamp",
  "avatar": "🎮",
  "bio": "Modulo math enthusiast",
  "language": "en",
  "soundEnabled": true,
  "analyticsOptIn": true,
  "privacyLevel": "public",
  "createdAt": "2024-12-01T08:15:00Z",
  "lastLoginAt": "2025-02-16T14:30:00Z",
  "totalLogins": 127
}
```

---

#### 4. game_stats

**Purpose**: Store aggregated user game statistics.

**Access Level**: Each user can only read/write their own stats.

**Schema**:

```typescript
// Document ID: userId
{
  userId: string;                      // User ID (doc ID)
  
  // Level Progress
  currentLevel: number;                // Highest level reached
  levelsCompleted: number;             // Total levels beat
  
  // Scoring
  totalScore: number;                  // Sum of all level scores
  bestScore: number;                   // Highest single level score
  averageScore: number;                // Average score per level
  
  // Gameplay
  totalGamesPlayed: number;            // Total game sessions
  gamesWon: number;                    // Completed levels
  gamesLost: number;                   // Failed attempts
  winRate: number;                     // Win percentage (0-100)
  
  // Performance
  averageMovesPerGame: number;         // Avg moves used
  bestMoveRecord: number;              // Fewest moves in a level
  
  // Engagement
  streakDays: number;                  // Current play streak
  longestStreak: number;               // Longest streak achieved
  lastPlayedAt: Timestamp;             // Last game timestamp
  
  // Achievements
  achievements: Array<{
    id: string;                        // Achievement ID
    unlockedAt: Timestamp;             // When unlocked
  }>;
}
```

**Example Document**:

```json
{
  "userId": "user123",
  "currentLevel": 15,
  "levelsCompleted": 14,
  "totalScore": 52840,
  "bestScore": 5200,
  "averageScore": 3774,
  "totalGamesPlayed": 145,
  "gamesWon": 54,
  "gamesLost": 91,
  "winRate": 37.2,
  "averageMovesPerGame": 18,
  "bestMoveRecord": 8,
  "streakDays": 12,
  "longestStreak": 23,
  "lastPlayedAt": "2025-02-16T14:30:00Z",
  "achievements": [
    {
      "id": "first_win",
      "unlockedAt": "2025-01-15T10:20:00Z"
    },
    {
      "id": "master_of_level_10",
      "unlockedAt": "2025-02-05T16:45:00Z"
    }
  ]
}
```

---

## Data Models (Code Level)

### GameBoard (Core Game State)

```dart
// lib/shared/models/game_board.dart
class GameBoard {
  final List<List<int?>> grid;      // 4x4 grid state
  final int rows = 4;
  final int cols = 4;
  final int level;                  // Difficulty level
  final int score;                  // Current score
  final int remainingMoves;         // Moves left
  final bool isFrozen;              // Frozen status
  
  // Core operations
  GameBoard moveCell(int fromRow, int fromCol, int toRow, int toCol);
  GameBoard slide(int fromRow, int fromCol, int dRow, int dCol);
  GameBoard mercySpawnHelperTile({required int scorePenalty});
  
  // State queries
  bool isBoardClear();
  bool hasMoves();
  int nonEmptyTileCount();
  
  // Factory for initialization
  factory GameBoard.initial({required int level});
  GameBoard populateRandomly({
    required int numbersToPlace,
    required int maxCellValue,
    int? level
  });
}
```

### GameState (Session State)

```dart
// lib/features/game/models/game_state.dart
class GameState {
  final GameBoard gameBoard;
  final int level;
  final int highScore;
  final int remainingMoves;
  final CellPosition? selectedCell;
  final bool isGameOver;
  final bool isLevelComplete;
  
  GameState copyWith({
    GameBoard? gameBoard,
    int? level,
    int? highScore,
    int? remainingMoves,
    CellPosition? selectedCell,
    bool? isGameOver,
    bool? isLevelComplete,
  });
}
```

### CellPosition (Grid Coordinates)

```dart
// lib/shared/models/cell_position.dart
class CellPosition {
  final int row;
  final int col;
  
  const CellPosition(this.row, this.col);
}
```

---

## Firestore Security Rules

### Complete Rules Configuration

```plaintext
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Leaderboard collection - read access for all, write for authenticated users
    match /modulo_leaderboard/{document} {
      allow read: if true;
      allow create: if request.auth != null &&
        request.resource.data.keys().hasAll(['userId', 'score', 'level', 'timestamp']) &&
        request.resource.data.userId == request.auth.uid &&
        request.resource.data.score is number &&
        request.resource.data.level is number &&
        request.resource.data.score >= 0 &&
        request.resource.data.level >= 1;
      allow update, delete: if false;  // Immutable records
    }

    // Purchases collection - user isolation
    match /purchases/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }

    // User profiles - user isolation
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }

    // Game statistics - user isolation
    match /game_stats/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

---

## Data Access Patterns

### Common Query Patterns

1. **Get Global Leaderboard**
   ```javascript
   const topScores = await db.collection('modulo_leaderboard')
     .orderBy('score', 'desc')
     .limit(100)
     .get();
   ```

2. **Get User's Scores**
   ```javascript
   const userScores = await db.collection('modulo_leaderboard')
     .where('userId', '==', currentUserId)
     .orderBy('timestamp', 'desc')
     .get();
   ```

3. **Get User Stats**
   ```javascript
   const stats = await db.collection('game_stats')
     .doc(currentUserId)
     .get();
   ```

4. **Check if User Has Purchase**
   ```javascript
   const purchases = await db.collection('purchases')
     .doc(currentUserId)
     .get();
   ```

---

## Data Consistency & Integrity

### Constraints

| Collection | Field | Constraint |
|-----------|--------|-----------|
| modulo_leaderboard | score | >= 0, number |
| modulo_leaderboard | level | >= 1, number |
| modulo_leaderboard | userId | matches Auth UID |
| purchases | totalSpent | >= 0 |
| game_stats | winRate | 0-100 |
| game_stats | levelsCompleted | >= 0 |

### Atomic Operations

- Leaderboard writes are atomic (single document)
- User profile updates are atomic
- Score submission includes validation in Cloud Function

### Transaction Requirements

When updating stats after level completion:
```javascript
// Atomic transaction
const batch = db.batch();
batch.set(statsRef, { /* updated stats */ });
batch.create(leaderboardRef, { /* score record */ });
await batch.commit();
```

---

## Performance Optimization

### Indexing Strategy

**Single Field Indexes** (auto-created):
- `modulo_leaderboard.score` (DESC)
- `modulo_leaderboard.level`
- `modulo_leaderboard.timestamp` (DESC)

**Composite Indexes** (if high-volume queries):
```javascript
// For leaderboard filtering by level
// modulo_leaderboard: (level, score DESC)

// For user history
// modulo_leaderboard: (userId, timestamp DESC)
```

### Query Optimization Tips

1. **Use collection groups** for cross-user queries
2. **Paginate** results: use limit + startAfter
3. **Cache frequently accessed data** (e.g., top 100)
4. **Filter before sorting** to reduce document reads

### Storage Optimization

- Document max size: 1 MB (use arrays for related data)
- Denormalize scores into stats document for quick access
- Archive old leaderboard entries periodically

---

## Backup & Recovery

### Automated Backups

- Firestore automatic backups (7-day retention)
- Export per GCP schedule
- Multi-region redundancy

### Manual Export

```bash
# Export specific collection
gcloud firestore export gs://backup-bucket/modulo-squares/leaderboard \
  --collection-ids=modulo_leaderboard
```

### Recovery Procedures

1. Identify issue timestamp
2. Request point-in-time restore
3. Verify restored data
4. Switch application to restored database

---

## Future Schema Expansions

### Planned Collections (v2.0+)

1. **achievements** - Game achievement definitions
2. **daily_challenges** - Time-limited challenge events
3. **user_notifications** - Push notification preferences
4. **feedback** - User feedback and reviews
5. **analytics_events** - Custom event tracking (optional)

### Migration Strategy

- Use database versioning flag
- Gradual rollout of schema changes
- Backward compatibility for reads
- Use Firestore migrations guide

---

## Related Documentation

- [System Architecture](SYSTEM_ARCHITECTURE.md)
- [API Documentation](API_DOCUMENTATION.md)
- [Security Guidelines](SECURITY.md)
- [Performance & Scalability](PERFORMANCE_SCALABILITY.md)
