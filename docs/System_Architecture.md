# Modulo Squares - System Architecture

## Overview

Modulo Squares is a multi-platform, cloud-native puzzle game built with a modern distributed architecture. The system consists of three main tiers:

1. **Frontend Layer** - Native mobile apps (iOS/Android) and web platform
2. **Backend Layer** - Firebase services and Cloud Functions
3. **Data Layer** - Firestore database with security rules

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT LAYER                            │
├──────────────────────┬──────────────────┬──────────────────┤
│  iOS App             │  Android App     │  Web App         │
│ (Flutter)            │  (Flutter)       │ (React + Vite)   │
│                      │                  │                  │
│ - Game Engine        │ - Game Engine    │ - Marketing      │
│ - Auth Integration   │ - Auth Integration│ - Game Demo      │
│ - Ad/IAP Integration │ - Ad/IAP Integration                │
│ - Analytics          │ - Analytics      │ - Analytics      │
└───────────┬──────────┴──────────┬───────┴──────────┬────────┘
            │                     │                  │
            └─────────────────────┼──────────────────┘
                                  │
        ┌─────────────────────────▼──────────────────────────┐
        │          FIREBASE SERVICES LAYER                   │
        ├─────────────────┬──────────────┬──────────────────┤
        │ Authentication  │ Real-time    │ Cloud Functions  │
        │ (Firebase Auth) │ Database     │ (Backend API)    │
        │                 │ (Firestore)  │                  │
        │ - Anonymous     │              │ - submitScore()  │
        │ - Email/Pass    │ Collections: │ - health check   │
        │ - Custom Claims │ - leaderboard│ - WebHook Server │
        │                 │ - purchases  │ - Docker API     │
        │                 │ - user_stats │                  │
        └────────┬────────┴──────┬───────┴────────┬─────────┘
                 │               │                │
                 │        ┌──────▼────────┐      │
        ┌────────▼─────┐  │ FIRESTORE     │      │
        │  STORAGE &   │  │ SECURITY RULES│      │
        │ STATIC FILES │  └───────────────┘      │
        │              │                         │
        │ - App Icons  │                    ┌────▼──────────┐
        │ - Store Assets│                    │ DOCKER/K8s    │
        │ - Downloads  │                    │ (Optional)     │
        └──────────────┘                    └────────────────┘
