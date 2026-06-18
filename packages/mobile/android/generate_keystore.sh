#!/bin/bash

# Android Keystore Generation Script for Modulo Squares
# This script generates a keystore for Android app signing

set -e

echo "🔐 Android Keystore Generation for Modulo Squares"
echo "================================================"

KEYSTORE_FILE="upload-keystore.jks"
KEY_ALIAS="upload"
KEYSTORE_PASSWORD=""
KEY_PASSWORD=""

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  Keystore file '$KEYSTORE_FILE' already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Keystore generation cancelled."
        exit 1
    fi
fi

# Generate keystore password
if [ -z "$KEYSTORE_PASSWORD" ]; then
    KEYSTORE_PASSWORD=$(openssl rand -base64 12)
    echo "🔑 Generated keystore password: $KEYSTORE_PASSWORD"
fi

# Generate key password
if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD=$(openssl rand -base64 12)
    echo "🔑 Generated key password: $KEY_PASSWORD"
fi

echo "📝 Generating keystore..."
echo "Keytool command:"
echo "keytool -genkeypair \\"
echo "  -alias $KEY_ALIAS \\"
echo "  -keyalg RSA \\"
echo "  -keysize 2048 \\"
echo "  -validity 9125 \\"
echo "  -keystore $KEYSTORE_FILE \\"
echo "  -storepass [HIDDEN] \\"
echo "  -keypass [HIDDEN] \\"
echo "  -dname 'CN=Modulo Squares, OU=Development, O=Nelson Grey, L=City, ST=State, C=US'"
echo ""

# Generate the keystore
keytool -genkeypair \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 9125 \
  -keystore "$KEYSTORE_FILE" \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=Modulo Squares, OU=Development, O=Nelson Grey, L=City, ST=State, C=US"

echo ""
echo "✅ Keystore generated successfully!"
echo ""
echo "🔒 Keystore Details:"
echo "- File: $KEYSTORE_FILE"
echo "- Alias: $KEY_ALIAS"
echo "- Keystore Password: $KEYSTORE_PASSWORD"
echo "- Key Password: $KEY_PASSWORD"
echo ""
echo "📋 Next Steps:"
echo "1. Move keystore to a secure location (outside version control)"
echo "2. Update local.properties or set environment variables:"
echo "   storeFile=$KEYSTORE_FILE"
echo "   storePassword=$KEYSTORE_PASSWORD"
echo "   keyAlias=$KEY_ALIAS"
echo "   keyPassword=$KEY_PASSWORD"
echo ""
echo "3. For CI/CD, encode keystore as base64:"
echo "   base64 -i $KEYSTORE_FILE"
echo ""
echo "4. Set these secrets in your CI/CD system:"
echo "   - ANDROID_KEYSTORE: <base64 encoded keystore>"
echo "   - ANDROID_KEYSTORE_PASSWORD: $KEYSTORE_PASSWORD"
echo "   - ANDROID_KEY_ALIAS: $KEY_ALIAS"
echo "   - ANDROID_KEY_PASSWORD: $KEY_PASSWORD"
echo ""
echo "5. Test the build:"
echo "   flutter build appbundle --release"
echo ""
echo "⚠️  IMPORTANT: Keep the keystore and passwords secure!"
echo "   Never commit the keystore file to version control."