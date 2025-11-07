#!/bin/bash

# Validate App Store Compliance for SerenaNet
# This script checks various compliance requirements before submission

set -e

echo "🔍 Validating App Store Compliance for SerenaNet..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

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

# Check if file exists
check_file() {
    if [ -f "$1" ]; then
        check_pass "File exists: $1"
        return 0
    else
        check_fail "Missing file: $1"
        return 1
    fi
}

# Check if directory exists
check_dir() {
    if [ -d "$1" ]; then
        check_pass "Directory exists: $1"
        return 0
    else
        check_fail "Missing directory: $1"
        return 1
    fi
}

echo ""
echo "📱 App Metadata Validation"
echo "=========================="

# Check Info.plist
if check_file "Sources/SerenaNet/Info.plist"; then
    # Check bundle identifier
    if grep -q "com.serenatools.serenanet" Sources/SerenaNet/Info.plist; then
        check_pass "Bundle identifier configured"
    else
        check_fail "Bundle identifier not found or incorrect"
    fi
    
    # Check version info
    if grep -q "CFBundleShortVersionString" Sources/SerenaNet/Info.plist; then
        check_pass "Version string configured"
    else
        check_fail "Version string missing"
    fi
    
    # Check privacy descriptions
    if grep -q "NSMicrophoneUsageDescription" Sources/SerenaNet/Info.plist; then
        check_pass "Microphone usage description present"
    else
        check_fail "Microphone usage description missing"
    fi
    
    if grep -q "NSSpeechRecognitionUsageDescription" Sources/SerenaNet/Info.plist; then
        check_pass "Speech recognition usage description present"
    else
        check_fail "Speech recognition usage description missing"
    fi
    
    # Check app category
    if grep -q "public.app-category.productivity" Sources/SerenaNet/Info.plist; then
        check_pass "App category set to Productivity"
    else
        check_warn "App category not set to Productivity"
    fi
fi

echo ""
echo "🔒 Privacy Compliance Validation"
echo "================================"

# Check privacy manifest
if check_file "Sources/SerenaNet/PrivacyInfo.xcprivacy"; then
    # Check no tracking declaration
    if grep -q "<false/>" Sources/SerenaNet/PrivacyInfo.xcprivacy; then
        check_pass "No tracking declared"
    else
        check_fail "Tracking declaration unclear"
    fi
    
    # Check API access declarations
    if grep -q "NSPrivacyAccessedAPITypes" Sources/SerenaNet/PrivacyInfo.xcprivacy; then
        check_pass "API access types declared"
    else
        check_warn "API access types not declared"
    fi
fi

echo ""
echo "🎨 App Icons Validation"
echo "======================="

# Check app icon structure
if check_dir "Sources/SerenaNet/Resources/AppIcon.appiconset"; then
    if check_file "Sources/SerenaNet/Resources/AppIcon.appiconset/Contents.json"; then
        # Check for required icon sizes
        required_sizes=("16x16" "32x32" "128x128" "256x256" "512x512")
        for size in "${required_sizes[@]}"; do
            if grep -q "\"size\" : \"$size\"" Sources/SerenaNet/Resources/AppIcon.appiconset/Contents.json; then
                check_pass "Icon size $size configured"
            else
                check_fail "Icon size $size missing from configuration"
            fi
        done
        
        # Check for actual icon files (basic check)
        icon_count=$(find Sources/SerenaNet/Resources/AppIcon.appiconset -name "*.png" | wc -l)
        if [ "$icon_count" -gt 0 ]; then
            check_pass "Icon files present ($icon_count found)"
            if [ "$icon_count" -lt 10 ]; then
                check_warn "Some icon files may be missing (expected ~10, found $icon_count)"
            fi
        else
            check_fail "No icon files found"
        fi
    fi
fi

echo ""
echo "📚 Help System Validation"
echo "========================="

# Check help view
if check_file "Sources/SerenaNet/Views/HelpView.swift"; then
    # Check for comprehensive help sections
    help_sections=("gettingStarted" "voiceInput" "conversations" "settings" "privacy" "troubleshooting" "shortcuts" "about")
    for section in "${help_sections[@]}"; do
        if grep -q "$section" Sources/SerenaNet/Views/HelpView.swift; then
            check_pass "Help section: $section"
        else
            check_fail "Missing help section: $section"
        fi
    done
fi

# Check onboarding view
if check_file "Sources/SerenaNet/Views/OnboardingView.swift"; then
    if grep -q "OnboardingPage" Sources/SerenaNet/Views/OnboardingView.swift; then
        check_pass "Onboarding system implemented"
    else
        check_warn "Onboarding system may be incomplete"
    fi
fi

echo ""
echo "📄 Marketing Materials Validation"
echo "================================="

# Check marketing structure
check_dir "Marketing"
check_file "Marketing/README.md"
check_dir "Marketing/AppStore"
check_dir "Marketing/AppStore/Screenshots"
check_file "Marketing/AppStore/Screenshots/README.md"

# Check app metadata
check_file "AppMetadata.md"
check_file "APP_STORE_SUBMISSION.md"
check_file "APP_STORE_SUBMISSION_CHECKLIST.md"

echo ""
echo "🔧 Build System Validation"
echo "=========================="

# Check deployment scripts
scripts=("build_release.sh" "code_sign.sh" "notarize.sh" "deploy.sh" "prepare_testflight.sh")
for script in "${scripts[@]}"; do
    if check_file "Scripts/$script"; then
        if [ -x "Scripts/$script" ]; then
            check_pass "Script executable: $script"
        else
            check_warn "Script not executable: $script"
        fi
    fi
done

# Check Package.swift
if check_file "Package.swift"; then
    if grep -q "platforms:" Package.swift; then
        check_pass "Platform requirements specified"
    else
        check_warn "Platform requirements not clearly specified"
    fi
fi

echo ""
echo "🧪 Code Quality Validation"
echo "=========================="

# Check for Swift build
if command -v swift &> /dev/null; then
    check_pass "Swift compiler available"
    
    # Try to build (basic syntax check)
    if swift build --configuration release --quiet 2>/dev/null; then
        check_pass "Swift build successful"
    else
        check_fail "Swift build failed - check for compilation errors"
    fi
else
    check_warn "Swift compiler not found - cannot validate build"
fi

# Check for test files
test_count=$(find Tests -name "*.swift" 2>/dev/null | wc -l)
if [ "$test_count" -gt 0 ]; then
    check_pass "Test files present ($test_count found)"
else
    check_warn "No test files found"
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

echo ""
if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed! App is ready for App Store submission.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Validations passed with warnings. Review warnings before submission.${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ Validation failed. Please fix the issues above before submission.${NC}"
    echo ""
    echo "Common fixes:"
    echo "• Run ./Scripts/generate_placeholder_icons.sh to create icon files"
    echo "• Update Info.plist with correct bundle identifier and descriptions"
    echo "• Ensure all required files are present and properly configured"
    echo "• Fix any Swift compilation errors"
    exit 1
fi