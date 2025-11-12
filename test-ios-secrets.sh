#!/bin/bash

# Test iOS Secrets Locally
# This script helps validate your iOS certificates and provisioning profiles

set -e

echo "🧪 Testing iOS Secrets Locally"
echo "================================"

# Check if required environment variables are set
check_env_vars() {
    local missing_vars=()

    if [ -z "$IOS_PROVISIONING_PROFILE_BASE64" ]; then
        missing_vars+=("IOS_PROVISIONING_PROFILE_BASE64")
    fi

    if [ -z "$IOS_PROVISIONING_PROFILE" ]; then
        missing_vars+=("IOS_PROVISIONING_PROFILE")
    fi

    if [ -z "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" ]; then
        missing_vars+=("IOS_DISTRIBUTION_CERTIFICATE_BASE64")
    fi

    if [ -z "$IOS_CERTIFICATE_PASSWORD" ]; then
        missing_vars+=("IOS_CERTIFICATE_PASSWORD")
    fi

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "❌ Missing environment variables:"
        printf '  - %s\n' "${missing_vars[@]}"
        echo ""
        echo "Set them using:"
        echo "export IOS_PROVISIONING_PROFILE_BASE64='your_base64_string'"
        echo "export IOS_PROVISIONING_PROFILE='your_profile_uuid'"
        echo "export IOS_DISTRIBUTION_CERTIFICATE_BASE64='your_cert_base64'"
        echo "export IOS_CERTIFICATE_PASSWORD='your_cert_password'"
        exit 1
    fi

    echo "✅ All required environment variables are set"
}

# Test provisioning profile
test_provisioning_profile() {
    echo ""
    echo "📱 Testing Provisioning Profile..."
    echo "-----------------------------------"

    # Create directory if it doesn't exist
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/

    # Decode and install profile
    echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/$IOS_PROVISIONING_PROFILE.mobileprovision

    if [ ! -f ~/Library/MobileDevice/Provisioning\ Profiles/$IOS_PROVISIONING_PROFILE.mobileprovision ]; then
        echo "❌ Failed to create provisioning profile file"
        return 1
    fi

    echo "✅ Provisioning profile file created"

    # Check profile contents
    echo "📋 Profile details:"
    security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/$IOS_PROVISIONING_PROFILE.mobileprovision | grep -E "(Name|UUID|TeamName|AppIDName|application-identifier)" || true

    # Check bundle ID
    if security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/$IOS_PROVISIONING_PROFILE.mobileprovision | grep -q "com.nelsongrey.modulosquares.app.ios"; then
        echo "✅ Profile contains correct bundle ID"
    else
        echo "❌ Profile does not contain correct bundle ID"
        echo "Expected: com.nelsongrey.modulosquares.app.ios"
        return 1
    fi

    # Check if it's a distribution profile
    if security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/$IOS_PROVISIONING_PROFILE.mobileprovision | grep -q "ProvisionedDevices"; then
        echo "⚠️  This appears to be a DEVELOPMENT profile (contains ProvisionedDevices)"
        echo "   For TestFlight, you need an APP STORE DISTRIBUTION profile"
    else
        echo "✅ This appears to be a DISTRIBUTION profile (no ProvisionedDevices)"
    fi
}

# Test certificate
test_certificate() {
    echo ""
    echo "🔐 Testing Distribution Certificate..."
    echo "--------------------------------------"

    # Create temporary keychain
    KEYCHAIN_PATH=$HOME/Library/Keychains/test.keychain
    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

    # Clean up any existing keychain
    security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true

    # Create and unlock keychain
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"

    # Decode certificate
    echo "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode > /tmp/test_cert.p12

    # Try to import
    if security import /tmp/test_cert.p12 -P "$IOS_CERTIFICATE_PASSWORD" -A -k "$KEYCHAIN_PATH" 2>/dev/null; then
        echo "✅ Certificate imported successfully"

        # Check identities
        echo "📋 Available identities:"
        security find-identity -v "$KEYCHAIN_PATH"

        if security find-identity -v "$KEYCHAIN_PATH" | grep -q "Apple Distribution"; then
            echo "✅ Found Apple Distribution certificate"
        else
            echo "❌ No Apple Distribution certificate found"
            echo "📋 Available identities in test keychain:"
            security find-identity -v "$KEYCHAIN_PATH" || true
            echo ""
            echo "💡 For TestFlight builds, you need an 'Apple Distribution' certificate"
            echo "   You currently have a different type of certificate."
            echo ""
            echo "Check your local certificates with:"
            echo "security find-identity -v -p codesigning"
            echo ""
            echo "If you only have 'Apple Development' certificates:"
            echo "1. Go to https://developer.apple.com/account/resources/certificates"
            echo "2. Click '+' → Choose 'Apple Distribution'"
            echo "3. Follow the instructions to create and download"
            echo "4. Install the certificate in Keychain Access"
            echo "5. Export as .p12 file with password"
            echo "6. Base64 encode: base64 -i YourCert.p12"
            echo "7. Update IOS_DISTRIBUTION_CERTIFICATE_BASE64 secret"
            security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
            rm -f /tmp/test_cert.p12
            return 1
        fi
    else
        echo "❌ Certificate import failed"
        echo "This could be due to:"
        echo "  - Wrong password"
        echo "  - Corrupted certificate file"
        echo "  - Wrong certificate format"
        echo ""
        echo "Try validating the certificate with:"
        echo "openssl pkcs12 -info -in /tmp/test_cert.p12 -nokeys"
        rm -f /tmp/test_cert.p12
        return 1
    fi

    # Clean up
    security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
    rm -f /tmp/test_cert.p12
}

# Main execution
main() {
    check_env_vars
    test_provisioning_profile
    test_certificate

    echo ""
    echo "🎉 All tests passed! Your iOS secrets appear to be configured correctly."
    echo ""
    echo "Next steps:"
    echo "1. Run the GitHub Actions test workflow: test-ios-secrets.yml"
    echo "2. If that passes, try a full iOS distribution build"
}

# Run main function
main "$@"