# Android Release Signing Configuration

> **Phase 2 reference (reviewed 2026-07-20):** Android source/signing support exists, but the active CI pipeline does not build or publish Android. Follow [Release Checklist](Release_Checklist.md) when Android delivery is activated.

## Creating a Keystore

### Option 1: Using Android Studio
1. Open Android Studio
2. Go to Build → Generate Signed Bundle/APK
3. Select APK or Bundle
4. Click "Create new..."
5. Fill in keystore details:
   - **Key store path**: `android/app/modulo_keystore.jks`
   - **Password**: Choose a strong password
   - **Key alias**: `modulo_key`
   - **Key password**: Same as keystore password (or different)
   - **Validity**: 25 years
   - **Certificate**: Fill in your details

### Option 2: Using Command Line
```bash
keytool -genkey -v -keystore android/app/modulo_keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias modulo_key
```

## Configuration Files

### 1. Local Properties (DO NOT COMMIT)
Create/update `android/local.properties`:
```
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=modulo_key
storeFile=modulo_keystore.jks
```

### 2. Build Configuration
The `android/app/build.gradle.kts` is already configured to use signing properties.

## Security Notes

- **Never commit** the keystore file or `local.properties` to version control
- Add these files to `.gitignore`:
  ```
  android/app/*.jks
  android/local.properties
  ```
- Store keystore passwords securely (consider using environment variables for CI/CD)
- Keep backup copies of your keystore in a secure location

## Testing Release Build

```bash
# Build release APK
flutter build apk --release

# Build app bundle (recommended for Play Store)
flutter build appbundle --release
```

## Play Store Upload

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new release
3. Upload the generated `.aab` file from `build/app/outputs/bundle/release/`
4. Fill in release notes and submit

## Troubleshooting

- **Build fails**: Check that `local.properties` exists and contains correct passwords
- **Upload fails**: Ensure you're using the same keystore used for previous releases
- **Lost keystore**: Contact Google Play support if you lose your signing key
