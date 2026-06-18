# Modulo Squares - API Documentation

## Overview

Modulo Squares provides a Cloud Functions-based API for backend operations. The API is exposed as HTTP endpoints and can be containerized for deployment via Docker.

**Base URLs**:
- Cloud Functions: `https://us-central1-modulo-squares-{ENV}.cloudfunctions.net`
- Docker API: `http://localhost:3000` (local/containerized)
- Health Check: `/health` endpoint

**Authentication**: Firebase Auth tokens required (except health check)

**Content-Type**: `application/json`

**Framework**: Node.js 20+ with Express.js

---

## API Endpoints

### 1. Health Check Endpoint

**Purpose**: Docker and load balancer health monitoring

**Endpoint**: `GET /health`

**Authentication**: None required

**Response** (200 OK):

```json
{
  "status": "healthy",
  "timestamp": "2025-02-16T14:30:00.000Z",
  "service": "modulo-squares-api"
}
```

**Use Cases**:
- Kubernetes liveness/readiness probes
- Load balancer health checks
- CloudRun health monitoring
- Docker container health checks

**Example**:
```bash
curl http://localhost:3000/health
```

---

### 2. Submit Score Endpoint

**Purpose**: Validate and store leaderboard scores

**Endpoint**: `POST /functions/v1/submitScore`

**Authentication**: Firebase ID token (Authorization header)

**Request Headers**:
```
Authorization: Bearer {firebaseIdToken}
Content-Type: application/json
```

**Request Body**:
```json
{
  "score": 4250,
  "level": 7
}
```

**Request Parameters**:

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| score | number | Yes | >= 0, integer |
| level | number | Yes | >= 1, integer |

**Response** (200 OK):

```json
{
  "success": true,
  "message": "Score submitted successfully",
  "scoreId": "doc123abc",
  "data": {
    "userId": "user123",
    "userEmail": "player@example.com",
    "score": 4250,
    "level": 7,
    "timestamp": "2025-02-16T14:30:00Z"
  }
}
```

**Error Responses**:

**400 Bad Request** - Invalid input:
```json
{
  "code": "invalid-argument",
  "message": "Invalid score",
  "details": "score must be a non-negative number"
}
```

**401 Unauthorized** - Missing/invalid token:
```json
{
  "code": "unauthenticated",
  "message": "Request not authenticated",
  "details": "No Firebase ID token provided"
}
```

**403 Forbidden** - User verification failed:
```json
{
  "code": "permission-denied",
  "message": "User verification failed",
  "details": "Token UID does not match request context"
}
```

**500 Internal Server Error** - Database error:
```json
{
  "code": "internal",
  "message": "Failed to submit score",
  "details": "Database write error: PERMISSION_DENIED"
}
```

**Implementation Details**:

```javascript
// File: packages/functions/index.js
exports.submitScore = functions.https.onCall(async (data, context) => {
  // 1. Verify user is authenticated
  const user = FunctionsAuthHelpers.verifyAuthenticated(context);
  const { uid, email } = user;

  // 2. Validate input
  const { score, level } = data;
  if (typeof score !== 'number' || score < 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid score');
  }
  if (typeof level !== 'number' || level < 1) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid level');
  }

  try {
    // 3. Store in Firestore
    const docRef = await admin.firestore()
      .collection('modulo_leaderboard')
      .add({
        userId: uid,
        userEmail: email || 'anonymous',
        score,
        level,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      success: true,
      scoreId: docRef.id,
      data: {
        userId: uid,
        userEmail: email || 'anonymous',
        score,
        level,
      }
    };
  } catch (error) {
    console.error('Score submission error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to submit score',
      error.message
    );
  }
});
```

**Example Usage** (Flutter):

```dart
// lib/core/services/leaderboard_service.dart
Future<void> submitScore(int score, int level) async {
  try {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
      'submitScore',
      options: HttpsCallableOptions(timeout: Duration(seconds: 30)),
    );
    
    final result = await callable.call({
      'score': score,
      'level': level,
    });
    
    print('Score submitted: ${result.data}');
  } on FirebaseFunctionsException catch (error) {
    print('Error: ${error.code} - ${error.message}');
    rethrow;
  }
}
```

