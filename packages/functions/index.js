import { onCall, HttpsError } from 'firebase-functions/v2/https';
import admin from 'firebase-admin';
import express from 'express';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

admin.initializeApp();

// Create Express app for Docker deployment
const app = express();
app.use(express.json());

// Health check endpoint for Docker
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'modulo-squares-api'
  });
});

const SCORE_SUBMIT_MIN_INTERVAL_MS = 15000;
const SCORE_SESSION_TTL_MS = 20 * 60 * 1000;
const PURCHASE_PRODUCTS = new Set(['remove_ads', 'premium_version']);

function verifyAuth(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }
  return {
    uid: request.auth.uid,
    email: request.auth.token?.email,
    token: request.auth.token,
  };
}

function validateLeaderboardPayload({ score, level, playerName }) {
  if (typeof score !== 'number' || score < 0 || score > 999999 || !Number.isInteger(score)) {
    throw new HttpsError('invalid-argument', 'Invalid score: must be integer between 0-999999');
  }

  if (typeof level !== 'number' || level < 1 || level > 200 || !Number.isInteger(level)) {
    throw new HttpsError('invalid-argument', 'Invalid level: must be integer between 1-200');
  }

  if (typeof playerName !== 'string' || playerName.trim().length < 1 || playerName.trim().length > 50) {
    throw new HttpsError('invalid-argument', 'Invalid player name: must be 1-50 characters');
  }

  return playerName.trim();
}

async function enforceScoreRateLimit(uid, bucketKey) {
  const userRef = admin.firestore().collection('users').doc(uid);
  const userSnap = await userRef.get();
  const now = Date.now();
  const rateLimits = userSnap.data()?.scoreSubmitRateLimits || {};
  const lastSubmit = Number(rateLimits[bucketKey] || 0);

  if (now - lastSubmit < SCORE_SUBMIT_MIN_INTERVAL_MS) {
    throw new HttpsError(
      'resource-exhausted',
      'Too many submissions. Please wait before submitting again.'
    );
  }

  await userRef.set(
    {
      scoreSubmitRateLimits: {
        [bucketKey]: now,
      },
      lastScoreSubmit: now,
    },
    { merge: true }
  );

  return now;
}

