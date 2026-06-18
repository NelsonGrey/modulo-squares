# Solution Hardening Matrix

This matrix tracks hardening controls across all major solution dimensions.

## Branches

| Control | develop | staging | main |
|---|---|---|---|
| Branch protection enabled | Yes | Yes | Yes |
| PR required for merge | Yes | Yes | Yes |
| Required approvals >= 1 | Yes | Yes | Yes |
| Require Code Owner review | Yes | Yes | Yes |
| Enforce admins | Yes | Yes | Yes |
| Block force push | Yes | Yes | Yes |
| Block branch deletion | Yes | Yes | Yes |
| Require conversation resolution | Yes | Yes | Yes |
| Require linear history | Yes | Yes | Yes |

## Web (Firebase Hosting)

| Control | dev | staging | prod |
|---|---|---|---|
| X-Content-Type-Options: nosniff | Yes | Yes | Yes |
| X-Frame-Options: DENY | Yes | Yes | Yes |
| Referrer-Policy configured | Yes | Yes | Yes |
| Permissions-Policy configured | Yes | Yes | Yes |
| HSTS configured | Yes | Yes | Yes |
| HTML no-cache headers set | Yes | Yes | Yes |

## Mobile: Android

| Control | Status |
|---|---|
| Internet/network-state permissions explicit | Yes |
| AD_ID permission explicit | Yes |
| android:allowBackup=false | Yes |
| android:fullBackupContent=false | Yes |
| android:usesCleartextTraffic=false | Yes |

## Mobile: iOS

| Control | Status |
|---|---|
| ATS explicit (NSAllowsArbitraryLoads=false) | Yes |
| App Tracking usage description present | Yes |
| Local network usage description present | Yes |

## Repository and CI/CD

| Control | Status |
|---|---|
| Proprietary LICENSE (all rights reserved) | Yes |
| CODEOWNERS file present | Yes |
| Actions policy restricted to selected/verified/owner allowlist | Yes |
| Default workflow token permissions read-only | Yes |
| Auto-delete branch on merge | Yes |

## Remaining Manual/External Controls

These controls are not fully enforceable from repository code alone and should be verified in provider consoles:

1. Google API key restrictions by app package/bundle and API allowlist.
2. Firebase App Check enforcement for all production clients.
3. Apple/Google signing credential lifecycle and periodic rotation.
4. GitHub forking disabled (if available for account plan/repo settings).
5. Optional: required status checks list pinning for protected branches.

## Review Cadence

1. Weekly: review Dependabot, secret scanning, and code scanning.
2. Monthly: re-validate branch protections and Actions policy.
3. Per release: verify this matrix and update any status changes.
