# Public Repository Hardening Guide

> **Current control guide (reviewed 2026-07-20):** Functions business logic now lives in the private companion repository. Console-side API restrictions, App Check, secrets, and branch rules still require periodic verification.

This repository is public for operational reasons. The controls below reduce IP and abuse risk.

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
