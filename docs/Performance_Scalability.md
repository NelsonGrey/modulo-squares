# Modulo Squares - Performance & Scalability Guide

> **Planning/reference material (reviewed 2026-07-20):** Examples below include legacy APIs and proposed controls. Validate current behavior against [System Architecture](System_Architecture.md) and the private Functions repo before implementation.

## Overview

This document covers performance optimization strategies, scalability considerations, and monitoring for Modulo Squares across all platforms.

---

## Performance Goals

### Key Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| App startup time | < 3 seconds | TBD | 📊 Track |
| Level load time | < 500ms | TBD | 📊 Track |
| Frame rate | 60 FPS | TBD | 📊 Monitor |
| Memory usage | < 150MB | TBD | 📊 Monitor |
| Battery drain | < 2% per hour | TBD | 📊 Track |
| API response time | < 500ms | TBD | 📊 Monitor |
| Database query time | < 100ms | TBD | 📊 Track |

---

## Frontend Performance Optimization

### Flutter Mobile App

#### Code Splitting & Lazy Loading

```dart
// lib/main.dart - Lazy load expensive features
void main() async {
  // Initialize core services only
  await Firebase.initializeApp();
  
  // Lazy initialize expensive services
  runApp(const ModuloApp());
}

// In GameScreen
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadResources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GameScreenContent();
        }
        return LoadingScreen();
      },
    );
  }

  Future<void> _loadResources() async {
    // Load game assets in parallel
    await Future.wait([
      getIt<AssetService>().preloadGameAssets(),
      getIt<AdService>().loadInterstitial(),
    ]);
  }
}
```

#### Widget Optimization

```dart
// Use const constructors
const GameCell(
  value: 5,
  onTap: handleTap,
)

// Use Selector for specific rebuilds
Selector<GameProvider, GameBoard>(
  selector: (_, provider) => provider.gameBoard,
  builder: (_, gameBoard, __) => GameGrid(board: gameBoard),
)

// Avoid rebuilding entire screen on state change
Consumer<GameProvider>(
  builder: (context, gameProvider, child) {
    return Column(
      children: [
        child!, // Static widgets don't rebuild
        GameGrid(board: gameProvider.gameBoard),
      ],
    );
  },
  child: const Header(), // Only built once
)
```

#### Asset Optimization

```dart
// lib/core/services/asset_service.dart
class AssetService {
  static const _instance = AssetService._();

  factory AssetService() => _instance;

  AssetService._();

  final Map<String, ImageProvider> _imageCache = {};

  Future<void> preloadAssets() async {
    // Preload critical assets
    final assets = [
      'assets/images/tiles.png',
      'assets/images/board.png',
      'assets/sounds/move.mp3',
    ];

    await Future.wait(
      assets.map((asset) => _precacheImage(asset)),
    );
  }

  Future<void> _precacheImage(String assetPath) async {
    final image = AssetImage(assetPath);
    await image.resolve(ImageConfiguration.empty);
    _imageCache[assetPath] = image;
  }

  ImageProvider getImage(String assetPath) =>
    _imageCache[assetPath] ?? AssetImage(assetPath);
}
```

#### Memory Management

```dart
// Dispose resources properly
class GameScreenState extends State<GameScreen> {
  late GameProvider _gameProvider;

  @override
  void initState() {
    super.initState();
    _gameProvider = context.read<GameProvider>();
  }

  @override
  void dispose() {
    // Clean up resources
    _gameProvider.dispose();
    super.dispose();
  }
}

// Limit cached data
class CacheService {
  static const _cacheSize = 50; // Maximum cached items

  final Map<String, dynamic> _cache = {};

  void set(String key, dynamic value) {
    if (_cache.length >= _cacheSize) {
      _cache.remove(_cache.keys.first); // LRU eviction
    }
    _cache[key] = value;
  }
}
```

### React Web App

#### Code Splitting

