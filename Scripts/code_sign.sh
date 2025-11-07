#!/bin/bash

# SerenaNet Code Signing Script
# This script signs the SerenaNet app for distribution

set -e  # Exit on any error

# Configuration - Update these with your actual values
DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
APP_PATH="./build/SerenaNet.app"
ENTITLEMENTS_PATH="./Scripts/SerenaNet.entitlements"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Starting SerenaNet Code Signing${NC}"
echo "App Path: $APP_PATH"
echo "Developer ID: $DEVELOPER_ID"
echo ""

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App bundle not found at $APP_PATH${NC}"
    echo "Please run build_release.sh first"
    exit 1
fi

# Check if entitlements file exists
if [ ! -f "$ENTITLEMENTS_PATH" ]; then
    echo -e "${YELLOW}⚠️  Entitlements file not found, creating default...${NC}"
    mkdir -p ./Scripts
    cat > "$ENTITLEMENTS_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <false/>
    <key>com.apple.security.network.server</key>
    <false/>
</dict>
</plist>
EOF
    echo -e "${GREEN}✅ Created default entitlements file${NC}"
fi

# List available signing identities
echo -e "${YELLOW}🔍 Available signing identities:${NC}"
security find-identity -v -p codesigning

echo ""
echo -e "${YELLOW}🔐 Signing app bundle...${NC}"

# Sign the app
codesign --force --options runtime --entitlements "$ENTITLEMENTS_PATH" --sign "$DEVELOPER_ID" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ App signed successfully${NC}"
else
    echo -e "${RED}❌ Code signing failed${NC}"
    echo "Please check your Developer ID and ensure you have the correct certificates installed"
    exit 1
fi

# Verify the signature
echo -e "${YELLOW}🔍 Verifying signature...${NC}"
codesign --verify --verbose "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Signature verification passed${NC}"
else
    echo -e "${RED}❌ Signature verification failed${NC}"
    exit 1
fi

# Display signature information
echo ""
echo -e "${BLUE}📋 Signature Information:${NC}"
codesign --display --verbose=4 "$APP_PATH"

echo ""
echo -e "${GREEN}🎉 Code Signing Summary:${NC}"
echo "✅ App bundle signed successfully"
echo "✅ Signature verified"
echo "✅ Ready for notarization"

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Notarize the app with Apple (see notarize.sh)"
echo "2. Staple the notarization ticket"
echo "3. Create final DMG for distribution"

echo ""
echo -e "${GREEN}✅ Code signing process completed successfully!${NC}"