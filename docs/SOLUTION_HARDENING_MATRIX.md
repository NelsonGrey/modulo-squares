# Solution Hardening Matrix

**Updated**: 2026-07-20

| Area | Repository state | Remaining verification/action |
|---|---|---|
| Branch synchronization | `develop` matches `origin/develop` at audit time | Refresh stale local `main`/`staging` before using them |
| Branch protection | CODEOWNERS and guidance tracked | Verify live GitHub rulesets/environments |
| Secret handling | secrets ignored; CI uses secrets/environments | Audit live secrets and least privilege |
| Public/private boundary | Functions source moved to private companion repo | Contract-test and audit companion repo |
| Firestore rules | deny-by-default with owner/server boundaries | Add automated tests/deployment gate |
| Authentication | Apple/Google/email paths; Apple nonce/entitlement | Real-device provider and collision testing |
| Account deletion | UI and callable integration present | Verify deletion across every current collection |
| Score integrity | server-authoritative callable submissions and session token | Verify anti-replay/rate limits in private server |
| Leaderboard product path | services/screens/web reads exist | Wire falling runs to submission/navigation or remove unsupported claims |
| Purchase integrity | server validation and entitlements | Sandbox/TestFlight receipt and restore testing |
| App Check | client integration present | Enable/verify enforcement in Firebase console |
| API keys | client identifiers tracked as expected | Apply bundle/API/quota restrictions in console |
| Mobile consent | ATT + UMP service | Validate regional/device behavior |
| Web consent | default-denied GTM/AdSense flow | Browser automation and tag validation |
| Mobile CI | analyze/test and iOS TestFlight | Add Android job; preserve iOS signing health |
| Web CI | TypeScript production build | Add lint and browser/accessibility tests to CI |
| Firebase utilities | lint/type-check/build pass | Add Vitest coverage; current test command finds no tests |
| Dependency security | Dependabot, auto-merge, CodeQL | Continue audits and review major upgrades manually |
| Documentation | reconciled to source on 2026-07-20 | Keep status dates and canonical docs current |
| App Store | corrected TestFlight build documented | Verify current review/public state in App Store Connect |
| Google Play | platform source exists | Create record and delivery pipeline when Phase 2 begins |

## Priority actions

1. Add Firestore rules validation/deployment to CI.
2. Verify App Store Connect status and update the go-live runbook.
3. Verify App Check/API-key restrictions and account-deletion coverage.
4. Add web browser tests and Android build validation.
5. Resolve the live-versus-legacy game code boundary.
