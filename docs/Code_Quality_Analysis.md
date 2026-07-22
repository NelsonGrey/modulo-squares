# Code Quality Analysis

**Audit date**: 2026-07-20
**Scope**: public tracked source/config/tests/workflows plus ignored/generated artifacts at inventory level

## Summary

The repository has strong Flutter unit/widget coverage and a clear active delivery workflow, but it carries significant legacy surface area and had substantial documentation drift. The documentation set has been reconciled during this audit.

## Validation results

Run on 2026-07-20:

- `npm run lint`: passed for React and Firebase utilities.
- `npm run check`: passed TypeScript checks for both packages.
- `npm run build:web`: passed production Vite build.
- `npm run build` in `packages/firebase-utils`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: all 325 tests passed.
- `bash -n` across tracked shell scripts: passed.
- maintained Markdown local-link check: 0 broken or case-incorrect links across 69 tracked/new docs.
- store metadata: short description 79/80 characters, keywords 81/100, description 1203/4000.
- `npm test -- --run` in `packages/firebase-utils`: failed because no test files exist; recorded below as a coverage gap.

## Strengths

- Active falling-mode rules are isolated in a pure engine with deterministic tests.
- Startup and Firebase use defensive initialization/fallbacks.
- Leaderboards and purchases use server-authoritative callable paths.
- Firestore rules deny privileged client writes.
- Account deletion is visible in Settings and invokes a backend cleanup path.
- React builds with TypeScript and has route-level SEO, sitemap, robots, consent, and legal pages.
- CI uses GitHub-hosted runners for normal delivery and keeps the self-hosted device flow optional.
- Functions business logic is separated from the public repository.

## Current concerns

### P1: live and legacy game implementations coexist

`GameScreen` routes only to falling mode, but old board classes, providers, instructions, analytics events, and tests remain. This raises maintenance and product-copy risk. Either formalize the old mode as a supported future module or move it to an explicitly named legacy/archive area.

### P1: server source is not available in the normal checkout

The public client contract can be audited, but score validation, rate limits, receipt verification, data deletion, and App Check enforcement require the private Functions repository. Add a cross-repository contract/test process.

### P1: current gameplay is disconnected from leaderboard claims

Leaderboard services, screens, callable contracts, and public web reads exist, but `FallingModuloGameScreen` neither submits scores nor opens leaderboard UI. Store/marketing claims should be constrained until the falling run is wired to an appropriate leaderboard contract.

### P1: rules are not deployed by the normal pipeline

The active Hosting job deploys Hosting and the Functions job deploys Functions. Neither deploys Firestore rules. Add an explicit rules job or documented release gate whenever rules change.

### P2: web automated test coverage is absent

Web lint/build validation exists, but consent, SPA routes, responsive behavior, accessibility, SEO tags, and live leaderboard behavior have no automated browser tests.

### P2: Firebase utility tests are configured but absent

`packages/firebase-utils` has a Vitest script but no `*.test.*` or `*.spec.*` files. The package builds, lints, and type-checks, while `npm test -- --run` exits 1 because no tests are found.

### P2: Android delivery is untested in CI

Android configuration/signing source exists, but no active build or publishing job prevents regression detection.

### P2: legacy Flutter web surface contains placeholders

`WebsiteScreen` is not the deployed site but is selected when the Flutter app runs on web. It contains placeholder store URLs and feedback behavior. Remove the target, redirect it, or bring it into alignment to avoid accidental exposure.

### P3: root orchestration assumes optional private source

`build:functions`, `test:functions`, and `deploy:all` fail without `packages/functions`. Add a preflight message or move those commands into a companion-repo-aware script.

### P3: dependency/build artifacts add repository weight

Tracked generated output and a large Git history increase clone size. Ignored local build/Pods/node_modules artifacts consume several gigabytes but are recoverable. Keep generated/third-party content out of source audits and avoid committing more build output unless required.

## Documentation findings addressed

- Replaced retired 4x4 gameplay descriptions with current falling-mode rules.
- Documented the private Functions boundary.
- Corrected Flutter/Node/React/Vite/Tailwind versions.
- Corrected package paths and active workflow names.
- Updated store metadata for the current game.
- Rebuilt the documentation index and classified legacy planning material.
- Corrected exact-case and missing internal links where practical.
- Marked external App Store/Firebase/analytics state as requiring dated verification.

## Recommended next engineering work

1. Align falling gameplay with leaderboard UI/submission or remove unsupported claims.
2. Add a rules deployment/test job.
3. Decide whether to archive or reintroduce legacy board mode.
4. Add Playwright coverage for public web routes, consent, metadata, and leaderboard states.
5. Add unit tests for `packages/firebase-utils` and promote them into CI.
6. Add Android analyze/build validation.
7. Establish contract tests shared with the private Functions repo.
8. Remove or redirect the Flutter `WebsiteScreen`.
