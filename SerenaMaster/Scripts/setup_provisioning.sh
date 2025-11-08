#!/bin/bash

# SerenaNet Provisioning Profile Setup Script
# This script helps set up code signing and provisioning profiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              SerenaNet Provisioning Setup                   ║"
echo "║                                                              ║"
echo "║  🔐 Configure code signing and provisioning profiles        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Configuration
BUNDLE_ID="com.serenatools.serenanet"
TEAM_ID=""
APPLE_ID=""
APP_NAME="SerenaNet"

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            input="$default"
        fi
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            echo -e "${RED}This field is required.${NC}"
            read -p "$prompt: " input
        done
    fi
    
    eval "$var_name='$input'"
}

echo -e "${BLUE}📋 Provisioning Profile Configuration${NC}"
echo "======================================"
echo ""

# Get user input
prompt_input "Enter your Apple Developer Team ID" "TEAM_ID"
prompt_input "Enter your Apple ID email" "APPLE_ID"
prompt_input "Enter your Developer Name (for certificates)" "DEVELOPER_NAME"

echo ""
echo -e "${YELLOW}🔍 Checking existing certificates...${NC}"

# List available certificates
echo -e "${BLUE}Available Developer ID Application certificates:${NC}"
security find-identity -v -p codesigning | grep "Developer ID Application" || echo "No Developer ID certificates found"

echo ""
echo -e "${BLUE}Available Mac App Store certificates:${NC}"
security find-identity -v -p codesigning | grep "Mac App Store" || echo "No Mac App Store certificates found"

echo ""
echo -e "${YELLOW}📝 Creating provisioning profile configuration...${NC}"

# Create entitlements file
mkdir -p Scripts
cat > "Scripts/SerenaNet.entitlements" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- File Access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- Hardware Access -->
    <key>com.apple.security.device.microphone</key>
    <true/>
    
    <!-- Network Access (disabled for privacy) -->
    <key>com.apple.security.network.client</key>
    <false/>
    <key>com.apple.security.network.server</key>
    <false/>
    
    <!-- Other Capabilities -->
    <key>com.apple.security.personal-information.speech-recognition</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <false/>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ Created entitlements file: Scripts/SerenaNet.entitlements${NC}"

# Update deployment configuration
cat > "deployment_config.json" << EOF
{
  "app": {
    "name": "SerenaNet",
    "bundle_id": "$BUNDLE_ID",
    "version": "1.0.0",
    "build_number": "1",
    "category": "Productivity",
    "minimum_os_version": "13.0",
    "supported_architectures": ["arm64", "x86_64"]
  },
  "signing": {
    "team_id": "$TEAM_ID",
    "developer_id": "Developer ID Application: $DEVELOPER_NAME ($TEAM_ID)",
    "app_store_certificate": "Mac App Store: $DEVELOPER_NAME ($TEAM_ID)",
    "provisioning_profile": "SerenaNet App Store",
    "entitlements": {
      "sandbox": true,
      "microphone": true,
      "speech_recognition": true,
      "file_access": "user_selected",
      "network_client": false,
      "network_server": false
    }
  },
  "distribution": {
    "methods": ["direct_dmg", "app_store", "testflight"],
    "dmg": {
      "volume_name": "SerenaNet",
      "window_size": [600, 400],
      "icon_size": 100,
      "background_image": null
    },
    "app_store": {
      "category": "Productivity",
      "price_tier": "Free",
      "availability": "worldwide",
      "age_rating": "4+"
    }
  },
  "notarization": {
    "apple_id": "$APPLE_ID",
    "team_id": "$TEAM_ID",
    "bundle_id": "$BUNDLE_ID",
    "primary_bundle_id": "$BUNDLE_ID"
  },
  "metadata": {
    "short_description": "Local AI assistant for privacy",
    "keywords": ["AI assistant", "local AI", "privacy", "offline AI", "voice input", "productivity"],
    "support_url": "https://serenatools.com/support",
    "privacy_policy_url": "https://serenatools.com/privacy",
    "terms_url": "https://serenatools.com/terms"
  },
  "build": {
    "configuration": "Release",
    "optimization": "speed",
    "strip_symbols": false,
    "include_debug_info": true,
    "enable_bitcode": false
  },
  "testing": {
    "testflight": {
      "internal_testers": 25,
      "external_testers": 100,
      "test_duration_days": 90,
      "feedback_email": "feedback@serenatools.com"
    },
    "beta_features": {
      "crash_reporting": true,
      "analytics": false,
      "feedback_collection": true
    }
  },
  "privacy": {
    "data_collection": "none",
    "tracking": false,
    "third_party_sdks": [],
    "encryption": "local_only",
    "data_retention": "user_controlled"
  },
  "requirements": {
    "minimum_ram": "4GB",
    "recommended_ram": "8GB",
    "disk_space": "2GB",
    "processor": "Apple Silicon or Intel x64",
    "special_hardware": "microphone_optional"
  }
}
EOF

echo -e "${GREEN}✅ Updated deployment configuration${NC}"

# Update code signing script with actual values
sed -i.bak "s/YOUR_TEAM_ID/$TEAM_ID/g" Scripts/code_sign.sh
sed -i.bak "s/Developer ID Application: Your Name (TEAM_ID)/Developer ID Application: $DEVELOPER_NAME ($TEAM_ID)/g" Scripts/code_sign.sh

echo -e "${GREEN}✅ Updated code signing script${NC}"

# Update notarization script with actual values
sed -i.bak "s/your-apple-id@example.com/$APPLE_ID/g" Scripts/notarize.sh
sed -i.bak "s/YOUR_TEAM_ID/$TEAM_ID/g" Scripts/notarize.sh

echo -e "${GREEN}✅ Updated notarization script${NC}"

# Clean up backup files
rm -f Scripts/*.bak

echo ""
echo -e "${BLUE}📋 Next Steps for Code Signing Setup${NC}"
echo "====================================="
echo ""
echo "1. **Install Certificates:**"
echo "   - Log in to Apple Developer Portal"
echo "   - Go to Certificates, Identifiers & Profiles"
echo "   - Download and install your certificates:"
echo "     • Developer ID Application (for direct distribution)"
echo "     • Mac App Store (for App Store submission)"
echo ""
echo "2. **Create App ID:**"
echo "   - In Apple Developer Portal, create App ID: $BUNDLE_ID"
echo "   - Enable required capabilities:"
echo "     • App Sandbox"
echo "     • Personal Information (Speech Recognition)"
echo ""
echo "3. **Create Provisioning Profiles:**"
echo "   - Create Mac App Store provisioning profile"
echo "   - Download and install the profile"
echo ""
echo "4. **Set Up App-Specific Password:**"
echo "   - Go to appleid.apple.com"
echo "   - Generate app-specific password for notarization"
echo "   - Update Scripts/notarize.sh with the password"
echo ""
echo "5. **Test Code Signing:**"
echo "   - Run: ./Scripts/build_release.sh"
echo "   - Run: ./Scripts/code_sign.sh"
echo "   - Verify signature: codesign --verify --verbose build/SerenaNet.app"
echo ""

echo -e "${YELLOW}⚠️  Important Security Notes:${NC}"
echo "• Never commit app-specific passwords to version control"
echo "• Store sensitive credentials in Keychain or environment variables"
echo "• Use separate certificates for development and distribution"
echo "• Regularly rotate app-specific passwords"

echo ""
echo -e "${GREEN}✅ Provisioning setup completed!${NC}"
echo -e "${BLUE}Configuration files updated with your information.${NC}"