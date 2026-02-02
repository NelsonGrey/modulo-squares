# 🔒 Security Guidelines for Modulo Squares

## 🚨 CRITICAL SECURITY REQUIREMENTS

### Never Commit These Files
The following files **MUST NEVER** be committed to version control:

- `packages/mobile/ios/app_store_connect_key.p8` - App Store Connect API private key
- `packages/mobile/ios/*.p8` - Any .p8 private key files
- `packages/mobile/android/app/*.jks` - Android keystores
- `packages/mobile/android/app/*.keystore` - Android keystores
- `**/*service-account-key.json` - Firebase service account keys
- `packages/mobile/ios/certs/*.p12` - iOS certificates
- `packages/mobile/ios/certs/*.pem` - Certificate files

### Required GitHub Repository Secrets

#### App Store Connect (iOS)
- `APP_STORE_CONNECT_KEY_ID` - App Store Connect API Key ID
- `APP_STORE_CONNECT_ISSUER_ID` - App Store Connect API Issuer ID
- `APP_STORE_CONNECT_KEY` - Base64 encoded private key (.p8 file content)
- `FASTLANE_APPLE_ID` - Apple Developer email
- `FASTLANE_TEAM_ID` - Apple Developer Team ID
- `MATCH_PASSWORD` - Match repository password

#### Firebase
- `FIREBASE_TOKEN_DEVELOPMENT` - Firebase CI token for dev environment
- `FIREBASE_TOKEN_STAGING` - Firebase CI token for staging environment
- `FIREBASE_TOKEN_PRODUCTION` - Firebase CI token for prod environment

#### Android (Optional for signed releases)
- `ANDROID_KEYSTORE` - Base64 encoded Android keystore
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password

## 🔄 Security Incident Response

### If a Secret is Exposed:

1. **IMMEDIATELY** revoke the compromised credential
2. **ROTATE** to new credentials
3. **UPDATE** all GitHub secrets
4. **AUDIT** access logs for unauthorized activity
5. **NOTIFY** team members

### App Store Connect Key Compromise:
1. Delete the compromised API key in App Store Connect
2. Create new API key with minimal required permissions
3. Update `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_KEY` secrets
4. Test CI/CD pipeline with new credentials

### Firebase Token Compromise:
1. Revoke the compromised token
2. Generate new CI token: `firebase login:ci`
3. Update appropriate `FIREBASE_TOKEN_*` secret
4. Verify deployments still work

## 🛡️ Security Best Practices

### Development
- Use `.env` files for local development (never commit)
- Test with dummy/test credentials in development
- Use separate Firebase projects per environment

### CI/CD
- All secrets stored in GitHub repository secrets
- No hardcoded credentials in workflows
- Temporary files cleaned up after builds
- Use environment-specific service accounts

### Code Review
- Check for accidentally committed secrets in PRs
- Review `.gitignore` changes
- Verify secret usage in workflows

## 🚦 Security Checklist

### Before Committing:
- [ ] No `.p8`, `.jks`, or service account files committed
- [ ] No hardcoded API keys or tokens in code
- [ ] No secrets in `.env` files (use `.env.example` templates)

### Before Deploying:
- [ ] All required GitHub secrets are set
- [ ] Firebase tokens are valid and not expired
- [ ] App Store Connect API key has correct permissions
- [ ] Android keystore is properly configured (if used)

### After Security Incident:
- [ ] Compromised credentials revoked
- [ ] New credentials generated and tested
- [ ] Team notified of incident
- [ ] Security practices reviewed and improved

## 📞 Emergency Contacts

If you suspect a security breach:
1. Immediately notify repository administrator
2. Revoke potentially compromised credentials
3. Document the incident for post-mortem analysis

---

**Last Updated**: December 4, 2025
**Version**: 1.0.0