**Example Usage** (Web/JavaScript):

```javascript
// packages/web/src/services/api.ts
async function submitScore(score: number, level: number): Promise<any> {
  const auth = getAuth();
  const idToken = await auth.currentUser?.getIdToken();

  const response = await fetch(
    'https://us-central1-modulo-squares-dev.cloudfunctions.net/submitScore',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        score,
        level,
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }

  return response.json();
}
```

---

## API Error Handling

### Error Codes Reference

| Code | HTTP Status | Description | Cause |
|------|-------------|-----------|-------|
| invalid-argument | 400 | Invalid input parameters | Bad request data |
| unauthenticated | 401 | User not authenticated | Missing/invalid token |
| permission-denied | 403 | User not authorized | Insufficient permissions |
| not-found | 404 | Resource not found | Document doesn't exist |
| already-exists | 409 | Resource already exists | Duplicate entry |
| internal | 500 | Internal server error | Database/system error |
| unavailable | 503 | Service unavailable | Temporary outage |

### Error Response Format

```json
{
  "code": "string",
  "message": "string",
  "details": "string",
  "timestamp": "ISO8601"
}
```

---

## API Rate Limiting

### Current Limits

- **Cloud Functions**: 1,000 requests/second per function
- **Firestore**: Database-level quotas apply
- **Firebase Auth**: 50 auth operations/second per project

### Handling Rate Limits

When hitting rate limits, implement:
1. Exponential backoff (1s, 2s, 4s, 8s max)
2. Error handling for 429 status
3. Retry logic with max attempts (3-5)

**Example (Dart)**:

```dart
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
}) async {
  int attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      
      final delay = Duration(seconds: 1 << attempt);
      await Future.delayed(delay);
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

---

## API Versioning

### Version Strategy

- **Current Version**: v1
- **URL Pattern**: `/functions/v1/{endpoint}`
- **Backward Compatibility**: Maintained for 2 major versions
- **Deprecation**: 6-month notice period

### Version Roadmap

| Version | Status | Features |
|---------|--------|----------|
| v1 | Stable | Score submission, health check |
| v2 (planned) | Future | Batch operations, achievements API |
| v3 (planned) | Future | Real-time syncing, webhooks |

---

## API Usage Examples

### Complete Score Submission Flow

**Flutter Mobile App**:

```dart
// 1. Authenticate user
await FirebaseAuth.instance.signInAnonymously();

// 2. Get current user
final user = FirebaseAuth.instance.currentUser;

// 3. Submit score
final callable = FirebaseFunctions.instance.httpsCallable('submitScore');
try {
  final result = await callable.call({
    'score': 4250,
    'level': 7,
  });
  
  print('Leaderboard updated: ${result.data['scoreId']}');
  
  // 4. Update local UI
  showLeaderboard();
} catch (e) {
  print('Error submitting score: $e');
  showErrorDialog();
}
```

**React Web App**:

```typescript
import { initializeApp } from 'firebase/app';
import { getAuth, signInAnonymously } from 'firebase/auth';
import { getFunctions, httpsCallable } from 'firebase/functions';

const firebaseApp = initializeApp(firebaseConfig);
const auth = getAuth(firebaseApp);
const functions = getFunctions(firebaseApp);

async function submitGameScore(score: number, level: number) {
  try {
    // 1. Ensure user is authenticated
    if (!auth.currentUser) {
      await signInAnonymously(auth);
    }

    // 2. Call Cloud Function
    const submitScore = httpsCallable(functions, 'submitScore');
    const response = await submitScore({ score, level });
    
    console.log('Score submitted:', response.data);
    return response.data;
  } catch (error) {
    console.error('Failed to submit score:', error);
    throw error;
  }
}
```

### Monitoring API Usage

**View in Cloud Logging**:

```bash
# Filter Cloud Function invocations
gcloud logging read "resource.type=cloud_function AND function_name=submitScore" \
  --limit 50 \
  --format json
