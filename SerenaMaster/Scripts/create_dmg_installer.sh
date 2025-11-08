#!/bin/bash

# SerenaNet DMG Installer Creation Script
# This script creates a professional DMG installer for SerenaNet

set -e

# Configuration
APP_NAME="SerenaNet"
APP_PATH="./build/SerenaNet.app"
DMG_PATH="./build/SerenaNet.dmg"
VOLUME_NAME="SerenaNet"
TEMP_DMG="./build/temp.dmg"
MOUNT_POINT="./build/dmg_mount"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                SerenaNet DMG Creation                        ║"
echo "║                                                              ║"
echo "║  💿 Creating professional installer package                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App bundle not found at $APP_PATH${NC}"
    echo "Please run build_release.sh first"
    exit 1
fi

# Clean up any existing files
echo -e "${YELLOW}🧹 Cleaning up previous builds...${NC}"
rm -f "$DMG_PATH" "$TEMP_DMG"
rm -rf "$MOUNT_POINT"

# Check if create-dmg is available
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}⚠️  create-dmg not found. Installing via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install create-dmg
    else
        echo -e "${RED}❌ Homebrew not found. Please install create-dmg manually:${NC}"
        echo "   brew install create-dmg"
        echo "   or visit: https://github.com/create-dmg/create-dmg"
        exit 1
    fi
fi

# Get app version for DMG name
APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
VERSIONED_DMG_PATH="./build/SerenaNet-${APP_VERSION}.dmg"

echo -e "${BLUE}📦 Creating DMG installer...${NC}"
echo "App: $APP_PATH"
echo "Version: $APP_VERSION"
echo "Output: $VERSIONED_DMG_PATH"
echo ""

# Create background image if it doesn't exist
BACKGROUND_PATH="./Marketing/AppStore/dmg_background.png"
if [ ! -f "$BACKGROUND_PATH" ]; then
    echo -e "${YELLOW}🎨 Creating default background image...${NC}"
    mkdir -p "./Marketing/AppStore"
    
    # Create a simple background using ImageMagick if available
    if command -v magick &> /dev/null; then
        magick -size 600x400 xc:"#f0f0f0" \
            -fill "#007AFF" \
            -font "Helvetica-Bold" \
            -pointsize 24 \
            -gravity center \
            -annotate +0-50 "SerenaNet" \
            -pointsize 14 \
            -annotate +0-20 "Local AI Assistant" \
            -pointsize 12 \
            -fill "#666666" \
            -annotate +0+20 "Drag SerenaNet to Applications folder to install" \
            "$BACKGROUND_PATH"
        echo -e "${GREEN}✅ Created background image${NC}"
    else
        echo -e "${YELLOW}⚠️  ImageMagick not found, using default background${NC}"
        BACKGROUND_PATH=""
    fi
fi

# Create the DMG
echo -e "${YELLOW}💿 Building DMG installer...${NC}"

# Build create-dmg command
CREATE_DMG_CMD=(
    create-dmg
    --volname "$VOLUME_NAME"
    --volicon "$APP_PATH/Contents/Resources/AppIcon.appiconset/icon_512x512.png"
    --window-pos 200 120
    --window-size 600 400
    --icon-size 100
    --icon "$APP_NAME.app" 150 200
    --hide-extension "$APP_NAME.app"
    --app-drop-link 450 200
    --hdiutil-quiet
)

# Add background if available
if [ -n "$BACKGROUND_PATH" ] && [ -f "$BACKGROUND_PATH" ]; then
    CREATE_DMG_CMD+=(--background "$BACKGROUND_PATH")
fi

# Add output path and source
CREATE_DMG_CMD+=("$VERSIONED_DMG_PATH" "$APP_PATH")

# Execute create-dmg
"${CREATE_DMG_CMD[@]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DMG created successfully${NC}"
else
    echo -e "${RED}❌ DMG creation failed${NC}"
    exit 1
fi

# Create a symlink to the latest version
ln -sf "SerenaNet-${APP_VERSION}.dmg" "./build/SerenaNet-latest.dmg"

# Get DMG size
DMG_SIZE=$(du -h "$VERSIONED_DMG_PATH" | cut -f1)

echo ""
echo -e "${BLUE}🔍 DMG Validation${NC}"
echo "=================="

