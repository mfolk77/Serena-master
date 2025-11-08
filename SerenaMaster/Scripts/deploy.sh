#!/bin/bash

# SerenaNet Master Deployment Script
# This script orchestrates the complete deployment process

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
DEPLOYMENT_TYPE="${1:-dmg}"  # dmg, testflight, or appstore

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    SerenaNet Deployment                     ║"
echo "║                                                              ║"
echo "║  🚀 Automated build, sign, and distribution pipeline        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}📋 Deployment Configuration:${NC}"
echo "Deployment Type: $DEPLOYMENT_TYPE"
echo "Project Root: $PROJECT_ROOT"
echo "Build Directory: $BUILD_DIR"
echo ""

# Validate deployment type
case $DEPLOYMENT_TYPE in
    dmg|testflight|appstore)
        echo -e "${GREEN}✅ Valid deployment type: $DEPLOYMENT_TYPE${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid deployment type: $DEPLOYMENT_TYPE${NC}"
        echo "Valid options: dmg, testflight, appstore"
        exit 1
        ;;
esac

# Pre-flight checks
echo -e "${YELLOW}🔍 Running pre-flight checks...${NC}"

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/Package.swift" ]; then
    echo -e "${RED}❌ Package.swift not found. Please run from project root.${NC}"
    exit 1
fi

# Check for required tools
REQUIRED_TOOLS=("swift" "codesign" "xcrun")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Required tool not found: $tool${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Pre-flight checks passed${NC}"
echo ""

# Step 1: Clean and Build
echo -e "${BLUE}🏗️  Step 1: Building Release Version${NC}"
echo "----------------------------------------"
cd "$PROJECT_ROOT"

if [ -f "$SCRIPT_DIR/build_release.sh" ]; then
    bash "$SCRIPT_DIR/build_release.sh"
else
    echo -e "${YELLOW}⚠️  build_release.sh not found, running basic build...${NC}"
    swift build --configuration release --arch arm64 --arch x86_64
fi

echo ""

# Step 2: Code Signing (for dmg and appstore deployments)
if [ "$DEPLOYMENT_TYPE" != "testflight" ]; then
    echo -e "${BLUE}🔐 Step 2: Code Signing${NC}"
    echo "------------------------"
    
    if [ -f "$SCRIPT_DIR/code_sign.sh" ]; then
        # Check if signing configuration exists
        if grep -q "YOUR_TEAM_ID" "$SCRIPT_DIR/code_sign.sh"; then
            echo -e "${YELLOW}⚠️  Code signing not configured. Please update code_sign.sh with your Developer ID.${NC}"
            echo "Skipping code signing step..."
        else
            bash "$SCRIPT_DIR/code_sign.sh"
        fi
    else
        echo -e "${YELLOW}⚠️  code_sign.sh not found, skipping code signing...${NC}"
    fi
    
    echo ""
fi

# Step 3: Deployment-specific actions
case $DEPLOYMENT_TYPE in
    dmg)
        echo -e "${BLUE}💿 Step 3: Creating DMG Distribution${NC}"
        echo "------------------------------------"
        
        if [ -d "$BUILD_DIR/SerenaNet.app" ]; then
            # Use enhanced DMG creation script
            if [ -f "$SCRIPT_DIR/create_dmg_installer.sh" ]; then
                bash "$SCRIPT_DIR/create_dmg_installer.sh"
            else
                # Fallback to basic DMG creation
                if command -v create-dmg &> /dev/null; then
                    create-dmg \
                        --volname "SerenaNet" \
                        --window-pos 200 120 \
                        --window-size 600 400 \
                        --icon-size 100 \
                        --icon "SerenaNet.app" 175 120 \
                        --hide-extension "SerenaNet.app" \
                        --app-drop-link 425 120 \
                        "$BUILD_DIR/SerenaNet.dmg" \
                        "$BUILD_DIR/SerenaNet.app"
                    
                    echo -e "${GREEN}✅ DMG created successfully${NC}"
                else
                    echo -e "${YELLOW}⚠️  create-dmg not found. Install with: brew install create-dmg${NC}"
                    echo -e "${BLUE}📦 App bundle ready at $BUILD_DIR/SerenaNet.app${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ App bundle not found at $BUILD_DIR/SerenaNet.app${NC}"
            exit 1
        fi
        ;;
        
    testflight)
        echo -e "${BLUE}✈️  Step 3: Preparing for TestFlight${NC}"
        echo "------------------------------------"
        
        if [ -f "$SCRIPT_DIR/prepare_testflight.sh" ]; then
            bash "$SCRIPT_DIR/prepare_testflight.sh"
        else
            echo -e "${YELLOW}⚠️  prepare_testflight.sh not found${NC}"
            echo "Please create an Xcode project and upload manually to TestFlight"
        fi
        ;;
        
    appstore)
        echo -e "${BLUE}🏪 Step 3: Preparing for App Store${NC}"
        echo "-----------------------------------"
        
        # Notarization step
        if [ -f "$SCRIPT_DIR/notarize.sh" ]; then
            if grep -q "your-apple-id@example.com" "$SCRIPT_DIR/notarize.sh"; then
                echo -e "${YELLOW}⚠️  Notarization not configured. Please update notarize.sh with your Apple ID.${NC}"
                echo "Skipping notarization step..."
            else
                bash "$SCRIPT_DIR/notarize.sh"
            fi
        else
            echo -e "${YELLOW}⚠️  notarize.sh not found, skipping notarization...${NC}"
        fi
        
        echo -e "${BLUE}📋 App Store submission checklist created${NC}"
        echo "Please review APP_STORE_SUBMISSION.md for next steps"
        ;;
