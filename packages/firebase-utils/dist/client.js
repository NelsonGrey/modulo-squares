// Firebase Client SDK Utilities
import { initializeApp, getApps } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getFunctions, connectFunctionsEmulator } from 'firebase/functions';
import { getStorage, connectStorageEmulator } from 'firebase/storage';
import { initializeApp as initializeAdminApp, getApps as getAdminApps } from 'firebase-admin/app';
import { getFirestore as getAdminFirestore, FieldValue, } from 'firebase-admin/firestore';
import { createRequire } from 'module';
const nodeRequire = createRequire(import.meta.url);
/**
 * Initialize Firebase app with singleton pattern
 */
export class FirebaseClient {
    static instance;
    _app;
    _auth;
    _firestore;
    _functions;
    _storage;
    constructor(config) {
        // Initialize Firebase app
        this._app = getApps().length === 0
            ? initializeApp(config)
            : getApps()[0];
        // Initialize services
        this._auth = getAuth(this._app);
        this._firestore = getFirestore(this._app);
        this._functions = getFunctions(this._app);
        this._storage = getStorage(this._app);
    }
    static initialize(config) {
        if (!FirebaseClient.instance) {
            FirebaseClient.instance = new FirebaseClient(config);
        }
        return FirebaseClient.instance;
    }
    static getInstance() {
        if (!FirebaseClient.instance) {
            throw new Error('Firebase not initialized. Call FirebaseClient.initialize() first.');
        }
        return FirebaseClient.instance;
    }
    // Getters for Firebase services
    get auth() {
        return this._auth;
    }
    get firestore() {
        return this._firestore;
    }
    get functions() {
        return this._functions;
    }
    get storage() {
        return this._storage;
    }
    get app() {
        return this._app;
    }
    /**
     * Connect to Firebase emulators in development
     */
    connectToEmulators() {
        if (process.env.NODE_ENV === 'development') {
            try {
                connectAuthEmulator(this._auth, "http://localhost:9099");
                connectFirestoreEmulator(this._firestore, 'localhost', 8080);
                connectFunctionsEmulator(this._functions, "localhost", 5001);
                connectStorageEmulator(this._storage, "localhost", 9199);
                console.log('🔗 Connected to Firebase emulators');
            }
            catch (error) {
                console.warn('⚠️  Could not connect to emulators:', error);
            }
        }
    }
}
/**
 * Authentication helpers
 */
export class AuthHelpers {
    static async getCurrentUser(auth) {
        return new Promise((resolve, reject) => {
            const unsubscribe = auth.onAuthStateChanged((user) => {
                unsubscribe();
                resolve(user);
            }, (error) => {
                unsubscribe();
                reject(error);
            });
        });
    }
    static async waitForAuth(auth) {
        return new Promise((resolve, reject) => {
            const unsubscribe = auth.onAuthStateChanged((user) => {
                unsubscribe();
                resolve(user);
            }, (error) => {
                unsubscribe();
                reject(error);
            });
            // Timeout after 10 seconds
            setTimeout(() => {
                unsubscribe();
                reject(new Error('Auth state timeout'));
            }, 10000);
        });
    }
}
/**
 * Firestore CRUD helpers for Firebase Functions
 */
