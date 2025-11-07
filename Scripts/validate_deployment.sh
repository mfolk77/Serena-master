#!/bin/bash

# SerenaNet Deployment Validation Script
# This script validates the deployment package before distribution

set -e

# Configuration
APP_PATH="./build/SerenaNet.app"
DMG_PATH="./build/SerenaNet.dmg"
BUNDLE_ID="com.serenatools.serenanet"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              SerenaNet Deployment Validation                ║"
echo "║                                                              ║"
echo "║  🔍 Comprehensive validation before distribution             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Helper functions
check_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((WARNINGS++))
}

check_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

echo ""
echo -e "${BLUE}📱 App Bundle Validation${NC}"
echo "========================"

# Check if app bundle exists
if [ -d "$APP_PATH" ]; then
    check_pass "App bundle exists at $APP_PATH"
    
    # Check executable
    if [ -f "$APP_PATH/Contents/MacOS/SerenaNet" ]; then
        check_pass "Executable found"
        
        # Check if executable is actually executable
        if [ -x "$APP_PATH/Contents/MacOS/SerenaNet" ]; then
            check_pass "Executable has correct permissions"
        else
            check_fail "Executable is not executable"
        fi
    else
        check_fail "Executable not found"
    fi
    
    # Check Info.plist
    if [ -f "$APP_PATH/Contents/Info.plist" ]; then
        check_pass "Info.plist found"
        
        # Validate Info.plist content
        if plutil -lint "$APP_PATH/Contents/Info.plist" >/dev/null 2>&1; then
            check_pass "Info.plist is valid XML"
        else
            check_fail "Info.plist is malformed"
        fi
        
        # Check bundle identifier
        ACTUAL_BUNDLE_ID=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")
        if [ "$ACTUAL_BUNDLE_ID" = "$BUNDLE_ID" ]; then
            check_pass "Bundle identifier correct: $BUNDLE_ID"
        else
            check_fail "Bundle identifier mismatch: expected $BUNDLE_ID, got $ACTUAL_BUNDLE_ID"
        fi
        
        # Check version info
        VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "")
        BUILD=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "")
        
        if [ -n "$VERSION" ]; then
            check_pass "Version string present: $VERSION"
        else
            check_fail "Version string missing"
        fi
        
        if [ -n "$BUILD" ]; then
            check_pass "Build number present: $BUILD"
        else
            check_fail "Build number missing"
        fi
        
    else
        check_fail "Info.plist not found"
    fi
    
    # Check privacy manifest
    if [ -f "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy" ]; then
        check_pass "Privacy manifest found"
        
        if plutil -lint "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy" >/dev/null 2>&1; then
            check_pass "Privacy manifest is valid XML"
        else
            check_fail "Privacy manifest is malformed"
        fi
    else
        check_fail "Privacy manifest not found"
    fi
    
    # Check app icons
    if [ -d "$APP_PATH/Contents/Resources/AppIcon.appiconset" ]; then
        check_pass "App icon set found"
        
        # Count icon files
        ICON_COUNT=$(find "$APP_PATH/Contents/Resources/AppIcon.appiconset" -name "*.png" | wc -l)
        if [ "$ICON_COUNT" -gt 5 ]; then
            check_pass "Multiple icon sizes present ($ICON_COUNT icons)"
        else
            check_warn "Few icon files found ($ICON_COUNT icons)"
        fi
    else
        check_warn "App icon set not found"
    fi
    
else
    check_fail "App bundle not found at $APP_PATH"
fi

echo ""
echo -e "${BLUE}🔐 Code Signing Validation${NC}"
echo "=========================="

