#!/bin/bash

# ZERO-TOUCH API Key Health Check and Rotation Assistant
# Detects expired App Store Connect API keys and assists with rotation

set -e

# App Store Connect env vars
APP_STORE_CONNECT_KEY_ID="${APP_STORE_CONNECT_KEY_ID}"
APP_STORE_CONNECT_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID}"
APP_STORE_CONNECT_KEY="${APP_STORE_CONNECT_KEY}"

echo "🔍 ZERO-TOUCH: API Key Health Check"
echo "==================================="
echo ""

# Check if required environment variables are set
check_env_vars() {
    local missing_vars=()

    if [ -z "$APP_STORE_CONNECT_KEY_ID" ]; then missing_vars+=("APP_STORE_CONNECT_KEY_ID"); fi
    if [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then missing_vars+=("APP_STORE_CONNECT_ISSUER_ID"); fi
    if [ -z "$APP_STORE_CONNECT_KEY" ]; then missing_vars+=("APP_STORE_CONNECT_KEY"); fi

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "❌ Missing required environment variables:"
        printf '   • %s\n' "${missing_vars[@]}"
        echo ""
        echo "💡 Set these in your .env file or CI/CD secrets"
        return 1
    fi

    echo "✅ All required environment variables are set"
    return 0
}

# Test API key validity by making a simple API call
test_api_key() {
    echo "🔐 Testing App Store Connect API key validity..."

    # Decode the private key
    local private_key_content="$APP_STORE_CONNECT_KEY"
    # Trim any whitespace/newlines from the secret
    private_key_content=$(echo "$private_key_content" | tr -d ' \t\n\r')

    # Create a temporary key file
    local key_file=$(mktemp)
    echo "$private_key_content" | base64 -d > "$key_file" 2>/dev/null || {
        echo "❌ Failed to decode private key - invalid base64"
        rm -f "$key_file"
        return 1
    }

    # Verify the key file was created and has content
    if [ ! -s "$key_file" ]; then
        echo "❌ Private key file is empty after decoding"
        rm -f "$key_file"
        return 1
    fi

    echo "✅ Private key decoded successfully"

    # Generate JWT token
    local jwt_token
    jwt_token=$(generate_jwt "$APP_STORE_CONNECT_KEY_ID" "$APP_STORE_CONNECT_ISSUER_ID" "$key_file") || {
        echo "❌ Failed to generate JWT token"
        rm -f "$key_file"
        return 1
    }

    echo "✅ JWT token generated successfully"

    # Test the API key with a simple call (list apps)
    local response
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer $jwt_token" \
        -H "Accept: application/json" \
        "https://api.appstoreconnect.apple.com/v1/apps" 2>/dev/null) || response="000"

    rm -f "$key_file"

    echo "📡 API Response Code: $response"

    case $response in
        200)
            echo "✅ API key is valid and working"
            return 0
            ;;
        401)
            echo "❌ API key authentication failed (expired or invalid)"
            return 1
            ;;
        403)
            echo "⚠️ API key lacks required permissions"
            return 1
            ;;
        *)
            echo "❓ Unexpected API response: $response"
            return 1
            ;;
    esac
}

