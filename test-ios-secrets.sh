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
    if security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/$IOS_PROVISIONING_PROFILE.mobileprovision | grep -q "com.modulosquares.app.ios"; then
        echo "✅ Profile contains correct bundle ID"
    else
        echo "❌ Profile does not contain correct bundle ID"
        echo "Expected: com.modulosquares.app.ios"
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

# Test certificate (keychainless)
test_certificate() {
    echo ""
    echo "🔐 Testing Distribution Certificate..."
    echo "--------------------------------------"

    # Decode certificate
    echo "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode > /tmp/test_cert.p12

    if openssl pkcs12 -in /tmp/test_cert.p12 -passin pass:"$IOS_CERTIFICATE_PASSWORD" -nokeys -clcerts >/tmp/test_cert_public.pem 2>/dev/null; then
        echo "✅ Certificate decrypted successfully"
    else
        echo "❌ Certificate validation failed"
        echo "This could be due to:"
        echo "  - Wrong password"
        echo "  - Corrupted certificate file"
        echo "  - Wrong certificate format"
        rm -f /tmp/test_cert.p12 /tmp/test_cert_public.pem
        return 1
    fi

    echo "📋 Certificate subject/issuer/details:"
    openssl x509 -in /tmp/test_cert_public.pem -noout -subject -issuer -dates || true

    if openssl x509 -in /tmp/test_cert_public.pem -noout -subject | grep -q "Apple Distribution"; then
        echo "✅ Found Apple Distribution certificate"
    else
        echo "❌ Expected an Apple Distribution certificate"
        rm -f /tmp/test_cert.p12 /tmp/test_cert_public.pem
        return 1
    fi

    rm -f /tmp/test_cert.p12
    rm -f /tmp/test_cert_public.pem
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