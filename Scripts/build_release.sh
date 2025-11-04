#!/bin/bash

# SerenaNet Release Build Script
# This script builds SerenaNet for distribution

set -e  # Exit on any error

# Configuration
PROJECT_NAME="SerenaNet"
SCHEME_NAME="SerenaNet"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/SerenaNet.xcarchive"
EXPORT_PATH="./build/export"
DMG_PATH="./build/SerenaNet.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting SerenaNet Release Build${NC}"
echo "Configuration: $CONFIGURATION"
echo "Archive Path: $ARCHIVE_PATH"
echo ""

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf ./build
mkdir -p ./build

# Build and archive
echo -e "${YELLOW}🔨 Building and archiving...${NC}"
swift build --configuration release --arch arm64 --arch x86_64

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build completed successfully${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Copy executable to build directory
echo -e "${YELLOW}📦 Preparing distribution package...${NC}"
mkdir -p ./build/SerenaNet.app/Contents/MacOS
mkdir -p ./build/SerenaNet.app/Contents/Resources

# Copy the built executable
cp ./.build/release/SerenaNet ./build/SerenaNet.app/Contents/MacOS/

# Copy Info.plist
cp ./Sources/SerenaNet/Info.plist ./build/SerenaNet.app/Contents/

# Copy privacy manifest
cp ./Sources/SerenaNet/PrivacyInfo.xcprivacy ./build/SerenaNet.app/Contents/Resources/

# Copy app icons if they exist
if [ -d "./Sources/SerenaNet/Resources/AppIcon.appiconset" ]; then
    cp -r ./Sources/SerenaNet/Resources/AppIcon.appiconset ./build/SerenaNet.app/Contents/Resources/
fi

# Set executable permissions
chmod +x ./build/SerenaNet.app/Contents/MacOS/SerenaNet

echo -e "${GREEN}✅ Distribution package created at ./build/SerenaNet.app${NC}"

# Create DMG (if create-dmg is available)
if command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}💿 Creating DMG installer...${NC}"
    create-dmg \
        --volname "SerenaNet" \
        --volicon "./Sources/SerenaNet/Resources/AppIcon.appiconset/icon_512x512.png" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "SerenaNet.app" 175 120 \
        --hide-extension "SerenaNet.app" \
        --app-drop-link 425 120 \
        "$DMG_PATH" \
        "./build/SerenaNet.app"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ DMG created successfully at $DMG_PATH${NC}"
    else
        echo -e "${YELLOW}⚠️  DMG creation failed, but app bundle is ready${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  create-dmg not found. Install with: brew install create-dmg${NC}"
    echo -e "${BLUE}📦 App bundle ready at ./build/SerenaNet.app${NC}"
fi

# Display build summary
echo ""
echo -e "${GREEN}🎉 Build Summary:${NC}"
echo "✅ Release build completed"
echo "✅ App bundle created: ./build/SerenaNet.app"
if [ -f "$DMG_PATH" ]; then
    echo "✅ DMG installer created: $DMG_PATH"
fi

# Display next steps
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Test the app bundle on a clean macOS system"
echo "2. Code sign the app for distribution (see code_sign.sh)"
echo "3. Notarize the app with Apple (see notarize.sh)"
echo "4. Distribute via DMG or prepare for App Store submission"

echo ""
echo -e "${GREEN}✅ Release build process completed successfully!${NC}"