export class FirestoreCrudHelpers {
    static get db() {
        if (!getAdminApps().length) {
            initializeAdminApp();
        }
        return getAdminFirestore();
    }
    /**
     * Create a document with standard metadata
     */
    static async createDocument(collection, data, userId, options) {
        const documentData = {
            ...data,
            createdBy: userId,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        };
        let docRef;
        if (options?.id) {
            docRef = this.db.collection(collection).doc(options.id);
            if (options?.merge) {
                await docRef.set(documentData, { merge: true });
            }
            else {
                await docRef.set(documentData);
            }
        }
        else {
            docRef = await this.db.collection(collection).add(documentData);
        }
        return {
            id: docRef.id,
            data: { ...documentData, id: docRef.id }
        };
    }
    /**
     * Get a document by ID
     */
    static async getDocument(collection, documentId) {
        const doc = await this.db.collection(collection).doc(documentId).get();
        if (!doc.exists) {
            return null;
        }
        return { id: doc.id, ...doc.data() };
    }
    /**
     * Update a document
     */
    static async updateDocument(collection, documentId, data, options) {
        const updateData = {
            ...data,
            updatedAt: FieldValue.serverTimestamp(),
        };
        if (options?.merge) {
            await this.db.collection(collection).doc(documentId).set(updateData, { merge: true });
        }
        else {
            await this.db.collection(collection).doc(documentId).update(updateData);
        }
    }
    /**
     * Delete a document
     */
    static async deleteDocument(collection, documentId) {
        await this.db.collection(collection).doc(documentId).delete();
    }
    /**
     * Query documents with filters
     */
    static async queryDocuments(collection, options) {
        let query = this.db.collection(collection);
        // Apply filters
        if (options?.filters) {
            options.filters.forEach(filter => {
                query = query.where(filter.field, filter.operator, filter.value);
            });
        }
        // Apply ordering
        if (options?.orderBy) {
            query = query.orderBy(options.orderBy.field, options.orderBy.direction);
        }
        // Apply limit
        if (options?.limit) {
            query = query.limit(options.limit);
        }
        // Apply offset (startAfter)
        if (options?.offset) {
            // This is a simplified version - in practice you'd need a document reference
            // query = query.startAfter(options.offset);
        }
        const snapshot = await query.get();
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    }
    /**
     * Batch operations
     */
    static async batchCreate(collection, documents, userId) {
        const batch = this.db.batch();
        const results = [];
        for (const doc of documents) {
            const documentData = {
                ...doc.data,
                createdBy: userId,
                createdAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
            };
            let docRef;
            if (doc.id) {
                docRef = this.db.collection(collection).doc(doc.id);
                batch.set(docRef, documentData);
            }
            else {
                docRef = this.db.collection(collection).doc();
                batch.set(docRef, documentData);
            }
            results.push({ id: docRef.id, data: { ...documentData, id: docRef.id } });
        }
        await batch.commit();
        return results;
    }
    static async batchUpdate(collection, updates) {
        const batch = this.db.batch();
        for (const update of updates) {
            const updateData = {
                ...update.data,
                updatedAt: FieldValue.serverTimestamp(),
            };
            const docRef = this.db.collection(collection).doc(update.id);
            batch.update(docRef, updateData);
        }
        await batch.commit();
    }
    static async batchDelete(collection, documentIds) {
        const batch = this.db.batch();
        for (const id of documentIds) {
            const docRef = this.db.collection(collection).doc(id);
            batch.delete(docRef);
        }
        await batch.commit();
    }
}
/**
 * Functions helpers
 */
export class FunctionsHelpers {
    static async callFunction(functions, name, data) {
        const { httpsCallable } = await import('firebase/functions');
        const callable = httpsCallable(functions, name);
        const result = await callable(data);
        return result.data;
    }
}
/**
 * Storage helpers
 */
export class StorageHelpers {
    static async uploadFile(storage, path, file) {
        const { ref, uploadBytes, getDownloadURL } = await import('firebase/storage');
        const storageRef = ref(storage, path);
        await uploadBytes(storageRef, file);
        return getDownloadURL(storageRef);
    }
    static async deleteFile(storage, path) {
        const { ref, deleteObject } = await import('firebase/storage');
        const storageRef = ref(storage, path);
        await deleteObject(storageRef);
    }
}
/**
 * Authentication helpers for Firebase Functions
 */
export class FunctionsAuthHelpers {
    /**
     * Verify user is authenticated and return user info
     * Throws HttpsError if not authenticated
     */
    static verifyAuthenticated(context) {
        if (!context.auth) {
            const { HttpsError } = nodeRequire('firebase-functions/v1/https');
            throw new HttpsError('unauthenticated', 'User must be authenticated');
        }
        return {
            uid: context.auth.uid,
            email: context.auth.token.email,
            token: context.auth.token
        };
    }
    /**
     * Check if user is authenticated without throwing
     */
    static isAuthenticated(context) {
        return !!context.auth;
    }
    /**
     * Get user ID if authenticated, null otherwise
     */
    static getUserId(context) {
        return context.auth?.uid || null;
    }
    /**
     * Get user email if authenticated, null otherwise
     */
    static getUserEmail(context) {
        return context.auth?.token?.email || null;
    }
    /**
     * Verify user has specific custom claims
     */
    static verifyCustomClaims(context, requiredClaims) {
        const user = this.verifyAuthenticated(context);
        for (const [key, value] of Object.entries(requiredClaims)) {
            if (user.token[key] !== value) {
                const { HttpsError } = nodeRequire('firebase-functions/v1/https');
                throw new HttpsError('permission-denied', `Missing required claim: ${key}=${value}`);
            }
        }
    }
}
