# Modulo Monorepo Workspace Configuration

This file defines the workspace structure for the Modulo Squares monorepo.

## Packages
- `packages/app`: Main Flutter application
- `packages/functions`: Firebase Cloud Functions
- `packages/firestore-rules`: Firestore security rules
- `packages/shared`: Shared utilities and types

## Development Setup
1. Run `npm install` in the root directory
2. Run `npm run install:all` to install all package dependencies
3. Use `cd packages/app && flutter run` to run the Flutter app
4. Use `firebase emulators:start` to run Firebase emulators locally