if [ -d "$APP_PATH" ]; then
    # Check if app is signed
    if codesign --verify --verbose "$APP_PATH" 2>/dev/null; then
        check_pass "App is code signed"
        
        # Get signing information
        SIGNING_INFO=$(codesign --display --verbose=4 "$APP_PATH" 2>&1)
        
        # Check for Developer ID
        if echo "$SIGNING_INFO" | grep -q "Developer ID Application"; then
            check_pass "Signed with Developer ID (for direct distribution)"
        elif echo "$SIGNING_INFO" | grep -q "Mac App Store"; then
            check_pass "Signed with Mac App Store certificate"
        else
            check_warn "Signed with unknown certificate type"
        fi
        
        # Check for hardened runtime
        if echo "$SIGNING_INFO" | grep -q "runtime"; then
            check_pass "Hardened runtime enabled"
        else
            check_warn "Hardened runtime not enabled"
        fi
        
        # Check entitlements
        if codesign --display --entitlements :- "$APP_PATH" 2>/dev/null | grep -q "entitlements"; then
            check_pass "Entitlements present"
        else
            check_warn "No entitlements found"
        fi
        
    else
        check_warn "App is not code signed"
        check_info "For distribution, code signing is recommended"
    fi
    
    # Check Gatekeeper assessment
    if spctl --assess --verbose "$APP_PATH" 2>/dev/null; then
        check_pass "Passes Gatekeeper assessment"
    else
        check_warn "Fails Gatekeeper assessment (may require notarization)"
    fi
fi

echo ""
echo -e "${BLUE}📦 DMG Package Validation${NC}"
echo "========================="

