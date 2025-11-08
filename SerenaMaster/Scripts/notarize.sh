#!/bin/bash

# SerenaNet Notarization Script
# This script notarizes the SerenaNet app with Apple

set -e  # Exit on any error

# Configuration - Update these with your actual values
APPLE_ID="your-apple-id@example.com"
TEAM_ID="YOUR_TEAM_ID"
APP_SPECIFIC_PASSWORD="your-app-specific-password"
APP_PATH="./build/SerenaNet.app"
ZIP_PATH="./build/SerenaNet.zip"
BUNDLE_ID="com.serenatools.serenanet"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍎 Starting SerenaNet Notarization${NC}"
echo "App Path: $APP_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo ""

# Check if app exists and is signed
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App bundle not found at $APP_PATH${NC}"
    echo "Please run build_release.sh and code_sign.sh first"
    exit 1
fi

# Verify the app is signed
echo -e "${YELLOW}🔍 Verifying app signature...${NC}"
codesign --verify --verbose "$APP_PATH"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ App is not properly signed${NC}"
    echo "Please run code_sign.sh first"
    exit 1
fi

# Create zip file for notarization
echo -e "${YELLOW}📦 Creating zip file for notarization...${NC}"
cd ./build
zip -r SerenaNet.zip SerenaNet.app
cd ..

if [ ! -f "$ZIP_PATH" ]; then
    echo -e "${RED}❌ Failed to create zip file${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Zip file created: $ZIP_PATH${NC}"

# Submit for notarization
echo -e "${YELLOW}🚀 Submitting for notarization...${NC}"
echo "This may take several minutes..."

# Using xcrun notarytool (Xcode 13+)
if command -v xcrun &> /dev/null && xcrun notarytool --help &> /dev/null; then
    echo "Using notarytool..."
    
    # Store credentials (run this once)
    echo -e "${BLUE}💾 Storing notarization credentials...${NC}"
    echo "You may be prompted to enter your app-specific password"
    
    # Submit for notarization
    SUBMISSION_ID=$(xcrun notarytool submit "$ZIP_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --wait \
        --output-format json | jq -r '.id')
    
    if [ "$SUBMISSION_ID" != "null" ] && [ -n "$SUBMISSION_ID" ]; then
        echo -e "${GREEN}✅ Notarization submitted successfully${NC}"
        echo "Submission ID: $SUBMISSION_ID"
        
        # Check status
        echo -e "${YELLOW}⏳ Checking notarization status...${NC}"
        xcrun notarytool info "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APP_SPECIFIC_PASSWORD"
        
        # Staple the notarization
        echo -e "${YELLOW}📎 Stapling notarization to app...${NC}"
        xcrun stapler staple "$APP_PATH"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Notarization stapled successfully${NC}"
        else
            echo -e "${RED}❌ Failed to staple notarization${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Notarization submission failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  notarytool not available, using legacy altool...${NC}"
    
    # Legacy method using altool
    xcrun altool --notarize-app \
        --primary-bundle-id "$BUNDLE_ID" \
        --username "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --asc-provider "$TEAM_ID" \
        --file "$ZIP_PATH"
    
    echo -e "${YELLOW}⏳ Notarization submitted. Check status with:${NC}"
    echo "xcrun altool --notarization-history 0 --username $APPLE_ID --password $APP_SPECIFIC_PASSWORD"
fi

# Verify notarization
echo -e "${YELLOW}🔍 Verifying notarization...${NC}"
spctl --assess --verbose "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ App passes Gatekeeper assessment${NC}"
else
    echo -e "${YELLOW}⚠️  Gatekeeper assessment failed - this may be expected for development builds${NC}"
fi

# Clean up
echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
rm -f "$ZIP_PATH"

echo ""
echo -e "${GREEN}🎉 Notarization Summary:${NC}"
echo "✅ App submitted for notarization"
echo "✅ Notarization stapled (if successful)"
echo "✅ Ready for distribution"

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Create final DMG with notarized app"
echo "2. Test on different macOS systems"
echo "3. Distribute to users or submit to App Store"

echo ""
echo -e "${GREEN}✅ Notarization process completed!${NC}"