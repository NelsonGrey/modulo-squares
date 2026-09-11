# Public Repository Hardening Guide

> **Current control guide (reviewed 2026-09-11):** Functions business logic lives in the private companion repository. Console-side API restrictions, App Check, secrets, and branch rules still require periodic verification.

This repository is public for operational reasons. The controls below reduce IP and abuse risk, and the status table tracks where each control currently stands.

## Current hardening status

| Area | Repository state | Remaining verification/action |
|---|---|---|
| Branch synchronization | `develop` is the working branch; keep `main`/`staging` refreshed before using them | Refresh stale local `main`/`staging` before using them |
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
| Documentation | reconciled to source on 2026-09-11 | Keep status dates and canonical docs current |
| App Store | corrected TestFlight build documented | Verify current review/public state in App Store Connect |
| Google Play | platform source exists | Create record and delivery pipeline when Phase 2 begins |

### Priority actions

1. Add Firestore rules validation/deployment to CI.
2. Verify App Store Connect status and update the go-live runbook.
3. Verify App Check/API-key restrictions and account-deletion coverage.
4. Add web browser tests and Android build validation.
5. Resolve the live-versus-legacy game code boundary.

## 1) Legal and ownership controls

- Keep `LICENSE` as proprietary (all rights reserved).
- Keep `CODEOWNERS` mapped to the repository owner.
- Keep branch protection enabled on long-lived branches.
- Prefer pull-request-only merges and required reviews for protected branches.

## 2) Keep competitive advantage off-client

- Treat mobile/web app code as inspectable.
- Move proprietary game balancing, anti-abuse, pricing, and ranking logic to private backend services.
- Keep secret decision logic behind authenticated APIs.
- Return only minimum data needed by clients.

## 3) Secrets and credential handling

- Never commit private keys, service account keys, signing material, or long-lived tokens.
- Rotate credentials immediately if exposure is suspected.
- Restrict Firebase/Google API keys by app package/bundle IDs, API allowlists, and quotas.
- Keep production credentials in GitHub Actions secrets or external secret managers.

## 4) GitHub repository settings checklist

- Disable forking if available for your plan/repository settings.
- Restrict Actions to trusted/verified/owner allowlists.
- Keep default workflow token permissions at read-only.
- Enable Dependabot security updates.
- Enable secret scanning and push protection.

## 5) Data and asset minimization

- Do not publish internal roadmaps, launch plans, or unreleased monetization details unless intentionally public.
- Keep paid assets, proprietary models, and internal analytics schemas outside public source control.
- Keep sample data synthetic when possible.

## 6) Enforcement posture

- Use clear copyright notices in docs and release artifacts.
- Log notable external misuse for DMCA/trademark escalation.
- Use separate trademark guidance for product name/logo protection.

## 7) Ongoing operational cadence

- Weekly: review security alerts and dependency updates.
- Monthly: rotate non-user credentials and review API key restrictions.
- Per release: verify no sensitive files are added and branch protections remain enabled.