# Find DMG files
DMG_FILES=(./build/*.dmg)
if [ -f "${DMG_FILES[0]}" ]; then
    for dmg in "${DMG_FILES[@]}"; do
        if [ -f "$dmg" ]; then
            check_pass "DMG found: $(basename "$dmg")"
            
            # Check DMG integrity
            if hdiutil verify "$dmg" >/dev/null 2>&1; then
                check_pass "DMG integrity verified"
            else
                check_fail "DMG integrity check failed"
            fi
            
            # Check DMG size
            DMG_SIZE=$(du -h "$dmg" | cut -f1)
            check_info "DMG size: $DMG_SIZE"
            
            # Test mounting
            TEMP_MOUNT="/tmp/serenanet_validation_$$"
            if hdiutil attach "$dmg" -mountpoint "$TEMP_MOUNT" -quiet 2>/dev/null; then
                check_pass "DMG mounts successfully"
                
                # Check contents
                if [ -d "$TEMP_MOUNT/SerenaNet.app" ]; then
                    check_pass "App bundle present in DMG"
                else
                    check_fail "App bundle not found in DMG"
                fi
                
                if [ -L "$TEMP_MOUNT/Applications" ]; then
                    check_pass "Applications symlink present"
                else
                    check_warn "Applications symlink not found"
                fi
                
                # Unmount
                hdiutil detach "$TEMP_MOUNT" -quiet 2>/dev/null
                rm -rf "$TEMP_MOUNT"
            else
                check_fail "Failed to mount DMG"
            fi
        fi
    done
else
    check_warn "No DMG files found"
    check_info "Run create_dmg_installer.sh to create DMG"
fi

echo ""
echo -e "${BLUE}📋 Metadata Validation${NC}"
echo "======================"

# Check required documentation
REQUIRED_DOCS=("AppMetadata.md" "APP_STORE_SUBMISSION.md" "DEPLOYMENT_GUIDE.md")
for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        check_pass "Documentation present: $doc"
    else
        check_warn "Documentation missing: $doc"
    fi
done

# Check marketing materials
if [ -d "Marketing" ]; then
    check_pass "Marketing directory exists"
    
    if [ -d "Marketing/AppStore/Screenshots" ]; then
        check_pass "Screenshot directory exists"
        
        SCREENSHOT_COUNT=$(find Marketing/AppStore/Screenshots -name "*.png" -o -name "*.jpg" | wc -l)
        if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
            check_pass "Screenshots present ($SCREENSHOT_COUNT found)"
        else
            check_warn "No screenshots found"
        fi
    else
        check_warn "Screenshot directory not found"
    fi
else
    check_warn "Marketing directory not found"
fi

echo ""
echo -e "${BLUE}🧪 Functional Validation${NC}"
echo "========================"

if [ -d "$APP_PATH" ]; then
    # Check if app can be launched (basic test)
    check_info "Testing app launch (this may take a moment)..."
    
    # Try to get app info without launching
    if otool -L "$APP_PATH/Contents/MacOS/SerenaNet" >/dev/null 2>&1; then
        check_pass "App binary is valid Mach-O executable"
    else
        check_fail "App binary is not a valid executable"
    fi
    
    # Check for required frameworks/libraries
    REQUIRED_FRAMEWORKS=("Foundation" "AppKit" "SwiftUI")
    for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
        if otool -L "$APP_PATH/Contents/MacOS/SerenaNet" | grep -q "$framework"; then
            check_pass "Links to $framework framework"
        else
            check_warn "$framework framework not found in dependencies"
        fi
    done
    
    # Check architecture support
    ARCHS=$(lipo -archs "$APP_PATH/Contents/MacOS/SerenaNet" 2>/dev/null || echo "unknown")
    if echo "$ARCHS" | grep -q "arm64"; then
        check_pass "Supports Apple Silicon (arm64)"
    else
        check_warn "Apple Silicon support not detected"
    fi
    
    if echo "$ARCHS" | grep -q "x86_64"; then
        check_pass "Supports Intel (x86_64)"
    else
        check_warn "Intel support not detected"
    fi
    
    check_info "Supported architectures: $ARCHS"
fi

echo ""
echo -e "${BLUE}🔒 Security Validation${NC}"
echo "======================"

if [ -d "$APP_PATH" ]; then
    # Check for common security issues
    
    # Check for executable stack
    if otool -l "$APP_PATH/Contents/MacOS/SerenaNet" | grep -q "ALLOW_STACK_EXECUTION"; then
        check_warn "Executable stack detected (potential security risk)"
    else
        check_pass "No executable stack detected"
    fi
    
    # Check for PIE (Position Independent Executable)
    if otool -hv "$APP_PATH/Contents/MacOS/SerenaNet" | grep -q "PIE"; then
        check_pass "Position Independent Executable (PIE) enabled"
    else
        check_warn "PIE not enabled"
    fi
    
    # Check for stack canaries
    if otool -I "$APP_PATH/Contents/MacOS/SerenaNet" | grep -q "stack_chk"; then
        check_pass "Stack protection enabled"
    else
        check_warn "Stack protection not detected"
    fi
fi

echo ""
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "===================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

echo ""
if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed! Package is ready for distribution.${NC}"
        
        echo ""
        echo -e "${BLUE}📋 Distribution Checklist${NC}"
        echo "========================="
        echo "✅ App bundle validated"
        echo "✅ Code signing verified"
        echo "✅ DMG package tested"
        echo "✅ Documentation complete"
        echo "✅ Security checks passed"
        echo ""
        echo -e "${GREEN}Ready for distribution! 🚀${NC}"
        
        exit 0
    else
        echo -e "${YELLOW}⚠️  Validations passed with warnings. Review warnings before distribution.${NC}"
        
        echo ""
        echo -e "${BLUE}📋 Recommended Actions${NC}"
        echo "======================"
        echo "• Review and address warnings above"
        echo "• Test on different macOS versions"
        echo "• Consider code signing for better user experience"
        echo "• Create marketing screenshots if missing"
        echo "• Complete documentation if needed"
        
        exit 0
    fi
else
    echo -e "${RED}❌ Validation failed. Please fix the issues above before distribution.${NC}"
    
    echo ""
    echo -e "${BLUE}📋 Required Actions${NC}"
    echo "=================="
    echo "• Fix all failed validation checks"
    echo "• Rebuild the app if necessary"
    echo "• Re-run validation after fixes"
    echo "• Address any security concerns"
    
    exit 1
fi