```typescript
// src/routes.tsx
import { lazy, Suspense } from 'react';

const HomePage = lazy(() => import('./pages/Home'));
const GamePage = lazy(() => import('./pages/Game'));
const LeaderboardPage = lazy(() => import('./pages/Leaderboard'));

export function Routes() {
  return (
    <Suspense fallback={<Loading />}>
      <Route path="/" element={<HomePage />} />
      <Route path="/game" element={<GamePage />} />
      <Route path="/leaderboard" element={<LeaderboardPage />} />
    </Suspense>
  );
}
```

#### Bundle Optimization (Vite)

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules')) {
            if (id.includes('react') || id.includes('react-dom')) {
              return 'react-vendor';
            }
            if (id.includes('firebase')) {
              return 'firebase-vendor';
            }
            return 'vendor';
          }
          if (id.includes('features/game')) {
            return 'game-logic';
          }
        },
      },
    },
    minify: 'terser',
    sourcemap: false,
  },
});
```

#### Performance Monitoring (Web Vitals)

```typescript
// src/utils/performance.ts
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

export function initPerformanceMonitoring() {
  getCLS(console.log); // Cumulative Layout Shift
  getFID(console.log); // First Input Delay
  getFCP(console.log); // First Contentful Paint
  getLCP(console.log); // Largest Contentful Paint
  getTTFB(console.log); // Time to First Byte
}
```

---

## Backend Performance Optimization

### Cloud Functions

#### Optimization Strategies

```javascript
// packages/functions/index.js

// ✅ Good: Efficient function
exports.submitScore = functions.https.onCall(
  async (data, context) => {
    // 1. Quick validation
    if (typeof data.score !== 'number') {
      throw new Error('Invalid score');
    }

    // 2. Prepare write operation
    const writeOperation = {
      userId: context.auth.uid,
      score: data.score,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // 3. Single atomic write
    const docRef = await admin.firestore()
      .collection('modulo_leaderboard')
      .add(writeOperation);

    // 4. Return result
    return { success: true, scoreId: docRef.id };
  }
);

// ❌ Bad: Inefficient function with N+1 queries
exports.submitScoreBad = functions.https.onCall(
  async (data, context) => {
    // Multiple reads
    const user = await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    const stats = await admin.firestore()
      .collection('stats')
      .doc(context.auth.uid)
      .get();

    const leaderboard = await admin.firestore()
      .collection('leaderboard')
      .get(); // Expensive!

    // Process...
    // Multiple writes
    await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .update({ /* ... */ });

    await admin.firestore()
      .collection('stats')
      .doc(context.auth.uid)
      .update({ /* ... */ });

    await admin.firestore()
      .collection('leaderboard')
      .add({ /* ... */ });
  }
);
```

#### Connection Pooling

```javascript
// Reuse admin instance
const admin = require('firebase-admin');
admin.initializeApp(); // Singleton, reused across functions

// Database connections are pooled automatically
const db = admin.firestore();

// All functions share the same connection pool
```

#### Caching Strategy

```javascript
// In-memory cache for frequently accessed data
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 300 }); // 5 min TTL

exports.getTopScores = functions.https.onCall(
  async (data, context) => {
    const cacheKey = 'top_scores_100';

    // Check cache first
    let topScores = cache.get(cacheKey);
    if (topScores) {
      return { scores: topScores, fromCache: true };
    }

    // Fetch from Firestore
    const snapshot = await admin.firestore()
      .collection('modulo_leaderboard')
      .orderBy('score', 'desc')
      .limit(100)
      .get();

    topScores = snapshot.docs.map(doc => doc.data());

    // Store in cache
    cache.set(cacheKey, topScores);

    return { scores: topScores, fromCache: false };
  }
);
```

### Firestore Optimization

#### Query Optimization

```dart
// ✅ Efficient queries

// 1. Filter before sorting
db.collection('modulo_leaderboard')
  .where('level', isEqualTo: 5)
  .orderBy('score', descending: true)
  .limit(10)

// 2. Use pagination
Query query = db.collection('modulo_leaderboard')
  .orderBy('score', descending: true)
  .limit(10);

DocumentSnapshot lastDoc = snapshot.docs.last;
query.startAfterDocument(lastDoc)
  .limit(10)
  .get()