```

**View In Firebase Console**:
1. Go to Cloud Functions
2. Click function name
3. View "Logs" tab
4. Filter by timestamp or status

---

## Deployment & Container API

### Docker Deployment

The Cloud Functions can be containerized for deployment:

**Dockerfile** (packages/functions/Dockerfile):

```dockerfile
FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000
CMD ["node", "index.js"]
```

**Running Locally**:

```bash
# Build Docker image
docker build -t modulo-squares-api .

# Run container
docker run -p 3000:3000 \
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/service-account.json \
  -v $(pwd)/service-account.json:/app/service-account.json \
  modulo-squares-api

# Test health endpoint
curl http://localhost:3000/health
```

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| FIREBASE_PROJECT_ID | Firebase project | modulo-squares-dev |
| GOOGLE_APPLICATION_CREDENTIALS | Service account file | path/to/key.json |
| NODE_ENV | Environment | development/production |
| PORT | Server port | 3000 |

---

## API Testing

### Testing Tools

**Using curl**:

```bash
# Get Firebase ID token first
TOKEN=$(firebase auth get-access-token --email user@example.com)

# Submit score
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"score": 4250, "level": 7}' \
  https://us-central1-modulo-squares-dev.cloudfunctions.net/submitScore
```

**Using Postman**:

1. Set up Firebase Auth in Postman
2. Create POST request to Cloud Function
3. Add Authorization header with token
4. Set body: `{"score": 4250, "level": 7}`
5. Send request

**Using Jest/Node.js**:

```javascript
const functions = require('firebase-functions-test')();
const admin = require('firebase-admin');

describe('submitScore', () => {
  it('should store score in leaderboard', async () => {
    const wrapped = functions.wrap(require('./index').submitScore);
    
    const context = {
      auth: {
        uid: 'user123',
        email: 'test@example.com',
      },
    };
    
    const data = { score: 4250, level: 7 };
    
    const result = await wrapped(data, context);
    expect(result.success).toBe(true);
  });
});
```

---

## Performance & Optimization

### Request Times

| Operation | Expected Time | Notes |
|-----------|--------------|-------|
| Health check | < 50ms | No database query |
| Submit score | 200-500ms | Includes Firestore write |
| Firestore validation | 100-200ms | Rule evaluation |

### Optimization Tips

1. **Batch submissions**: Aggregate multiple scores if possible
2. **Caching**: Cache leaderboard top 100 in client
3. **Compression**: Enable gzip for responses
4. **Timeout handling**: Set client timeouts to 30 seconds

### Scaling Considerations

- Cloud Functions auto-scales to 1,000+ concurrent
- Firestore handles unlimited concurrent reads
- Cold starts: ~2 seconds on first invocation
- Warm starts: ~50-100ms per request

---

## Security

### Authentication

- All endpoints (except `/health`) require Firebase ID token
- Token validation via Firebase Admin SDK
- Token expiration: 1 hour
- Refresh handled automatically by client SDK

### Request Validation

```javascript
// Every endpoint must:
1. Verify authentication context
2. Validate input parameters
3. Check user permissions
4. Sanitize data before database write
5. Log security events
```

### Rate Limiting

Implemented at:
- Firebase Auth level
- Cloud Functions level
- Firestore write capacity

---

## API Changelog

### Version 1.0 (Current)

**Released**: 2024-12-15

**Endpoints**:
- `POST /submitScore` - Score submission
- `GET /health` - Health check

**Features**:
- Anonymous authentication
- Firestore integration
- Error handling
- Docker containerization

### Planned Features (v2.0)

- Batch score submission
- Leaderboard query endpoints
- User statistics endpoints
- Achievement system API
- Webhook events

---

## Related Documentation

- [System Architecture](SYSTEM_ARCHITECTURE.md)
- [Database Schema](DATABASE_SCHEMA.md)
- [Backend Services Guide](BACKEND_SERVICES_GUIDE.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
