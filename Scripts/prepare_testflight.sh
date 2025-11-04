#!/bin/bash

# SerenaNet TestFlight Preparation Script
# This script prepares SerenaNet for TestFlight beta testing

set -e  # Exit on any error

# Configuration
PROJECT_NAME="SerenaNet"
SCHEME_NAME="SerenaNet"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/SerenaNet.xcarchive"
EXPORT_PATH="./build/testflight"
EXPORT_OPTIONS_PLIST="./Scripts/ExportOptions-TestFlight.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}✈️ Preparing SerenaNet for TestFlight${NC}"
echo "Configuration: $CONFIGURATION"
echo "Export Path: $EXPORT_PATH"
echo ""

# Create export options plist if it doesn't exist
if [ ! -f "$EXPORT_OPTIONS_PLIST" ]; then
    echo -e "${YELLOW}📝 Creating TestFlight export options...${NC}"
    mkdir -p ./Scripts
    cat > "$EXPORT_OPTIONS_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>destination</key>
    <string>upload</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.serenatools.serenanet</key>
        <string>SerenaNet App Store</string>
    </dict>
</dict>
</plist>
EOF
    echo -e "${GREEN}✅ Created TestFlight export options${NC}"
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf ./build/testflight
mkdir -p ./build/testflight

# Note: For Swift Package Manager projects, we need to create an Xcode project first
echo -e "${YELLOW}📦 Preparing for TestFlight submission...${NC}"
echo ""
echo -e "${BLUE}📋 TestFlight Preparation Steps:${NC}"
echo ""
echo "1. Create Xcode Project:"
echo "   - Open Xcode and create a new macOS app project"
echo "   - Set Bundle ID to: com.serenatools.serenanet"
echo "   - Import your Swift Package Manager code"
echo "   - Configure signing with your App Store distribution certificate"
echo ""
echo "2. Configure App Store Connect:"
echo "   - Log in to App Store Connect (https://appstoreconnect.apple.com)"
echo "   - Create a new app with Bundle ID: com.serenatools.serenanet"
echo "   - Set up app metadata, descriptions, and screenshots"
echo "   - Configure TestFlight settings and beta testing groups"
echo ""
echo "3. Archive and Upload:"
echo "   - In Xcode: Product → Archive"
echo "   - Use Organizer to upload to App Store Connect"
echo "   - Select 'Distribute App' → 'App Store Connect' → 'Upload'"
echo ""
echo "4. TestFlight Configuration:"
echo "   - Add beta testers and groups in App Store Connect"
echo "   - Configure test information and feedback settings"
echo "   - Submit build for TestFlight review (if external testing)"
echo ""

# Create a configuration checklist
cat > "./build/testflight/TestFlight_Checklist.md" << EOF
# SerenaNet TestFlight Checklist

## Pre-Upload Requirements

### ✅ App Configuration
- [ ] Bundle ID matches App Store Connect: com.serenatools.serenanet
- [ ] Version number incremented from previous builds
- [ ] All required app icons included and properly sized
- [ ] Info.plist contains all required keys and descriptions
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) included

### ✅ Code Signing
- [ ] App Store distribution certificate installed
- [ ] App Store provisioning profile configured
- [ ] All frameworks and dependencies properly signed
- [ ] Entitlements file configured for App Store submission

### ✅ App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] App metadata completed (name, description, keywords)
- [ ] Screenshots uploaded for all required sizes
- [ ] Privacy policy URL configured
- [ ] Support URL configured
- [ ] Age rating completed

### ✅ TestFlight Configuration
- [ ] Beta testing groups created
- [ ] Internal testers added (if applicable)
- [ ] External testing configured (if needed)
- [ ] Test information and instructions provided
- [ ] Feedback settings configured

## Upload Process

1. **Archive in Xcode**
   - Product → Archive
   - Ensure "Release" configuration is selected
   - Wait for archive to complete

2. **Upload to App Store Connect**
   - Open Organizer (Window → Organizer)
   - Select your archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Select "Upload"
   - Follow the upload wizard

3. **Process in App Store Connect**
   - Wait for processing to complete (can take 10-60 minutes)
   - Check for any processing errors or warnings
   - Resolve any issues and re-upload if necessary

4. **Configure TestFlight Build**
   - Go to TestFlight tab in App Store Connect
   - Select your uploaded build
   - Add build notes and test information
   - Configure beta testing groups
   - Submit for TestFlight review (external testing only)

## Testing Process

### Internal Testing
- Add internal testers (up to 100)
- No review required
- Testers receive immediate access
- Can test for up to 90 days

### External Testing
- Add external testers (up to 10,000)
- Requires TestFlight review (1-3 days)
- Provide clear test instructions
- Monitor feedback and crash reports

## Success Criteria

- [ ] Build uploads successfully without errors
- [ ] All testers can download and install the app
- [ ] Core functionality works as expected
- [ ] No critical crashes or issues reported
- [ ] Feedback collected and addressed
- [ ] Ready for App Store submission

## Common Issues and Solutions

### Upload Failures
- **Invalid Bundle**: Check bundle ID matches App Store Connect
- **Missing Icons**: Ensure all required icon sizes are included
- **Code Signing**: Verify distribution certificate and provisioning profile
- **Entitlements**: Check sandbox and capability settings

### TestFlight Issues
- **Can't Download**: Check tester's device compatibility
- **Crashes on Launch**: Review crash logs in App Store Connect
- **Missing Features**: Verify all frameworks and resources are included

