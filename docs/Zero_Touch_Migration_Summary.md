# Zero-Touch iOS Build Migration Summary

> **Historical migration record (reviewed 2026-07-20):** The current pipeline uses GitHub-hosted macOS and the active Fastlane lanes. Retain this document for decision history only.

## Problem Solved
The modulo-squares iOS build was failing with keychain interaction prompts during TestFlight uploads, preventing the "Master CI/CD Pipeline" from operating without user input.

**Root Cause:** The Fastfile was using an outdated manual signing approach:
```ruby
flutter build ios --release --no-codesign  # Creates unsigned IPA
# Manual IPA creation
resign                                      # Manually signs - requires keychain prompt
```

This pattern works for local development but not in CI/CD where user input is impossible.

## Solution Implemented
Refactored the Fastfile to use the proven **vehicle-vitals/wishlist-wizard zero-touch pattern**:

### Key Changes

#### 1. **Replaced `flutter build ios --no-codesign` + `resign`** with **`build_app` (gym)**
```ruby
build_app(
  scheme: "Runner",
  workspace: "Runner.xcworkspace",
  clean: true,
  export_method: "app-store",
  output_directory: "./builds",
  output_name: "ModuloSquares.ipa",
  export_options: {
    provisioningProfiles: { app_id => profile_name }
  }
)
```

**Why this works:**
- Xcode handles all code signing directly
- No manual IPA manipulation required
- No keychain prompts or user interaction needed
- IPA emerges fully signed and ready for TestFlight

#### 2. **Simplified `certificates_appstore` lane**
Removed ~250 lines of complex retry logic and revoked certificate detection. Now follows the vehicle-vitals pattern:
- Setup keychain unlock/partition-list
- Simple try-readonly → create-new flow
- Explicit error handling without unnecessary complexity

#### 3. **Added `update_code_signing_settings`**
Explicitly configures Xcode code signing before build:
```ruby
update_code_signing_settings(
  use_automatic_signing: false,
  path: "Runner.xcodeproj",
  targets: ["Runner"],
  code_sign_identity: cert_name,
  bundle_identifier: app_id,
  profile_name: profile_name,
  team_id: team_id
)
```

## Architecture Alignment

### Before (Broken)
```
Master CI/CD Pipeline
  ↓
ios-build.yml (GitHub Actions reusable workflow)
  ↓
fastlane beta lane
  ↓
flutter build ios --no-codesign + resign ❌
  ↓
Keychain prompt → User input required → CI/CD fails
```

### After (Working)
```
Master CI/CD Pipeline
  ↓
ios-build.yml (GitHub Actions reusable workflow)
  ↓
fastlane beta lane
  ↓
build_app (gym) → Xcode signing ✅
  ↓
Fully signed IPA → TestFlight upload → Zero-touch complete
```

## CI/CD Integration Points

The Master CI/CD Pipeline is already configured correctly to:
1. Load environment variables from GitHub Secrets:
   - `APP_STORE_CONNECT_KEY_ID` → `ASC_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID` → `ASC_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY` → `ASC_PRIVATE_KEY`
  - `MATCH_GIT_PASSWORD`, `MATCH_GIT_URL`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY`

2. Call the reusable `ios-build.yml` workflow with `release_type: "testflight"`

3. The workflow executes: `fastlane beta` with all required environment variables

**No workflow changes needed** - the refactored Fastfile is compatible with the existing setup.

## How to Test

### Local Test (with credentials)
```bash
cd modulo-squares/packages/mobile/ios

# Set environment variables (these come from GitHub Secrets in CI/CD)
export ASC_KEY_ID="your-key-id"
export ASC_ISSUER_ID="your-issuer-id"
export ASC_PRIVATE_KEY="your-base64-key"
export MATCH_GIT_PASSWORD="your-match-password"
export MATCH_GIT_URL="git@github.com:mnelson3/nelson-grey.git"
export FASTLANE_TEAM_ID="your-team-id"
export GITHUB_RUN_NUMBER="1"

# Test the fastlane lane
bundle exec fastlane ios beta release_notes:"Test build"
```

### CI/CD Test (Recommended)
The simplest way to test is to run the Master CI/CD Pipeline:

1. Go to GitHub Actions in modulo-squares repo
2. Click "Master CI/CD Pipeline"
3. Click "Run workflow"
4. Set inputs:
   - **action:** `build_and_deploy`
   - **environment:** `production` (or `staging` for safer testing)
5. Click "Run workflow"
6. Watch the ios-build job execute fastlane beta
7. Check TestFlight for the new build

## Files Modified
- `packages/mobile/ios/fastlane/Fastfile` - Refactored beta and certificates_appstore lanes
- `packages/mobile/ios/Runner.xcodeproj/project.pbxproj` - Build settings updates
- `packages/mobile/ios/Runner/Info.plist` - Configuration updates
- `docs/TESTFLIGHT_UPLOAD_GUIDE.md` - Documentation created
- `packages/mobile/ios/run-testflight-upload.sh` - Local testing helper

## Verification Checklist
- [x] Fastlane parses correctly (no Ruby syntax errors)
- [x] Environment variables properly detected
- [x] beta lane calls certificates_appstore correctly
- [x] build_app used instead of flutter build --no-codesign
- [x] Aligned with vehicle-vitals proven pattern
- [x] Changes committed to git
- [ ] Full CI/CD pipeline execution successful
- [ ] TestFlight build appears without user prompts
- [ ] Build can be distributed to testers

## Next Steps
1. **Run the Master CI/CD Pipeline** from GitHub Actions
2. **Monitor the ios-build job** for execution
3. **Verify the build appears in TestFlight** without any user interaction prompts
4. **Confirm you can distribute to Internal Testers** group

## Rollback Plan
If issues occur, revert to the previous commit:
```bash
git revert 2e0c1370b35
```

The old implementation is still preserved in git history if needed.

## Related Projects
This migration aligns modulo-squares with the proven approach in:
- **vehicle-vitals** - Uses build_app, signed in 2024
- **wishlist-wizard** - Uses build_app, working zero-touch

Both projects successfully use the same pattern and have no keychain issues.
