# Modulo Squares Documentation Index

**Updated**: 2026-07-20

This index separates current implementation documentation from operational references, product plans, and historical records. The distinction matters because the repository retains older game-mode code and several pre-launch automation proposals.

## Start here

| Document | Use it for | Status |
|---|---|---|
| [Project README](../README.md) | Setup, repository layout, commands, and delivery overview | Current |
| [Current State](Current_State.md) | Audited implementation and release snapshot | Current |
| [Go-Live Runbook](GO_LIVE_RUNBOOK.md) | App Store/Firebase release gates and review history | Current; external items require console verification |
| [Game Mechanics](Game_Mechanics.md) | Active falling-mode rules and legacy-mode boundary | Current |
| [System Architecture](System_Architecture.md) | Runtime components and trust boundaries | Current |
| [Developer Guide](Developer_Guide.md) | Day-to-day engineering workflow | Current |
| [Testing](Testing.md) | Test layout and validation commands | Current |

## Current engineering references

| Document | Scope |
|---|---|
| [API Documentation](Api_Documentation.md) | Callable Function contracts used by the public client |
| [Database Schema](Database_Schema.md) | Firestore collections, ownership, and indexes |
| [Flutter Architecture](Flutter_Architecture.md) | Mobile package structure; includes legacy implementation details |
| [Web Frontend Architecture](Web_Frontend_Architecture.md) | React routes, Firebase reads, consent, SEO, and hosting |
| [CI/CD Setup](Ci_Cd_Setup.md) | Active GitHub Actions workflow |
| [Environment Setup](Environment_Setup.md) | Toolchain and local configuration |
| [Security](Security.md) | Security principles and operational checks |
| [Analytics](Analytics.md) | Mobile event taxonomy and measurement plan |
| [AdMob Setup](Admob_Setup.md) | Mobile ad configuration and consent |
| [Mobile Config Setup](Mobile_Config_Setup.md) | Environment-specific native Firebase switching |
| [Public Repo Hardening](PUBLIC_REPO_HARDENING.md) | Public/private source boundary and abuse controls |
| [Solution Hardening Matrix](SOLUTION_HARDENING_MATRIX.md) | Current hardening snapshot |
| [Code Quality Analysis](Code_Quality_Analysis.md) | Current audit findings and validation results |
| [Implementation Summary](Implementation_Summary.md) | Current implementation and risk summary |

## Release and platform operations

The go-live runbook is authoritative when it conflicts with these narrower references.

| Document | Scope |
|---|---|
| [Release Checklist](Release_Checklist.md) | Repeatable release checklist |
| [TestFlight Readiness](Testflight_Readiness_Checklist.md) | iOS beta preparation reference |
| [TestFlight Upload](Testflight_Upload_Guide.md) | Fastlane/manual upload commands |
| [iOS Signing](Ios_Signing.md) | Local and CI signing model |
| [iOS Certificate Setup](Ios_Certificate_Setup.md) | Certificate provisioning |
| [iOS Certificate Quick Reference](Ios_Certificate_Quick_Reference.md) | Common certificate commands |
| [iOS CI/CD Integration](Ios_Cicd_Integration_Guide.md) | Fastlane workflow details |
| [iOS Documentation Index](Ios_Documentation_Index.md) | iOS-specific navigation |
| [Android Signing](Android_Signing.md) | Android keystore reference; Android CI is disabled |
| [Store Assets](Store_Assets.md) | Store metadata and screenshot locations |
| [GitHub Secrets](Github_Secrets.md) | Secret names and setup |
| [Branch Protection](Branch_Protection.md) | Branch rule guidance |

## Product and marketing documents

These documents express requirements, targets, or plans. A checked item does not override live code or the go-live runbook.

| Document | Scope |
|---|---|
| [Business Requirements](Business_Requirements.md) | Business goals and launch assumptions |
| [Requirements](Requirements.md) | Product and technical requirements |
| [Product Design](Product_Design.md) | UX/product design history and targets |
| [iOS Gameplay Refocus Plan](Ios_Gameplay_Refocus_Plan.md) | Plan that led to falling-mode gameplay |
| [Social Media Strategy](Social_Media_Strategy.md) | Organic channel strategy |
| [Social Media Execution Plan](Social_Media_Execution_Plan.md) | Launch content/checklist |
| [Performance and Scalability](Performance_Scalability.md) | Capacity recommendations and future controls |

## Historical audits and legacy automation

These are retained for decision history. Commands, filenames, statuses, and architecture examples may be obsolete.

| Document | Why retained |
|---|---|
| [Quick Reference](Quick_Reference.md) | Companion to the earlier quality audit |
| [Test Cleanup Guide](Test_Cleanup_Guide.md) | Earlier test-remediation guidance |
| [Automation README](Automation_Readme.md) | Legacy broad automation system |
| [Zero-Touch README](Zero_Touch_Readme.md) | Legacy zero-touch design |
| [Zero-Touch Setup](Zero_Touch_Setup.md) | Legacy setup workflow |
| [Zero-Touch Implementation Guide](Zero_Touch_Devops_Implementation_Guide.md) | Legacy templates |
| [Zero-Touch Quick Reference](Zero_Touch_Devops_Quick_Reference.md) | Legacy commands |
| [Zero-Touch Migration Summary](Zero_Touch_Migration_Summary.md) | Migration history |
| [Self-Hosted Runners](Self_Hosted_Runners.md) | Historical normal-CI runner model; HADES remains optional |
| [macOS Runner Setup](Macos_Runner_Setup.md) | Optional HADES/local runner reference |
| [Cost-Effective CI/CD](Cost_Effective_Cicd.md) | Historical cost strategy |
| [CI/CD Workstreams](Cicd_Workstreams.md) | Historical workstream tracking |
| [Act Testing Guide](Act_Testing_Guide.md) | Local Actions emulation reference |
| [Docker Auth Setup](Docker_Auth_Setup.md) | Runner/container tooling; not application delivery |
| [Firebase-First Standard](Firebase_First_Standard.md) | Cross-project design standard, not current repo topology |
| [Backend Services Guide](Backend_Services_Guide.md) | Broad Firebase examples; private Functions repo is authoritative |

## Other repository documentation

- [Workspace](Workspace.md): compact directory map.
- [Mobile package README](../packages/mobile/README.md): mobile-specific commands.
- [Web package README](../packages/web/README.md): website-specific commands.
- [Firebase utilities README](../packages/firebase-utils/README.md): shared utility API.
- [Shared package README](../packages/shared/README.md): reserved package status.
- [Icons README](../icons/README.md): brand asset source-of-truth and archive.
- [Shared iOS setup README](../shared-ios-setup/README.md): reusable Fastlane reference.

## Documentation rules

- Use exact filename casing in links; GitHub is case-sensitive.
- Use repository-relative paths and name the authoritative code/config file.
- Label console-derived status with a verification date.
- Treat `.github/workflows/ci-cd.yml` as the active pipeline and `.github/workflows/archive/` as history.
- Treat `packages/functions` as an optional private checkout, not tracked public source.
- Update `Current_State.md` and `GO_LIVE_RUNBOOK.md` whenever gameplay, release, or deployment state changes.
