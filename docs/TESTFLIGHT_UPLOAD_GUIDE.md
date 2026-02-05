# TestFlight Upload Guide for Modulo Squares iOS

## Current Status

✅ **Completed:**
- Environment variables configured in `.env.development`
- App Store Connect API credentials set up
- Fastlane tools installed (v2.229.1)
- Match certificate repository configured (nelson-grey)
- Build infrastructure prepared
- Upload script created and refined

⚠️ **In Progress:**
- Code signing certificate setup (experiencing keychain interaction issue)

## Keychain Issue & Solution

**Problem:** When fastlane attempts to import newly created certificates into the keychain, macOS shows an interactive prompt ("User canceled the operation") that cannot be handled in automated environments.

 **Why This Matters:**
- TestFlight upload requires code signing certificates
- Certificates must be imported into the system keychain
- Non-interactive environments can't handle the prompt

## Solution Options

### Option 1: Run Fastlane Interactively (Recommended for First Run)

Run the upload process in an interactive terminal where you can respond to prompts:

```bash
cd /Users/marknelson/Circus/Repositories/modulo-squares/packages/mobile/ios
bash /Users/marknelson/Circus/Repositories/modulo-squares/packages/mobile/ios/run-testflight-upload.sh
```

When prompted by macOS about allowing fastlane to access the keychain, **click "Always Allow"**.

**Expected Duration:** 15-30 minutes depending on internet connection

### Option 2: Pre-create Certificates Manually

1. **Go to Apple Developer Portal:**
   - https://developer.apple.com/account/resources/certificates

2. **Create Distribution Certificate:**
   - Click "+"
   - Select "Apple Distribution"
   - Follow the prompts to upload CSR (Certificate Signing Request)
   - Download the `.cer` file

3. **Create App ID:**
   - Go to Identifiers
   - Click "+"
   - Register as "App ID"
   - Bundle ID: `com.nelsongrey.modulosquares.app.ios`
   - Enable capabilities:
     - Push Notifications
     - In-App Purchases
     - Game Kit
     - Sign In with Apple

4. **Create Provisioning Profile:**
   - Go to Profiles
   - Click "+"
   - Select "App Store"
   - Select the modulo-squares App ID
   - Select the distribution certificate you created
   - Name it: "Match AppStore com.nelsongrey.modulosquares.app.ios"
   - Generate and download

5. **Add to Match Repository:**
   ```bash
   # In the nelson-grey repo, under secure/fastlane/
   # Add the certificate files to the appropriate Match directories
   ```

### Option 3: Use GitHub Actions (Recommended for CI/CD)

The master CI/CD pipeline is already configured in [/.github/workflows/master-pipeline.yml](/.github/workflows/master-pipeline.yml)

1. Go to: https://github.com/mnelson3/modulo-squares/actions
2. Click "Master CI/CD Pipeline"
3. Click "Run workflow"
4. Select:
   - **Action:** `build_and_deploy`
   - **Environment:** `production` (for TestFlight)
5. Click "Run workflow"

The GitHub Actions runner will handle all certificate and keychain management automatically.

## Required Environment Variables

All set in `.env.development`:

| Variable | Value | Status |
|----------|-------|--------|
| `FASTLANE_APPLE_ID` | mark.a.nelson@outlook.com | ✅ |
| `FASTLANE_TEAM_ID` | P6YJUBML6P | ✅ |
| `FASTLANE_ITC_TEAM_ID` | 1024280708 | ✅ |
| `APP_STORE_CONNECT_KEY_ID` | W2N7DYR6DU | ✅ |
| `APP_STORE_CONNECT_ISSUER_ID` | 0c24c11e-7780-4f95-9dab-7b59328f0315 | ✅ |
| `APP_STORE_CONNECT_KEY` | (base64 encoded .p8 key) | ✅ |
| `MATCH_GIT_URL` | git@github.com:mnelson3/nelson-grey.git | ✅ |
| `MATCH_GIT_URL_TOKEN` | (GitHub PAT) | ✅ |
| `BETA_FEEDBACK_EMAIL` | mark.a.nelson@outlook.com | ✅ |

## Fastlane Lanes Available

```bash
# Run from: packages/mobile/ios/

fastlane ios sync_signing                 # Sync certificates
fastlane ios certificates_development     # Setup development certs
fastlane ios certificates_appstore        # Setup distribution certs
fastlane ios zero_touch_certificates      # Full certificate lifecycle
fastlane ios beta                         # Build and upload to TestFlight
fastlane ios beta[release_notes:"v1.0"]   # With custom release notes
fastlane ios submit_to_app_store          # Submit to App Store
fastlane ios promote_to_app_store         # Promote from TestFlight to App Store
```

##Current App Version

- **Version:** 0.0.2
- **Build Number:** 2
- **Bundle ID:** com.nelsongrey.modulosquares.app.ios
- **Team:** P6YJUBML6P (Mark Nelson)

## Next Steps

1. **For Immediate Upload (Interactive):**
   ```bash
   cd packages/mobile/ios
   bash run-testflight-upload.sh
   # When prompted, click "Always Allow" in the keychain dialog
   ```

2. **Check TestFlight Status:**
   - Go to: https://app​storeconnect.apple.com
   - Select "Modulo Squares" app
   - Go to TestFlight tab
   - Builds will appear within 30 minutes

3. **Add Testers:**
   - TestFlight > Beta Groups
   - Create or select a group
   - Add email addresses of testers

## Troubleshooting

### "Permission denied (publickey)"
- Ensure SSH keys are configured: `ssh -T git@github.com`
- Or use HTTPS: The script automatically converts to HTTPS with PAT

### "User canceled the operation" (Keychain)
- Run in interactive terminal (don't use pipe/redirect)
- Click "Always Allow" when prompted
- Never use `nohup` or background execution for first certificate import

### "Could not find the newly generated certificate installed"
- Use Option 2: Pre-create certificates manually in Apple Developer Portal
- Or use Option 3: GitHub Actions for fully automated CI/CD

### Build takes longer than expected
- First-time build can take 15-30 minutes
- Subsequent builds will be faster if certificates cache

## References

- [Apple Developer Account](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Fastlane Documentation](https://docs.fastlane.tools)
- [Match Certificate Management](https://docs.fastlane.tools/actions/match/)
- [TestFlight Distribution](https://docs.fastlane.tools/actions/upload_to_testflight/)