// 3. Use collection groups for cross-user data
db.collectionGroup('scores')
  .whereEqualTo('userId', uid)
  .get()

// ❌ Inefficient queries

// 1. Loading all documents
db.collection('modulo_leaderboard').get() // O(n)

// 2. Client-side filtering
db.collection('modulo_leaderboard')
  .get()
  .then(snap => snap.docs
    .where(doc => doc.score > 1000)
    .toList())

// 3. Not using indexes
db.collection('complex').where('a', '==', 1)
  .where('b', '==', 2)
  .where('c', '<', 3)
  .orderBy('d') // Missing composite index!
```

#### Index Management

```javascript
// Recommended indexes for modulo_leaderboard
{
  "collectionGroups": [
    {
      "collectionId": "modulo_leaderboard",
      "indexes": [
        {
          "fields": [
            { "fieldPath": "score", "order": "DESCENDING" },
            { "fieldPath": "__name__", "order": "DESCENDING" }
          ]
        },
        {
          "fields": [
            { "fieldPath": "userId" },
            { "fieldPath": "score", "order": "DESCENDING" }
          ]
        },
        {
          "fields": [
            { "fieldPath": "level" },
            { "fieldPath": "score", "order": "DESCENDING" }
          ]
        }
      ]
    }
  ]
}
```

#### Batch Operations

```dart
// ✅ Good: Batch write for multiple updates
WriteBatch batch = FirebaseFirestore.instance.batch();

// Add score
batch.set(
  FirebaseFirestore.instance
    .collection('modulo_leaderboard')
    .doc(),
  scoreData,
);

// Update stats
batch.update(
  FirebaseFirestore.instance
    .collection('game_stats')
    .doc(userId),
  statsUpdate,
);

await batch.commit();

// ❌ Bad: Multiple individual writes
await FirebaseFirestore.instance
  .collection('modulo_leaderboard')
  .add(scoreData);

await FirebaseFirestore.instance
  .collection('game_stats')
  .doc(userId)
  .update(statsUpdate);
```

### Compression & Caching

```dart
// Enable compression for Firestore (automatic on Android/iOS)
// Web: Handled by browser

// Set cache size
await FirebaseFirestore.instance.settings = Settings(
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  persistenceEnabled: true,
);

// Disable persistence to save memory
await FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: false,
);
```

---

## Monitoring & Analytics

### Performance Metrics Dashboard

```dart
// lib/core/services/performance_monitor.dart
class PerformanceMonitor {
  static const _instance = PerformanceMonitor._();

  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._();

  final FirebasePerformance _performance = 
    FirebasePerformance.instance;

  Future<void> trackLevelLoadTime() async {
    final trace = _performance.newTrace('level_load');

    await trace.start();
    try {
      // Load level assets
      await _loadLevelAssets();
    } finally {
      await trace.stop();
    }
  }

  Future<void> trackDatabaseQuery(String queryName) async {
    final trace = _performance.newTrace('firestore_query_$queryName');

    await trace.start();
    try {
      // Execute query
      await _executeQuery(queryName);
    } finally {
      await trace.stop();
    }
  }

  void trackFrameRate() {
    // Monitor frame drops in game screen
    final trace = _performance.newTrace('game_frame_rate');
    trace.incrementCounter('frame_count');
  }
}
```

### Analytics Events

```dart
// Track performance-related events
FirebaseAnalytics.instance.logEvent(
  name: 'performance_metric',
  parameters: {
    'metric_type': 'app_startup',
    'duration_ms': 2500,
    'device': 'iPhone12',
    'os_version': '15.0',
  },
);
```

### Real-time Dashboards

**Firebase Console**:
1. Navigate to Performance Monitoring
2. View:
   - App startup time
   - Screen load time
   - Network request duration
   - Custom traces

**Google Analytics**:
1. View custom events
2. Analyze user flow
3. Identify performance bottlenecks

---

## Scalability Considerations

### Database Scalability

#### Write Throughput
- **Current**: Firestore auto-scales to ~25,000 writes/sec per collection
- **Our usage**: ~10 scores/sec (100 concurrent users × 1 submit/10 sec)
- **Capacity**: Easily handles growth 100x

#### Read Throughput
- **Current**: Firestore auto-scales to unlimited reads
- **Our usage**: ~1000 reads/sec (million users checking leaderboard)
- **Capacity**: Firestore handles this natively

#### Solutions for Growth

```javascript
// 1. Partition collections by date for very high volumes
// modulo_leaderboard_2025_02 (monthly)
// modulo_leaderboard_2025_03

