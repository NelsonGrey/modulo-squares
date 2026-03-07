import * as functions from 'firebase-functions/v1';
import admin from 'firebase-admin';
import express from 'express';
import { fileURLToPath } from 'url';

// Import shared utilities
import { FunctionsAuthHelpers } from '@shared/firebase-utils';

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

// Cloud Function to validate and process leaderboard submissions
export const submitScore = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  const user = FunctionsAuthHelpers.verifyAuthenticated(context);
  const { uid, email } = user;

  const { score, level, clientTime } = data;

  // Comprehensive input validation
  if (typeof score !== 'number' || score < 0 || score > 999999 || !Number.isInteger(score)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid score: must be integer between 0-999999');
  }

  if (typeof level !== 'number' || level < 1 || level > 100 || !Number.isInteger(level)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid level: must be integer between 1-100');
  }

  try {
    // Rate limiting: Check user's last submission
    const userRef = admin.firestore().collection('users').doc(uid);
    const userData = await userRef.get();
    const lastSubmit = userData.data()?.lastScoreSubmit || 0;
    const now = Date.now();

    if (now - lastSubmit < 30000) { // 30 second minimum between submissions
      throw new functions.https.HttpsError('resource-exhausted', 'Too many submissions. Please wait 30 seconds.');
    }

    // Store score in Firestore with metadata for fraud detection
    await admin.firestore().collection('modulo_leaderboard').add({
      userId: uid,
      userEmail: email || 'anonymous',
      score,
      level,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      clientTime: clientTime || now,
      serverTime: now,
      ipAddress: context.rawRequest.ip,
    });

    // Update user's last submission timestamp
    await userRef.set(
      { lastScoreSubmit: now, email: email || '' },
      { merge: true }
    );

    return { success: true, message: 'Score submitted successfully' };
  } catch (error) {
    console.error('Error submitting score:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to submit score');
  }
});

// Cloud Function to get top scores
export const getTopScores = functions.https.onCall(async (data, context) => {
  const limit = data.limit || 10;

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
    throw new functions.https.HttpsError('internal', 'Failed to get top scores');
  }
});

// Cloud Function to validate purchases (server-side validation)
export const validatePurchase = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  const user = FunctionsAuthHelpers.verifyAuthenticated(context);
  const { uid } = user;

  const { productId, purchaseToken } = data;

  // In a real implementation, you would validate with the app store
  // For now, we'll just mark the purchase as valid
  try {
    const userId = uid;

    // Store purchase validation in Firestore
    await admin.firestore().collection('purchases').doc(userId).set({
      [productId]: {
        validated: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        purchaseToken,
      }
    }, { merge: true });

    return { valid: true, message: 'Purchase validated successfully' };
  } catch (error) {
    console.error('Error validating purchase:', error);
    throw new functions.https.HttpsError('internal', 'Failed to validate purchase');
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

  // Graceful shutdown handler
  const gracefulShutdown = (signal) => {
    console.log(`\nReceived ${signal}, shutting down gracefully...`);
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
    
    // Force shutdown after 30 seconds
    setTimeout(() => {
      console.error('Forced shutdown after timeout');
      process.exit(1);
    }, 30000);
  };

  // Handle process termination signals
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  
  // Handle uncaught exceptions
  process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error);
    gracefulShutdown('uncaughtException');
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled rejection at:', promise, 'reason:', reason);
    gracefulShutdown('unhandledRejection');
  });
}

export default app;