```

## Detailed Component Overview

### 1. Frontend Layer

#### Mobile App (Flutter)
**Platforms**: iOS, Android, Web

**Architecture Pattern**: Feature-based clean architecture

```
packages/mobile/
├── lib/
│   ├── core/                    # Application core
│   │   ├── config/              # Firebase configuration
│   │   ├── services/            # Core services (analytics, ads, auth)
│   │   └── di/                  # Dependency injection (GetIt)
│   ├── features/                # Feature modules
│   │   ├── auth/                # Authentication feature
│   │   ├── game/                # Game feature
│   │   │   ├── providers/       # State management (Provider pattern)
│   │   │   ├── models/          # Game data models
│   │   │   ├── widgets/         # Game UI components
│   │   │   └── game_screen.dart # Main game UI
│   │   ├── leaderboard/         # Leaderboard feature
│   │   └── website/             # Website launch feature
│   ├── shared/                  # Cross-feature components
│   │   ├── models/              # Shared data models (GameBoard)
│   │   └── widgets/             # Reusable UI components
│   ├── l10n/                    # Localization strings
│   └── main.dart                # App entry point
└── test/                        # Unit and widget tests
```

**Key Services**:
- **AnalyticsService**: Firebase Analytics integration
- **AdService**: Google AdMob integration (Android/iOS)
- **PurchaseService**: In-app purchases (RevenueCat)
- **ConsentService**: GDPR/ATT consent management
- **CacheService**: Local data caching
- **AssetService**: Asset preloading
- **ErrorHandler**: Centralized error handling

**State Management**:
- Provider pattern for global state
- ChangeNotifier for reactive updates
- Immutable models with `copyWith` pattern
- Local persistence via SharedPreferences

#### Web App (React + Vite)
**Purpose**: Marketing website and game demo

```
packages/web/
├── src/
│   ├── components/              # React components
│   ├── pages/                   # Page components
│   ├── assets/                  # Images, icons, styles
│   ├── utils/                   # Helper functions
│   └── firebase/                # Firebase integration
├── public/                      # Static assets
├── vite.config.ts               # Vite build configuration
├── tailwind.config.js           # Tailwind CSS config
├── Dockerfile                   # Container image
└── nginx.conf                   # Production server config
```

**Technologies**:
- React 18+ for UI
- Vite for bundling
- Tailwind CSS for styling
- Firebase SDK for backend integration

### 2. Backend Layer

#### Firebase Services

**Firebase Authentication**
- Anonymous sign-in (default user auth)
- Email/password support (future)
- Custom claims for user roles
- Multi-platform support (iOS, Android, Web)

**Cloud Firestore**
- NoSQL document database
- Real-time synchronization
- Automatic indexing
- Offline support via local cache

**Cloud Functions**
- Node.js 20+ runtime
- REST API endpoints
- ExpressJS framework for HTTP handling
- Containerizable via Docker

**Firebase Hosting**
- Static website deployment
- Multi-site support
- CDN with global edge locations
- Automatic HTTPS

#### Cloud Functions API

```javascript
packages/functions/
├── index.js                     # Main function handlers
├── package.json                 # Dependencies
├── Dockerfile                   # Container image
└── health check endpoints
```

**Key Functions**:
- `submitScore()`: Validate and store leaderboard scores
- `health/`: Docker health check endpoint
- Express app for containerized deployment

### 3. Data Layer

#### Firestore Database Schema

**Collections**:

1. **modulo_leaderboard** - Global high scores
   - `userId: string` - User ID
   - `userEmail: string` - User email
   - `score: number` - Final score
   - `level: number` - Level achieved
   - `timestamp: timestamp` - Submission time

2. **purchases** - User in-app purchase history
   - `userId: string` (doc ID)
   - `items: array` - Purchased items
   - `timestamp: timestamp` - Purchase date

3. **user_profiles** - User profile data
   - `userId: string` (doc ID)
   - `displayName: string` - User display name
   - `totalGamesPlayed: number` - Game count
   - `createdAt: timestamp` - Account creation

4. **game_stats** - Player game statistics
   - `userId: string` (doc ID)
   - `gamesPlayed: number` - Total games
   - `gamesWon: number` - Victories
   - `totalScore: number` - Cumulative score
   - `bestScore: number` - High score

#### Firestore Security Rules

- **Public Read**: Leaderboard visible to all
- **Authenticated Write**: Only signed-in users can create records
- **User Isolation**: Users can only read/write their own data
- **Immutable Leaderboard**: Score records are final (no updates/deletes)

## Data Flow Architecture

### Game Session Flow

```
1. App Launch
   ↓
2. Firebase Init + Anonymous Auth
   ↓
3. Service Initialization (Analytics, Ads, Cache)
   ↓
4. Load Game State (high score from cache)
   ↓
5. Initialize GameBoard (Level 1)
   ↓
6. Render Game Screen
   ↓
7. Player Actions (tap tiles, move pieces)
   ↓
8. GameProvider updates GameState
   ↓
9. Widget rebuild with new state
   ↓
10. Win/Lose Check
    ├─ Win: Show ad → Load next level
    ├─ Lose: Game Over screen
    └─ Submit score to leaderboard
   ↓
11. Save high score to SharedPreferences
```

### Score Submission Flow

```
Player completes level
    ↓
Collect score, level, timestamp
    ↓
Call Cloud Function (submitScore)
    ↓
CF: Verify user authentication
    ↓
CF: Validate score data
    ↓
CF: Store in Firestore (modulo_leaderboard)
    ↓
Return confirmation to client
    ↓
Update UI (show leaderboard)
```

## Deployment Architecture

### Multi-Environment Setup

**Development (dev)**
- Firebase Project: `modulo-squares-dev`
- Database: Firestore (dev)
- Analytics: Enabled
- Ads: Disabled (test ads)
- Features: All experimental features on

**Staging (staging)**
- Firebase Project: `modulo-squares-staging`
- Database: Firestore (staging)
- Analytics: Enabled
- Ads: Enabled (test ads)
- Features: Production-like environment

**Production (prod)**
- Firebase Project: `modulo-squares-prod`
- Database: Firestore (production)
- Analytics: Full tracking
- Ads: Live ads
- Features: Stable features only

### CI/CD Pipeline

```
GitHub Push
    ↓