# Generate JWT token for API authentication
generate_jwt() {
    local key_id="$1"
    local issuer_id="$2"
    local key_file="$3"

    echo "🔧 Generating JWT token..."

    # Verify key file exists and is readable
    if [ ! -f "$key_file" ]; then
        # Try to use the local .p8 file if available
        local local_key_file="/Users/marknelson/Circus/Repositories/modulo-squares/.act-secrets/AuthKey_${key_id}.p8"
        if [ -f "$local_key_file" ]; then
            key_file="$local_key_file"
        else
            echo "❌ Key file does not exist: $key_file"
            return 1
        fi
    fi

    # Create JWT header
    local header=$(echo -n '{"alg":"ES256","kid":"'"$key_id"'","typ":"JWT"}' | (base64 -w 0 2>/dev/null || base64 | tr -d '\n') | tr '+/' '-_' | tr -d '=')
    if [ -z "$header" ]; then
        echo "❌ Failed to create JWT header"
        return 1
    fi

    # Create JWT payload
    local now=$(date +%s)
    local exp=$((now + 1200))  # 20 minutes from now
    local payload=$(echo -n '{"iss":"'"$issuer_id"'","iat":'"$now"',"exp":'"$exp"',"aud":"appstoreconnect-v1"}' | (base64 -w 0 2>/dev/null || base64 | tr -d '\n') | tr '+/' '-_' | tr -d '=')
    if [ -z "$payload" ]; then
        echo "❌ Failed to create JWT payload"
        return 1
    fi

    # Create signature (ES256 requires raw r+s, not DER)
    local data="$header.$payload"
    local temp_der=$(mktemp)
    echo -n "$data" | openssl dgst -sha256 -sign "$key_file" -binary > "$temp_der" 2>/dev/null
    if [ ! -s "$temp_der" ]; then
        echo "❌ Failed to create DER signature"
        rm -f "$temp_der"
        return 1
    fi
    if [ ! -s "$temp_der" ]; then
        echo "❌ Failed to create JWT signature (DER)"
        rm -f "$temp_der"
        return 1
    fi
    local signature=$(openssl asn1parse -inform DER -in "$temp_der" 2>/dev/null | grep INTEGER | tail -2 | cut -d: -f4 | xxd -r -p | (base64 -w 0 2>/dev/null || base64 | tr -d '\n') | tr '+/' '-_' | tr -d '=' 2>/dev/null)
    rm -f "$temp_der"
    if [ -z "$signature" ]; then
        echo "❌ Failed to extract signature from DER"
        return 1
    fi

    printf "%s" "$data.$signature"
}

# Check if API key is approaching expiration (if we can determine creation date)
check_key_age() {
    echo "📅 Checking API key age..."

    # Try to extract creation date from key ID or other metadata
    # This is a best-effort check since Apple doesn't expose creation dates via API

    local key_id="$APP_STORE_CONNECT_KEY_ID"
    if [[ $key_id =~ ^[A-Z0-9]{10}_[A-Z0-9]{10}_[A-Z0-9]{2}$ ]]; then
        echo "📋 Key ID format suggests this is a valid App Store Connect key"
        echo "⚠️  App Store Connect API keys expire 1 year after creation"
        echo "🔄 Consider proactive rotation before expiration"
    else
        echo "⚠️  Key ID format doesn't match expected pattern"
    fi
}

# Generate rotation instructions
generate_rotation_guide() {
    echo ""
    echo "🔄 API KEY ROTATION REQUIRED"
    echo "=============================="
    echo ""
    echo "📋 Step-by-step rotation process:"
    echo ""
    echo "1. 🌐 Go to: https://appstoreconnect.apple.com/access/api"
    echo "2. 🔑 Click 'Keys' tab → '+' to create new key"
    echo "3. 📝 Name: 'GitHub Actions CI $(date +%Y-%m-%d)'"
    echo "4. ✅ Access: Select 'Developer' role (for certificate management)"
    echo "5. 💾 Download .p8 file and copy Key ID + Issuer ID"
    echo ""
    echo "6. 🔧 Convert to base64:"
    echo "   cat AuthKey_XXXXX.p8 | base64 | tr -d '\n'"
    echo ""
    echo "7. 🔒 Update GitHub secrets:"
    echo "   • APP_STORE_CONNECT_KEY_ID = [new Key ID]"
    echo "   • APP_STORE_CONNECT_ISSUER_ID = [new Issuer ID]"
    echo "   • APP_STORE_CONNECT_KEY = [base64 content]"
    echo ""
    echo "8. 🗑️  Delete old key from App Store Connect"
    echo ""
    echo "9. ✅ Test: Run this script again to verify"
}

# Main execution
main() {
    echo "🤖 ZERO-TOUCH API Key Management System"
    echo "========================================"

    if ! check_env_vars; then
        exit 1
    fi

    echo ""

    if test_api_key; then
        echo ""
        check_key_age
        echo ""
        echo "🎉 ZERO-TOUCH: API key is healthy and operational"
        echo "💡 System will continue automated certificate management"
        exit 0
    else
        echo ""
        echo "🚨 ZERO-TOUCH ALERT: API key requires rotation"
        generate_rotation_guide
        echo ""
        echo "📞 After rotation, the system will automatically resume ZERO-TOUCH operations"
        exit 1
    fi
}

# Run main function
main