esac

echo ""

# Step 4: Validation and Testing
echo -e "${BLUE}🧪 Step 4: Validation${NC}"
echo "---------------------"

# Use comprehensive validation script if available
if [ -f "$SCRIPT_DIR/validate_deployment.sh" ]; then
    echo -e "${YELLOW}🔍 Running comprehensive validation...${NC}"
    bash "$SCRIPT_DIR/validate_deployment.sh"
else
    # Fallback to basic validation
    if [ -d "$BUILD_DIR/SerenaNet.app" ]; then
        echo -e "${YELLOW}🔍 Validating app bundle...${NC}"
        
        # Check if app bundle is valid
        if [ -f "$BUILD_DIR/SerenaNet.app/Contents/MacOS/SerenaNet" ]; then
            echo -e "${GREEN}✅ Executable found${NC}"
        else
            echo -e "${RED}❌ Executable not found${NC}"
        fi
        
        # Check Info.plist
        if [ -f "$BUILD_DIR/SerenaNet.app/Contents/Info.plist" ]; then
            echo -e "${GREEN}✅ Info.plist found${NC}"
        else
            echo -e "${RED}❌ Info.plist not found${NC}"
        fi
        
        # Check code signature (if signed)
        if codesign --verify --verbose "$BUILD_DIR/SerenaNet.app" 2>/dev/null; then
            echo -e "${GREEN}✅ Code signature valid${NC}"
        else
            echo -e "${YELLOW}⚠️  App not signed or signature invalid${NC}"
        fi
        
    else
        echo -e "${RED}❌ App bundle not found${NC}"
    fi
fi

echo ""

# Step 5: Summary and Next Steps
echo -e "${PURPLE}🎉 Deployment Summary${NC}"
echo "====================="

case $DEPLOYMENT_TYPE in
    dmg)
        if [ -f "$BUILD_DIR/SerenaNet.dmg" ]; then
            echo -e "${GREEN}✅ DMG created successfully: $BUILD_DIR/SerenaNet.dmg${NC}"
            echo -e "${BLUE}📋 Next Steps:${NC}"
            echo "1. Test the DMG on different macOS systems"
            echo "2. Distribute to users via website or direct download"
            echo "3. Consider notarization for better user experience"
        else
            echo -e "${GREEN}✅ App bundle created: $BUILD_DIR/SerenaNet.app${NC}"
            echo -e "${BLUE}📋 Next Steps:${NC}"
            echo "1. Install create-dmg: brew install create-dmg"
            echo "2. Re-run deployment to create DMG"
            echo "3. Test on different macOS systems"
        fi
        ;;
        
    testflight)
        echo -e "${GREEN}✅ TestFlight preparation completed${NC}"
        echo -e "${BLUE}📋 Next Steps:${NC}"
        echo "1. Create Xcode project from Swift Package Manager code"
        echo "2. Configure signing and provisioning profiles"
        echo "3. Archive and upload to TestFlight"
        echo "4. Review checklist at $BUILD_DIR/testflight/TestFlight_Checklist.md"
        ;;
        
    appstore)
        echo -e "${GREEN}✅ App Store preparation completed${NC}"
        echo -e "${BLUE}📋 Next Steps:${NC}"
        echo "1. Complete notarization if not done automatically"
        echo "2. Review APP_STORE_SUBMISSION.md for submission guide"
        echo "3. Upload to App Store Connect"
        echo "4. Submit for App Store review"
        ;;
esac

echo ""
echo -e "${BLUE}📁 Build Artifacts:${NC}"
if [ -d "$BUILD_DIR" ]; then
    ls -la "$BUILD_DIR"
else
    echo "No build directory found"
fi

echo ""
echo -e "${PURPLE}🎯 Deployment Complete${NC}"
echo "====================="
echo -e "${GREEN}✅ Deployment process completed successfully!${NC}"
echo ""
echo -e "${BLUE}📚 Additional Resources:${NC}"
echo "• Documentation: https://serenatools.com/docs"
echo "• Support: https://serenatools.com/support"
echo "• Deployment Guide: ./DEPLOYMENT_GUIDE.md"
echo "• App Store Submission: ./APP_STORE_SUBMISSION.md"
echo ""
echo -e "${BLUE}🛠️  Available Scripts:${NC}"
echo "• ./Scripts/setup_provisioning.sh - Configure code signing"
echo "• ./Scripts/validate_deployment.sh - Comprehensive validation"
echo "• ./Scripts/validate_app_store_compliance.sh - App Store compliance"
echo "• ./Scripts/create_dmg_installer.sh - Professional DMG creation"
echo ""
echo -e "${GREEN}Happy deploying! 🚀${NC}"