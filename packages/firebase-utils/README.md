# `@shared/firebase-utils`

TypeScript ESM utilities shared by Firebase-oriented projects. The package exports:

- `FirebaseClient` and `FirebaseConfig`
- `AuthHelpers`
- `FirestoreCrudHelpers`
- `FunctionsHelpers`
- `FunctionsAuthHelpers`
- `StorageHelpers`

The package includes both Firebase client SDK and Admin SDK dependencies. Admin helpers initialize the default Admin app lazily.

## Commands

```bash
npm install
npm run lint
npm run check
npm run build
```

Build output is committed under `dist/`. Source remains authoritative.

`npm test` is configured for Vitest but no test files are currently present; Vitest therefore exits with code 1 (`No test files found`). Add tests before making that command a required gate.
