import { initializeApp, getApp, getApps } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
export const db = getFirestore(app);

// A second, fully independent Firebase App instance used only by
// EnvironmentGate's team-access check on the dev/staging web deployments. It
// shares the same project config but keeps its own Auth instance and session,
// so the gate's Google Sign-In never touches the default `app` above (which
// this promo site otherwise uses only for anonymous Firestore reads).
const GATE_APP_NAME = 'modulo-squares-gate';
const gateApp = (() => {
  try {
    return getApp(GATE_APP_NAME);
  } catch {
    return initializeApp(firebaseConfig, GATE_APP_NAME);
  }
})();
export const gateAuth = getAuth(gateApp);