# Verify DMG can be mounted
echo -e "${YELLOW}📀 Testing DMG mount...${NC}"
if hdiutil attach "$VERSIONED_DMG_PATH" -mountpoint "$MOUNT_POINT" -quiet; then
    echo -e "${GREEN}✅ DMG mounts successfully${NC}"
    
    # Check if app is accessible
    if [ -d "$MOUNT_POINT/$APP_NAME.app" ]; then
        echo -e "${GREEN}✅ App bundle accessible in DMG${NC}"
    else
        echo -e "${RED}❌ App bundle not found in DMG${NC}"
    fi
    
    # Check if Applications link works
    if [ -L "$MOUNT_POINT/Applications" ]; then
        echo -e "${GREEN}✅ Applications link present${NC}"
    else
        echo -e "${YELLOW}⚠️  Applications link not found${NC}"
    fi
    
    # Unmount
    hdiutil detach "$MOUNT_POINT" -quiet
    rm -rf "$MOUNT_POINT"
else
    echo -e "${RED}❌ Failed to mount DMG${NC}"
    exit 1
fi

# Create installation instructions
cat > "./build/Installation_Instructions.md" << EOF
# SerenaNet Installation Instructions

## System Requirements
- macOS 13.0 or later
- 4GB RAM (8GB recommended)
- 2GB available disk space
- Apple Silicon or Intel processor

## Installation Steps

### Method 1: DMG Installer (Recommended)
1. Download SerenaNet-${APP_VERSION}.dmg
2. Double-click the DMG file to mount it
3. Drag SerenaNet.app to the Applications folder
4. Eject the DMG by clicking the eject button in Finder
5. Launch SerenaNet from Applications folder

### Method 2: Direct App Bundle
1. Download and extract the app bundle
2. Move SerenaNet.app to your Applications folder
3. Right-click and select "Open" for first launch (if unsigned)

## First Launch
1. SerenaNet will request microphone permission for voice input
2. Complete the onboarding process
3. Start chatting with your local AI assistant!

## Troubleshooting

### "SerenaNet can't be opened because it's from an unidentified developer"
1. Right-click on SerenaNet.app
2. Select "Open" from the context menu
3. Click "Open" in the security dialog
4. This only needs to be done once

### App won't launch or crashes
1. Ensure you're running macOS 13.0 or later
2. Check that you have at least 4GB of available RAM
3. Try restarting your Mac
4. Contact support if issues persist

### Voice input not working
1. Check System Settings > Privacy & Security > Microphone
2. Ensure SerenaNet has microphone permission
3. Try restarting the app
4. Check that no other app is using the microphone

## Uninstallation
1. Quit SerenaNet if it's running
2. Move SerenaNet.app from Applications to Trash
3. Empty the Trash
4. Optionally, remove user data from ~/Library/Application Support/SerenaNet

## Support
- Documentation: https://serenatools.com/docs
- Support: https://serenatools.com/support
- Email: support@serenatools.com

## Privacy
SerenaNet processes all data locally on your device. No information is sent to external servers. Your conversations remain completely private.
EOF

echo -e "${GREEN}✅ Created installation instructions${NC}"

# Create checksums for verification
echo -e "${YELLOW}🔐 Generating checksums...${NC}"
shasum -a 256 "$VERSIONED_DMG_PATH" > "./build/SerenaNet-${APP_VERSION}.dmg.sha256"
echo -e "${GREEN}✅ SHA256 checksum created${NC}"

echo ""
echo -e "${GREEN}🎉 DMG Creation Summary${NC}"
echo "======================="
echo -e "${BLUE}✅ DMG File:${NC} $VERSIONED_DMG_PATH"
echo -e "${BLUE}✅ Size:${NC} $DMG_SIZE"
echo -e "${BLUE}✅ Version:${NC} $APP_VERSION"
echo -e "${BLUE}✅ Checksum:${NC} ./build/SerenaNet-${APP_VERSION}.dmg.sha256"
echo -e "${BLUE}✅ Instructions:${NC} ./build/Installation_Instructions.md"

echo ""
echo -e "${BLUE}📋 Distribution Checklist${NC}"
echo "========================="
echo "- [ ] Test DMG on different macOS versions"
echo "- [ ] Verify installation process works correctly"
echo "- [ ] Test app launches and functions properly"
echo "- [ ] Upload to distribution server or website"
echo "- [ ] Update download links and documentation"
echo "- [ ] Notify users of new release"

echo ""
echo -e "${BLUE}📁 Build Artifacts${NC}"
echo "=================="
ls -la ./build/*.dmg ./build/*.sha256 ./build/*.md 2>/dev/null || echo "No artifacts found"

echo ""
echo -e "${GREEN}✅ DMG installer creation completed successfully!${NC}"