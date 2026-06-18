# TestFlight Upload Guide (Non-Interactive Signing)

This project now uploads to TestFlight using:
- Automatic signing
- App Store Connect API key authentication
- No direct credential-prompt setup scripts

## Required Variables

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY`
- `FASTLANE_TEAM_ID`
- `MATCH_GIT_URL` (if still used for shared signing metadata)
- `MATCH_GIT_URL_TOKEN` (if still needed by your environment)

## Local Upload

```bash
cd packages/mobile/ios
bash run-testflight-upload.sh
```

Or via helper script:

```bash
./scripts/ios-local-dev.sh beta
```

## CI Upload

Run the `Master CI/CD Pipeline` workflow with:
- `action: build_and_deploy`
- `environment: production`

## Troubleshooting

- Verify all App Store Connect API variables are present and valid.
- Confirm `FASTLANE_TEAM_ID` matches your Apple Developer Team.
- Re-run `./scripts/ios-local-dev.sh sync` to validate signing configuration.
