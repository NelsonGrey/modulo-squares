# Copilot instructions for Modulo Squares

**Updated**: 2026-07-20

## Source of truth

- Read `README.md`, `docs/Current_State.md`, and `docs/Documentation_Index.md` first.
- Active native gameplay is `GameScreen` -> `FallingModuloGameScreen`.
- `GameBoard`, `GameProvider`, grid widgets, and `InstructionsScreen` are legacy/reference code unless a task explicitly targets them.
- Firebase Hosting deploys the React site in `packages/web`; Flutter `WebsiteScreen` is not the public site.
- `.github/workflows/ci-cd.yml` is the active pipeline. Files under `.github/workflows/archive` are inactive.
- Cloud Functions source is in private repo `NelsonGrey/modulo-squares-functions`; `packages/functions` is an ignored checkout path.

## Project map

- `packages/mobile`: Flutter app and tests.
- `packages/web`: React/Vite/Tailwind marketing site and public leaderboard.
- `packages/firebase-utils`: TypeScript Firebase client/admin helpers.
- `packages/firestore-rules`: Firestore rules.
- `packages/shared`: reserved; currently empty of runtime code.
- `scripts`: signing, config, deployment, and runner tools.

## Mobile conventions

- Keep falling-mode rules framework-free in `falling_modulo_game_engine.dart` and cover rule changes with unit tests.
- Keep plugin effects and UI state outside the pure engine.
- Treat leaderboard, purchase, entitlement, and account-deletion operations as server-authoritative.
- Do not assume retained Provider/Clean Architecture classes are on the live gameplay path.
- Guard Firebase/platform calls in widget tests where existing code supports uninitialized Firebase.

## Web conventions

- Add routes in `src/App.tsx` and add indexable routes to `public/sitemap.xml`.
- Use `SEOHead` on route pages.
- Keep GTM/GA4 as the website analytics path; do not add Firebase Analytics to React.
- Preserve default-denied Consent Mode before GTM and keep privacy/cookie disclosures aligned with source.

## Validation

```bash
npm run lint
npm run check
npm run build:web

cd packages/mobile
flutter analyze
flutter test
```

Add iOS/Android release builds, browser checks, rules tests, or private Functions tests in proportion to the change.

## Safety

- Never expose or commit secrets, service accounts, receipts, signing material, or ignored environment files.
- Do not deploy Functions without separately checking the private repo branch/status.
- Firestore rule changes require an explicit rules deploy; normal Hosting/Functions jobs do not deploy them.
- Update current documentation whenever gameplay, routes, API contracts, workflows, or release state changes.