### Review Rejections
- **Privacy Issues**: Ensure privacy manifest is complete and accurate
- **Functionality**: Provide clear test instructions and demo account if needed
- **Metadata**: Keep app description and screenshots up to date

## Next Steps After TestFlight

1. **Collect Feedback**: Monitor TestFlight feedback and crash reports
2. **Fix Issues**: Address any bugs or usability issues found
3. **Update Build**: Upload new builds as needed for testing
4. **Prepare for Release**: Once testing is complete, prepare for App Store submission
5. **App Store Review**: Submit final build for App Store review and release

EOF

echo -e "${GREEN}✅ TestFlight checklist created at ./build/testflight/TestFlight_Checklist.md${NC}"

# Create App Store submission template
cat > "./build/testflight/AppStore_Submission_Template.md" << EOF
# SerenaNet App Store Submission

## App Information

**App Name:** SerenaNet
**Bundle ID:** com.serenatools.serenanet
**Version:** 1.0.0
**Category:** Productivity
**Platform:** macOS 13.0+

## Submission Metadata

### App Description
[Copy from AppMetadata.md]

### Keywords
AI assistant, local AI, privacy, offline AI, voice input, productivity, chat, conversation, secure, private, macOS

### What's New
Version 1.0.0 - Initial Release

Welcome to SerenaNet! This initial release includes:
- Local AI conversations with advanced language model
- Voice input with Apple SpeechKit integration
- Encrypted conversation storage and management
- Native macOS interface with keyboard shortcuts
- Complete privacy with local-only processing

### App Review Information

**Contact Information:**
- First Name: [Your First Name]
- Last Name: [Your Last Name]
- Phone Number: [Your Phone Number]
- Email: [Your Email]

**Review Notes:**
SerenaNet is a productivity-focused AI assistant that runs entirely locally on the user's device. Key differentiators:

1. LOCAL PROCESSING: All AI computation happens on-device using local models
2. PRODUCTIVITY FOCUS: Designed for users who need AI assistance while maintaining privacy
3. NATIVE INTEGRATION: Built with SwiftUI following macOS design guidelines
4. OFFLINE FUNCTIONALITY: Works completely offline once installed

No demo account required - all functionality is local.

**Demo Instructions:**
1. Launch app and complete onboarding
2. Test text conversations with sample questions
3. Try voice input (requires microphone permission)
4. Explore settings and privacy options
5. Test help system and keyboard shortcuts

### Age Rating
**Rating:** 4+
**Content Descriptors:** None

### Pricing and Availability
**Price:** Free (initially)
**Availability:** All territories where macOS apps are available

## Required Assets

### App Icons
- [x] macOS: 1024x1024px PNG (no transparency)

### Screenshots (macOS)
- [ ] Main interface (1280x800 or 1440x900)
- [ ] Voice input demonstration
- [ ] Settings and privacy features
- [ ] Conversation management
- [ ] Help and onboarding

### Marketing Assets
- [ ] App preview video (optional, 15-30 seconds)
- [ ] Promotional text (170 characters max)

## Legal and Compliance

### URLs
- **Privacy Policy:** https://serenatools.com/privacy
- **Terms of Service:** https://serenatools.com/terms
- **Support URL:** https://serenatools.com/support

### Privacy
- **Data Collection:** None
- **Data Usage:** Local processing only
- **Third-party SDKs:** None that collect data
- **Tracking:** None

### Export Compliance
- **Uses Encryption:** Yes (standard iOS/macOS encryption APIs only)
- **Exempt from Export Compliance:** Yes (uses only Apple-provided encryption)

## Submission Checklist

### Pre-Submission
- [ ] All metadata completed in App Store Connect
- [ ] Screenshots uploaded and properly formatted
- [ ] App icons uploaded and approved
- [ ] Privacy policy and support URLs active and accessible
- [ ] Age rating completed
- [ ] Pricing and availability configured

### Technical Requirements
- [ ] App builds and runs without crashes
- [ ] All features work as described
- [ ] Proper error handling implemented
- [ ] Memory usage within reasonable limits
- [ ] Follows macOS design guidelines

### Review Preparation
- [ ] Review notes clearly explain app's value proposition
- [ ] Demo instructions are clear and complete
- [ ] All required permissions properly explained
- [ ] App differentiates from generic chat applications

### Post-Submission
- [ ] Monitor review status in App Store Connect
- [ ] Respond promptly to any reviewer questions
- [ ] Address any rejection reasons quickly
- [ ] Prepare marketing materials for launch

## Success Metrics

- [ ] App approved on first submission
- [ ] No critical issues found during review
- [ ] All functionality works as expected
- [ ] Positive reviewer feedback
- [ ] Ready for public release

EOF

echo -e "${GREEN}✅ App Store submission template created${NC}"

echo ""
echo -e "${GREEN}🎉 TestFlight Preparation Summary:${NC}"
echo "✅ Export options configured"
echo "✅ TestFlight checklist created"
echo "✅ App Store submission template created"
echo "✅ Documentation and guides prepared"

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Create Xcode project from Swift Package Manager code"
echo "2. Configure code signing and provisioning profiles"
echo "3. Set up App Store Connect app and metadata"
echo "4. Archive and upload to TestFlight"
echo "5. Configure beta testing and collect feedback"

echo ""
echo -e "${GREEN}✅ TestFlight preparation completed successfully!${NC}"