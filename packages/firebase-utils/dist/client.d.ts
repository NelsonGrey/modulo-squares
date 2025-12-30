import { FirebaseApp } from 'firebase/app';
import { Auth } from 'firebase/auth';
import { Firestore } from 'firebase/firestore';
import { Functions } from 'firebase/functions';
import { FirebaseStorage } from 'firebase/storage';
import * as admin from 'firebase-admin';
export interface FirebaseConfig {
    apiKey: string;
    authDomain: string;
    projectId: string;
    storageBucket: string;
    messagingSenderId: string;
    appId: string;
    measurementId?: string;
}
/**
 * Initialize Firebase app with singleton pattern
 */
export declare class FirebaseClient {
    private static instance;
    private _app;
    private _auth;
    private _firestore;
    private _functions;
    private _storage;
    private constructor();
    static initialize(config: FirebaseConfig): FirebaseClient;
    static getInstance(): FirebaseClient;
    get auth(): Auth;
    get firestore(): Firestore;
    get functions(): Functions;
    get storage(): FirebaseStorage;
    get app(): FirebaseApp;
    /**
     * Connect to Firebase emulators in development
     */
    connectToEmulators(): void;
}
/**
 * Authentication helpers
 */
export declare class AuthHelpers {
    static getCurrentUser(auth: Auth): Promise<unknown>;
    static waitForAuth(auth: Auth): Promise<any>;
}
/**
 * Firestore CRUD helpers for Firebase Functions
 */
export declare class FirestoreCrudHelpers {
    private static db;
    /**
     * Create a document with standard metadata
     */
    static createDocument(collection: string, data: any, userId: string, options?: {
        id?: string;
        merge?: boolean;
    }): Promise<{
        id: string;
        data: any;
    }>;
    /**
     * Get a document by ID
     */
    static getDocument(collection: string, documentId: string): Promise<any | null>;
    /**
     * Update a document
     */
    static updateDocument(collection: string, documentId: string, data: any, options?: {
        merge?: boolean;
    }): Promise<void>;
    /**
     * Delete a document
     */
    static deleteDocument(collection: string, documentId: string): Promise<void>;
    /**
     * Query documents with filters
     */
    static queryDocuments(collection: string, options?: {
        filters?: Array<{
            field: string;
            operator: admin.firestore.WhereFilterOp;
            value: any;
        }>;
        orderBy?: {
            field: string;
            direction: 'asc' | 'desc';
        };
        limit?: number;
        offset?: number;
    }): Promise<any[]>;
    /**
     * Batch operations
     */
    static batchCreate(collection: string, documents: Array<{
        data: any;
        id?: string;
    }>, userId: string): Promise<Array<{
        id: string;
        data: any;
    }>>;
    static batchUpdate(collection: string, updates: Array<{
        id: string;
        data: any;
    }>): Promise<void>;
    static batchDelete(collection: string, documentIds: string[]): Promise<void>;
}
/**
 * Functions helpers
 */
export declare class FunctionsHelpers {
    static callFunction(functions: Functions, name: string, data?: any): Promise<unknown>;
}
/**
 * Storage helpers
 */
export declare class StorageHelpers {
    static uploadFile(storage: FirebaseStorage, path: string, file: File): Promise<string>;
    static deleteFile(storage: FirebaseStorage, path: string): Promise<void>;
}
/**
 * Authentication helpers for Firebase Functions
 */
export declare class FunctionsAuthHelpers {
    /**
     * Verify user is authenticated and return user info
     * Throws HttpsError if not authenticated
     */
    static verifyAuthenticated(context: any): {
        uid: string;
        email?: string;
        token: any;
    };
    /**
     * Check if user is authenticated without throwing
     */
    static isAuthenticated(context: any): boolean;
    /**
     * Get user ID if authenticated, null otherwise
     */
    static getUserId(context: any): string | null;
    /**
     * Get user email if authenticated, null otherwise
     */
    static getUserEmail(context: any): string | null;
    /**
     * Verify user has specific custom claims
     */
    static verifyCustomClaims(context: any, requiredClaims: Record<string, any>): void;
}