async function issueScoreSession({ uid, mode, challengeId = null, weekId = null }) {
  const sessionRef = admin.firestore().collection('score_sessions').doc();
  const now = Date.now();
  const expiresAt = now + SCORE_SESSION_TTL_MS;
  const nonce = crypto.randomBytes(16).toString('hex');

  await sessionRef.set({
    uid,
    mode,
    challengeId,
    weekId,
    nonce,
    issuedAt: now,
    expiresAt,
    consumed: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    sessionId: sessionRef.id,
    nonce,
    expiresAt,
  };
}

async function consumeScoreSession({ uid, sessionId, mode, challengeId = null, weekId = null }) {
  if (typeof sessionId !== 'string' || sessionId.trim().length < 8) {
    throw new HttpsError('failed-precondition', 'Missing or invalid score session');
  }

  const ref = admin.firestore().collection('score_sessions').doc(sessionId.trim());
  const snap = await ref.get();
  const now = Date.now();

  if (!snap.exists) {
    throw new HttpsError('failed-precondition', 'Score session not found');
  }

  const data = snap.data() || {};
  if (data.uid !== uid) {
    throw new HttpsError('permission-denied', 'Score session does not belong to caller');
  }
  if (data.consumed === true) {
    throw new HttpsError('failed-precondition', 'Score session already consumed');
  }
  if (typeof data.expiresAt !== 'number' || data.expiresAt < now) {
    throw new HttpsError('failed-precondition', 'Score session expired');
  }
  if (data.mode !== mode) {
    throw new HttpsError('failed-precondition', 'Score session mode mismatch');
  }
  if (mode === 'daily' && Number(data.challengeId) !== Number(challengeId)) {
    throw new HttpsError('failed-precondition', 'Score session challenge mismatch');
  }
  if (mode === 'weekly' && Number(data.weekId) !== Number(weekId)) {
    throw new HttpsError('failed-precondition', 'Score session week mismatch');
  }

  await ref.set(
    {
      consumed: true,
      consumedAt: now,
      consumedAtServer: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export const startScoreSession = onCall(async (request) => {
  const user = verifyAuth(request);
  const { uid } = user;
  const mode = request.data?.mode;

  if (!['global', 'daily', 'weekly'].includes(mode)) {
    throw new HttpsError('invalid-argument', 'Invalid score mode');
  }

  let challengeId = null;
  let weekId = null;

  if (mode === 'daily') {
    challengeId = request.data?.challengeId;
    if (typeof challengeId !== 'number' || challengeId <= 0 || !Number.isInteger(challengeId)) {
      throw new HttpsError('invalid-argument', 'Invalid challenge id');
    }
  }

  if (mode === 'weekly') {
    weekId = request.data?.weekId;
    if (typeof weekId !== 'number' || weekId <= 0 || !Number.isInteger(weekId)) {
      throw new HttpsError('invalid-argument', 'Invalid week id');
    }
  }

  return issueScoreSession({ uid, mode, challengeId, weekId });
});

export const submitScore = onCall(async (request) => {
  const user = verifyAuth(request);
  const { uid, email } = user;

  const { score, level, clientTime, playerName, scoreSessionId } = request.data;
  const safePlayerName = validateLeaderboardPayload({ score, level, playerName });

  try {
    await consumeScoreSession({ uid, sessionId: scoreSessionId, mode: 'global' });
    const now = await enforceScoreRateLimit(uid, 'global');

    const leaderboardRef = admin.firestore().collection('modulo_leaderboard').doc(uid);
    const existing = await leaderboardRef.get();
    const existingScore = Number(existing.data()?.score || 0);
    const bestScore = Math.max(existingScore, score);

    await leaderboardRef.set({
      userId: uid,
      playerName: safePlayerName,
      userEmail: email || 'anonymous',
      score: bestScore,
      level,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      clientTime: clientTime || now,
      serverTime: now,
      ipAddress: request.rawRequest.ip,
    }, { merge: true });

    return { success: true, message: 'Score submitted successfully' };
  } catch (error) {
    console.error('Error submitting score:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Failed to submit score');
  }
});

export const submitDailyScore = onCall(async (request) => {
  const user = verifyAuth(request);
  const { uid } = user;
  const { challengeId, score, level, playerName, clientTime, scoreSessionId } = request.data;

  if (typeof challengeId !== 'number' || challengeId <= 0 || !Number.isInteger(challengeId)) {
    throw new HttpsError('invalid-argument', 'Invalid challenge id');
  }

  const safePlayerName = validateLeaderboardPayload({ score, level, playerName });

  try {
    await consumeScoreSession({
      uid,
      sessionId: scoreSessionId,
      mode: 'daily',
      challengeId,
    });
    const now = await enforceScoreRateLimit(uid, `daily_${challengeId}`);
    const docRef = admin
      .firestore()
      .collection('modulo_daily_leaderboard')
      .doc(String(challengeId))
      .collection('scores')
      .doc(uid);

    const existing = await docRef.get();
    const existingScore = Number(existing.data()?.score || 0);
    const bestScore = Math.max(existingScore, score);

    await docRef.set({
      userId: uid,
      playerName: safePlayerName,
      challengeId,
      score: bestScore,
      level,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      clientTime: clientTime || now,
      serverTime: now,
      ipAddress: request.rawRequest.ip,
    }, { merge: true });

    return { success: true, message: 'Daily score submitted successfully' };
  } catch (error) {
    console.error('Error submitting daily score:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Failed to submit daily score');
  }
});

export const submitWeeklyScore = onCall(async (request) => {
  const user = verifyAuth(request);
  const { uid } = user;
  const { weekId, score, level, playerName, clientTime, scoreSessionId } = request.data;

  if (typeof weekId !== 'number' || weekId <= 0 || !Number.isInteger(weekId)) {
    throw new HttpsError('invalid-argument', 'Invalid week id');
  }

  const safePlayerName = validateLeaderboardPayload({ score, level, playerName });

  try {
    await consumeScoreSession({
      uid,
      sessionId: scoreSessionId,
      mode: 'weekly',
      weekId,
    });
    const now = await enforceScoreRateLimit(uid, `weekly_${weekId}`);
    const docRef = admin
      .firestore()
      .collection('modulo_weekly_leaderboard')
      .doc(String(weekId))
      .collection('scores')
      .doc(uid);

    const existing = await docRef.get();
    const existingScore = Number(existing.data()?.score || 0);
    const bestScore = Math.max(existingScore, score);

    await docRef.set({
      userId: uid,
      playerName: safePlayerName,
      weekId,
      score: bestScore,
      level,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      clientTime: clientTime || now,
      serverTime: now,
      ipAddress: request.rawRequest.ip,
    }, { merge: true });

    return { success: true, message: 'Weekly score submitted successfully' };
  } catch (error) {
    console.error('Error submitting weekly score:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Failed to submit weekly score');
  }
});

export const getTopScores = onCall(async (request) => {
  const limit = request.data?.limit || 10;

  try {
    const snapshot = await admin.firestore()
      .collection('modulo_leaderboard')
      .orderBy('score', 'desc')
      .limit(limit)
      .get();

    const scores = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { scores };
  } catch (error) {
    console.error('Error getting top scores:', error);
    throw new HttpsError('internal', 'Failed to get top scores');
  }
});

export const validatePurchase = onCall(async (request) => {
  const user = verifyAuth(request);
  const { uid, email } = user;

  const { productId, purchaseToken, transactionId, platform } = request.data;

  if (!PURCHASE_PRODUCTS.has(productId)) {
    throw new HttpsError('invalid-argument', 'Unsupported product id');
  }
  if (typeof purchaseToken !== 'string' || purchaseToken.length < 10 || purchaseToken.length > 4096) {
    throw new HttpsError('invalid-argument', 'Invalid purchase token');
  }
  if (!['ios', 'android'].includes(platform)) {
    throw new HttpsError('invalid-argument', 'Invalid purchase platform');
  }

  const txId =
    typeof transactionId === 'string' && transactionId.trim().length > 0
      ? transactionId.trim()
      : crypto.createHash('sha256').update(`${uid}:${productId}:${purchaseToken}`).digest('hex');

  try {
    const entitlementsRef = admin.firestore().collection('entitlements').doc(uid);
    const txRef = admin
      .firestore()
      .collection('purchases')
      .doc(uid)
      .collection('transactions')
      .doc(txId);

    await txRef.set(
      {
        uid,
        email: email || null,
        productId,
        platform,
        purchaseTokenHash: crypto.createHash('sha256').update(purchaseToken).digest('hex'),
        status: 'validated_locally',
        validatedAt: Date.now(),
        validatedAtServer: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const entitlementPatch = {
      adsRemoved: productId === 'remove_ads' || productId === 'premium_version',
      premiumUnlocked: productId === 'premium_version',
      updatedAt: Date.now(),
      updatedAtServer: admin.firestore.FieldValue.serverTimestamp(),
      source: 'validatePurchaseCallable',
      lastProductId: productId,
      lastTransactionId: txId,
    };

    await entitlementsRef.set(entitlementPatch, { merge: true });

    return {
      valid: true,
      message: 'Purchase validated successfully',
      entitlements: {
        adsRemoved: entitlementPatch.adsRemoved,
        premiumUnlocked: entitlementPatch.premiumUnlocked,
      },
    };
  } catch (error) {
    console.error('Error validating purchase:', error);
    throw new HttpsError('internal', 'Failed to validate purchase');
  }
});

export const getEntitlements = onCall(async (request) => {
  const user = verifyAuth(request);
  const { uid } = user;

  try {
    const entitlementsRef = admin.firestore().collection('entitlements').doc(uid);
    const snap = await entitlementsRef.get();
    const data = snap.data() || {};

    return {
      adsRemoved: data.adsRemoved === true,
      premiumUnlocked: data.premiumUnlocked === true,
      updatedAt: data.updatedAt || null,
    };
  } catch (error) {
    console.error('Error getting entitlements:', error);
    throw new HttpsError('internal', 'Failed to get entitlements');
  }
});

async function deleteCollection(ref) {
  const snap = await ref.get();
  if (snap.empty) return;
  const batch = admin.firestore().batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

export const deleteAccount = onCall(async (request) => {
  const { uid } = verifyAuth(request);
  const firestore = admin.firestore();

  try {
    await deleteCollection(
      firestore.collection('purchases').doc(uid).collection('transactions')
    );

    const gamertagsSnap = await firestore
      .collection('gamertags')
      .where('uid', '==', uid)
      .get();
    if (!gamertagsSnap.empty) {
      const batch = firestore.batch();
      gamertagsSnap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    await Promise.all([
      firestore.collection('users').doc(uid).delete(),
      firestore.collection('user_profiles').doc(uid).delete(),
      firestore.collection('game_stats').doc(uid).delete(),
      firestore.collection('entitlements').doc(uid).delete(),
      firestore.collection('purchases').doc(uid).delete(),
      firestore.collection('modulo_leaderboard').doc(uid).delete(),
    ]);

    await admin.auth().deleteUser(uid);

    return { success: true };
  } catch (error) {
    console.error('Error deleting account:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Failed to delete account');
  }
});

// Start Express server for Docker deployment
const entryFile = process.argv[1] ?? '';
const currentFile = fileURLToPath(import.meta.url);
if (entryFile === currentFile) {
  const PORT = process.env.PORT || 3000;
  const server = app.listen(PORT, () => {
    console.log(`🚀 Modulo Squares API running on port ${PORT}`);
  });

  const gracefulShutdown = (signal) => {
    console.log(`\nReceived ${signal}, shutting down gracefully...`);
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });

    setTimeout(() => {
      console.error('Forced shutdown after timeout');
      process.exit(1);
    }, 30000);
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error);
    gracefulShutdown('uncaughtException');
  });

  process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled rejection at:', promise, 'reason:', reason);
    gracefulShutdown('unhandledRejection');
  });
}

export default app;
