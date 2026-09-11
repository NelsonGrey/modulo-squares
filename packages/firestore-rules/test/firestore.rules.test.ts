import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { assertFails, assertSucceeds, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { getTestEnv } from './setup.js';

const OWNER_UID = 'user-owner';
const OTHER_UID = 'user-other';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await getTestEnv();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('deny by default', () => {
  it('denies an unauthenticated read of an arbitrary, unlisted collection', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'totally_unlisted_collection', 'doc1')));
  });

  it('denies an unauthenticated write to an arbitrary, unlisted collection', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, 'totally_unlisted_collection', 'doc1'), { x: 1 }));
  });

  it('denies an authenticated write to an arbitrary, unlisted collection', async () => {
    // Being signed in doesn't grant access to collections the rules never
    // mention -- there is no catch-all "any authenticated user" rule.
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertFails(setDoc(doc(db, 'totally_unlisted_collection', 'doc1'), { x: 1 }));
    await assertFails(getDoc(doc(db, 'totally_unlisted_collection', 'doc1')));
  });
});

describe('leaderboards are public-read, server-write-only', () => {
  const cases: Array<{ name: string; path: string }> = [
    { name: 'global leaderboard', path: 'modulo_leaderboard/entry1' },
    {
      name: 'daily leaderboard bucket',
      path: 'modulo_daily_leaderboard/challenge-2026-09-11/scores/entry1',
    },
    {
      name: 'weekly leaderboard bucket',
      path: 'modulo_weekly_leaderboard/week-2026-37/scores/entry1',
    },
  ];

  for (const { name, path } of cases) {
    it(`allows an unauthenticated point read of the ${name}`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertSucceeds(getDoc(doc(db, path)));
    });

    it(`denies an unauthenticated client write to the ${name}`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(setDoc(doc(db, path), { score: 999999 }));
    });

    it(`denies an authenticated client write to the ${name} (server-only)`, async () => {
      // Score submission is server-authoritative via Cloud Functions; being
      // signed in must not be enough to write a leaderboard entry directly.
      const db = testEnv.authenticatedContext(OWNER_UID).firestore();
      await assertFails(setDoc(doc(db, path), { score: 999999 }));
    });
  }

  for (const { name, path } of [
    { name: 'global leaderboard', path: 'modulo_leaderboard' },
    {
      name: 'daily leaderboard scores',
      path: 'modulo_daily_leaderboard/challenge-2026-09-11/scores',
    },
    {
      name: 'weekly leaderboard scores',
      path: 'modulo_weekly_leaderboard/week-2026-37/scores',
    },
  ]) {
    it(`allows an unauthenticated list query of the ${name} collection`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertSucceeds(getDocs(collection(db, path)));
    });
  }
});

describe('purchases and entitlements are owner-read, server-write-only', () => {
  // The suite's top-level `afterEach` clears the whole emulator after every
  // test, so this fixture must be re-seeded in `beforeEach` -- a `beforeAll`
  // here would only survive for the first test in this block and every
  // later test would silently run against documents that no longer exist.
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'purchases', OWNER_UID), { verified: true });
      await setDoc(doc(db, 'purchases', OWNER_UID, 'transactions', 'txn1'), { productId: 'coins_100' });
      await setDoc(doc(db, 'entitlements', OWNER_UID), { premium: true });
    });
  });

  it('lets the owner read their own purchases document', async () => {
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'purchases', OWNER_UID)));
  });

  it('lets the owner read their own purchase transaction subdocument', async () => {
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'purchases', OWNER_UID, 'transactions', 'txn1')));
  });

  it("denies another authenticated user reading someone else's purchase transaction subdocument", async () => {
    // The transactions subcollection has its own security-rule match
    // separate from the parent purchases document -- exercise it directly
    // rather than only the parent doc, since a regression scoped to just
    // this nested match wouldn't otherwise be caught.
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(getDoc(doc(db, 'purchases', OWNER_UID, 'transactions', 'txn1')));
  });

  it("denies another authenticated user reading someone else's purchases", async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(getDoc(doc(db, 'purchases', OWNER_UID)));
  });

  it('denies an unauthenticated read of purchases', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'purchases', OWNER_UID)));
  });

  it('denies the owner writing to their own purchases document (server-only)', async () => {
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertFails(setDoc(doc(db, 'purchases', OWNER_UID), { verified: false }));
  });

  it('lets the owner read their own entitlements document', async () => {
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'entitlements', OWNER_UID)));
  });

  it("denies another authenticated user reading someone else's entitlements", async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(getDoc(doc(db, 'entitlements', OWNER_UID)));
  });

  it('denies an unauthenticated read of entitlements', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'entitlements', OWNER_UID)));
  });

  it('denies the owner writing to their own entitlements document (server-only)', async () => {
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertFails(setDoc(doc(db, 'entitlements', OWNER_UID), { premium: false }));
  });
});