GitHub Actions Workflow
    ├─ Run tests
    ├─ Lint code
    ├─ Build Flutter app
    ├─ Build Functions
    │   └─ Build Docker image → Push to registry
    └─ Deploy to Firebase
        ├─ Firestore rules
        ├─ Cloud Functions
        ├─ Hosting (web)
        └─ Android Play Store (automated)
```

## Security Architecture

### Authentication & Authorization

1. **Client-side Auth**
   - Firebase Authentication SDK
   - Anonymous sign-in by default
   - Secure token handling
   - Automatic token refresh

2. **Cloud Function Auth**
   - Verify authentication context
   - Check user UID matches claims
   - Validate request signatures

3. **Firestore Security**
   - Rule-based access control
   - User ID verification in document paths
   - Collection-level permissions

### Data Security

- **Encryption in transit**: HTTPS/TLS for all connections
- **Encryption at rest**: Firebase automatic encryption
- **Sensitive data**: No passwords or payment info stored locally
- **Ad consent**: GDPR/ATT tracking transparency

## External Integrations

### Third-Party Services

1. **Google AdMob**
   - Banner ads
   - Interstitial ads (between levels)
   - Rewarded ads (gameplay rewards)
   - Ad network management

2. **In-App Purchases**
   - Remove ads purchase
   - Premium content access
   - Payment processing
   - Purchase verification

3. **Firebase Analytics**
   - Event tracking
   - User property tracking
   - Funnel analysis
   - Crash reporting (Crashlytics)

4. **Firebase Performance Monitoring**
   - App startup time
   - Screen rendering performance
   - Network request metrics
   - Custom trace measurements

## Scalability Considerations

### Firestore Scaling

- Partitioned collections for high-volume reads
- Composite indexes for complex queries
- Document size limits (1 MB)
- Batch operations for bulk writes

### Cloud Functions Scaling

- Automatic scaling (0-1000+ concurrent)
- Cold start optimization
- Request timeout: 540 seconds
- Memory allocation: 256 MB - 16 GB

### Frontend Optimization

- Code splitting via Vite
- Asset lazy loading
- Image optimization
- Compression (gzip/brotli)

## Monitoring & Observability

### Logging

- Firebase Cloud Logging
- Custom event logging via Analytics
- Error tracking via Crashlytics
- Application Performance Monitoring (APM)

### Metrics

- App crashes and stability
- User engagement metrics
- Level difficulty analysis
- Performance metrics (startup, frame rate)

### Alerting

- Crash rate thresholds
- Function error rates
- Database quota alerts
- Performance degradation alerts

## Disaster Recovery

- **Backups**: Automatic Firestore backups
- **Data export**: Weekly full database exports
- **Recovery SLA**: 4-hour RTO
- **Testing**: Monthly backup restore drills

## Technology Stack Summary

| Layer | Component | Technology |
|-------|-----------|-----------|
| Mobile Frontend | iOS/Android/Web | Flutter 3.32+ |
| Web Frontend | Marketing Site | React 18+, Vite, Tailwind |
| State Management | Local state | Provider, ChangeNotifier |
| Backend API | Cloud Functions | Node.js 20+, Express |
| Database | Firestore | NoSQL, real-time sync |
| Authentication | Firebase Auth | Anonymous, Email/Password |
| Hosting | Web hosting | Firebase Hosting |
| Analytics | Events | Firebase Analytics |
| Monetization | Ads/IAP | AdMob, RevenueCat |
| Container/Orchestration | Optional | Docker, Docker Compose |
| CI/CD | Automation | GitHub Actions |

## References

- [System Architecture Principles](DEVELOPER_GUIDE.md#architecture-principles)
- [Database Schema](DATABASE_SCHEMA.md)
- [API Documentation](API_DOCUMENTATION.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