// 2. Use subcollections for user-specific data
/users/{userId}/scores/{scoreId}

// 3. Archive old leaderboards
const archiveOldScores = functions.pubsub
  .schedule('0 0 * * *') // Daily
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const snapshot = await admin.firestore()
      .collection('modulo_leaderboard')
      .where('timestamp', '<', thirtyDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

### API Scalability

#### Cloud Functions Auto-scaling

- Scales from 0 to 1000+ concurrent instances
- No pre-warming needed
- Cold start: ~2 seconds first invocation
- Warm start: ~50-100ms subsequent

#### Request Queuing

```javascript
// Handle rate limiting gracefully
exports.submitScore = functions.https.onCall(
  async (data, context) => {
    return new Promise((resolve, reject) => {
      // Queue if over capacity
      requestQueue.push(async () => {
        try {
          const result = await processScore(data, context);
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });
    });
  }
);
```

### Frontend Scalability

#### Progressive Web App (PWA)

```typescript
// Register service worker for offline caching
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}

// Cache assets for offline access
const cacheName = 'modulo-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/**',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(cacheName).then(cache => 
      cache.addAll(urlsToCache)
    )
  );
});
```

#### CDN Caching

```bash
# Firebase Hosting uses Google CDN automatically
# Cache static assets globally

# In firebase.json
{
  "hosting": {
    "headers": [
      {
        "source": "**/*.{js,css,png,jpg,svg,woff,woff2}",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

---

## Load Testing

### Setup

```bash
# Install load testing tools
npm install -g artillery

# Create test configuration
cat > load-test.yml << EOF
config:
  target: "https://us-central1-modulo-squares-dev.cloudfunctions.net"
  phases:
    - duration: 60
      arrivalRate: 10  # 10 requests/sec
    - duration: 600
      arrivalRate: 50  # 50 requests/sec
scenarios:
  - name: "Submit Score Load Test"
    flow:
      - post:
          url: "/submitScore"
          headers:
            Authorization: "Bearer {{ $randomNumber(1, 1000) }}"
          json:
            score: "{{ $randomNumber(1000, 5000) }}"
            level: "{{ $randomNumber(1, 20) }}"
EOF

# Run test
artillery run load-test.yml
```

### Metrics to Monitor

1. **Response Time**: p50, p95, p99 latencies
2. **Error Rate**: % of failed requests
3. **Throughput**: Requests per second sustained
4. **Resource Usage**: CPU, memory on Cloud Functions

---

## Optimization Checklist

### Frontend
- [ ] Code splitting implemented
- [ ] Assets compressed (images, audio)
- [ ] Lazy loading for heavy features
- [ ] Memory leaks identified and fixed
- [ ] Frame rate monitored (60 FPS target)
- [ ] Battery usage optimized

### Backend
- [ ] Database queries indexed
- [ ] Batch operations implemented
- [ ] Caching strategy in place
- [ ] Cloud Functions optimized
- [ ] Compression enabled
- [ ] Monitoring dashboards setup

### Deployment
- [ ] CDN caching configured
- [ ] Database auto-scaling enabled
- [ ] Monitoring alerts configured
- [ ] Performance benchmarks documented
- [ ] Load tests passing
- [ ] Rollback plan in place

---

## Related Documentation

- [System Architecture](System_Architecture.md)
- [Database Schema](Database_Schema.md)
- [CI/CD Setup](Ci_Cd_Setup.md)
- [Go-Live Runbook](GO_LIVE_RUNBOOK.md)