describe('owned user documents (profiles, stats, users)', () => {
  const ownedCollections = ['user_profiles', 'game_stats', 'users'];

  for (const collectionName of ownedCollections) {
    it(`lets the owner read and write their own ${collectionName} document`, async () => {
      const db = testEnv.authenticatedContext(OWNER_UID).firestore();
      await assertSucceeds(setDoc(doc(db, collectionName, OWNER_UID), { updatedAt: 1 }));
      await assertSucceeds(getDoc(doc(db, collectionName, OWNER_UID)));
    });

    it(`lets the owner update their own already-existing ${collectionName} document`, async () => {
      // The test above only ever writes to a previously-absent document,
      // which the rules evaluate as a `create`. Seed an existing doc here
      // and write to it again so the `update` path is exercised too -- a
      // regression that allows create but denies update wouldn't be caught
      // otherwise.
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), collectionName, OWNER_UID), { updatedAt: 1 });
      });
      const db = testEnv.authenticatedContext(OWNER_UID).firestore();
      await assertSucceeds(setDoc(doc(db, collectionName, OWNER_UID), { updatedAt: 2 }));
      const snap = await getDoc(doc(db, collectionName, OWNER_UID));
      expect(snap.data()).toEqual({ updatedAt: 2 });
    });

    it(`denies another authenticated user reading someone else's ${collectionName} document`, async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), collectionName, OWNER_UID), { updatedAt: 1 });
      });
      const db = testEnv.authenticatedContext(OTHER_UID).firestore();
      await assertFails(getDoc(doc(db, collectionName, OWNER_UID)));
    });

    it(`denies another authenticated user writing to someone else's ${collectionName} document`, async () => {
      const db = testEnv.authenticatedContext(OTHER_UID).firestore();
      await assertFails(setDoc(doc(db, collectionName, OWNER_UID), { updatedAt: 2 }));
    });

    it(`denies an unauthenticated user reading or writing a ${collectionName} document`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(db, collectionName, OWNER_UID)));
      await assertFails(setDoc(doc(db, collectionName, OWNER_UID), { updatedAt: 1 }));
    });
  }
});

describe('gamertag uniqueness index', () => {
  it('lets any authenticated user read a gamertag doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'gamertags', 'CoolPlayer'), {});
    });
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'gamertags', 'CoolPlayer')));
  });

  it('denies an unauthenticated user reading a gamertag doc', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'gamertags', 'CoolPlayer')));
  });

  it('lets an authenticated user claim a brand-new gamertag', async () => {
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, 'gamertags', 'FreshTag'), {}));
  });

  it('denies an unauthenticated user claiming a gamertag', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, 'gamertags', 'FreshTag'), {}));
  });

  it('denies overwriting an already-claimed gamertag, even by an authenticated user', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'gamertags', 'TakenTag'), {});
    });
    // A set() against an existing doc is evaluated as an `update`, and
    // the rules hard-deny update regardless of who's asking -- this is
    // what actually enforces uniqueness (first writer wins, forever).
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(setDoc(doc(db, 'gamertags', 'TakenTag'), { claimedBy: OTHER_UID }));
  });

  it('denies deleting a gamertag doc, even by an authenticated user', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'gamertags', 'TakenTag'), {});
    });
    const db = testEnv.authenticatedContext(OWNER_UID).firestore();
    await assertFails(deleteDoc(doc(db, 'gamertags', 'TakenTag')));
  });

  it('documents that an owner uid field is readable if application code writes one', async () => {
    // Rules do not strip fields; avoiding owner fields is an application-level contract.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'gamertags', 'NoOwnerField'), { ownerUid: OWNER_UID });
    });
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    const snap = await assertSucceeds(getDoc(doc(db, 'gamertags', 'NoOwnerField')));
    expect(snap.data()).toEqual({ ownerUid: OWNER_UID });
  });
});
