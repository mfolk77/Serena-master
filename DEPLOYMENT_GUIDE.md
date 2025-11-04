# SerenaNet Deployment Guide

This guide covers the complete deployment pipeline for SerenaNet, from development build to App Store submission.

## Overview

SerenaNet supports three deployment methods:
1. **Direct DMG Distribution** - For direct user downloads
2. **TestFlight Beta Testing** - For beta testing with Apple's TestFlight
3. **App Store Submission** - For official App Store release

## Prerequisites

### Development Environment
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Command Line Tools installed

### Apple Developer Account
- Active Apple Developer Program membership
- App Store Connect access
- Code signing certificates configured
- Provisioning profiles created

### Required Tools
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install create-dmg
```

## Quick Start

### 1. Configure Deployment Settings

Update the following files with your actual values:

**Scripts/code_sign.sh:**
```bash
DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
```

**Scripts/notarize.sh:**
```bash
APPLE_ID="your-apple-id@example.com"
TEAM_ID="YOUR_TEAM_ID"
APP_SPECIFIC_PASSWORD="your-app-specific-password"
```

**deployment_config.json:**
```json
{
  "signing": {
    "team_id": "YOUR_TEAM_ID",
    "developer_id": "Developer ID Application: Your Name (TEAM_ID)"
  },
  "notarization": {
    "apple_id": "your-apple-id@example.com",
    "team_id": "YOUR_TEAM_ID"
  }
}
```

### 2. Run Deployment

Choose your deployment method:

```bash
# For DMG distribution
./Scripts/deploy.sh dmg

# For TestFlight preparation
./Scripts/deploy.sh testflight

# For App Store submission
./Scripts/deploy.sh appstore
```

## Detailed Deployment Process

### DMG Distribution

Creates a signed DMG file for direct distribution to users.

```bash
./Scripts/deploy.sh dmg
```

**Process:**
1. Builds release version of SerenaNet
2. Signs the app bundle with Developer ID
3. Creates DMG installer with create-dmg
4. Validates the final package

**Output:**
- `build/SerenaNet.app` - Signed app bundle
- `build/SerenaNet.dmg` - DMG installer

**Distribution:**
- Upload DMG to your website
- Users can download and install directly
- Gatekeeper will verify the signature

### TestFlight Beta Testing

Prepares the app for TestFlight beta distribution.

```bash
./Scripts/deploy.sh testflight
```

**Process:**
1. Creates TestFlight configuration files
2. Generates submission checklist
3. Provides step-by-step instructions

**Manual Steps Required:**
1. Create Xcode project from Swift Package Manager code
2. Configure App Store signing
3. Archive in Xcode
4. Upload to App Store Connect
5. Configure TestFlight settings

**Output:**
- `build/testflight/TestFlight_Checklist.md` - Complete checklist
- `build/testflight/AppStore_Submission_Template.md` - Submission template

### App Store Submission

Prepares the app for official App Store release.

```bash
./Scripts/deploy.sh appstore
```

**Process:**
1. Builds and signs the app
2. Notarizes with Apple (if configured)
3. Creates submission documentation
4. Validates the final package

**Output:**
- Notarized app bundle ready for submission
- Complete submission documentation
- App Store metadata templates

## Individual Script Usage

### Build Release

Creates a release build of SerenaNet:

```bash
./Scripts/build_release.sh
```

**Features:**
- Builds for both ARM64 and x86_64 architectures
- Creates proper app bundle structure
- Copies all required resources
- Sets correct permissions

### Code Signing

Signs the app bundle for distribution:

```bash
./Scripts/code_sign.sh
```

**Requirements:**
- Developer ID Application certificate installed
- Entitlements file configured
- App bundle already built

**Features:**
- Signs with hardened runtime
- Applies proper entitlements
- Verifies signature validity

### Notarization

Notarizes the app with Apple:

```bash
./Scripts/notarize.sh
```

**Requirements:**
- App-specific password configured
- Apple ID and Team ID set
- Signed app bundle

**Features:**
- Submits to Apple for notarization
- Waits for completion
- Staples notarization ticket
- Verifies Gatekeeper acceptance

### TestFlight Preparation

Prepares comprehensive TestFlight documentation:

```bash
./Scripts/prepare_testflight.sh
```

**Output:**
- TestFlight configuration checklist
- App Store submission template
- Step-by-step instructions

## Configuration Files

### Info.plist

Located at `Sources/SerenaNet/Info.plist`, contains:
- Bundle identifier and version information
- Privacy usage descriptions
- Document type associations
- App capabilities and requirements

### PrivacyInfo.xcprivacy

Privacy manifest at `Sources/SerenaNet/PrivacyInfo.xcprivacy`:
- Declares no tracking
- Lists accessed APIs and reasons
- Required for App Store submission

### Entitlements

App sandbox and capability configuration:
- Microphone access for voice input
- Speech recognition capability
- File system access (user-selected)
- No network access required

## Troubleshooting

### Common Build Issues

**Swift Build Fails:**
```bash
# Clean build directory
rm -rf .build
swift build --configuration release
```

**Missing Dependencies:**
```bash
# Update package dependencies
swift package update
swift package resolve
```

### Code Signing Issues

**Certificate Not Found:**
1. Check Keychain Access for certificates
2. Download from Apple Developer portal
3. Install in login keychain

**Provisioning Profile Issues:**
1. Create new profile in Apple Developer portal
2. Download and install
3. Update script configuration

### Notarization Problems

**Authentication Fails:**
1. Generate app-specific password
2. Update notarize.sh with correct credentials
3. Verify Team ID is correct

**Notarization Rejected:**
1. Check notarization log for details
2. Fix any code signing issues
3. Ensure all frameworks are signed

### TestFlight Issues

**Upload Fails:**
1. Check bundle ID matches App Store Connect
2. Verify all required metadata is complete
3. Ensure proper code signing

**Processing Errors:**
1. Review processing log in App Store Connect
2. Fix any identified issues
3. Upload new build

## Security Considerations

### Code Signing Best Practices

1. **Certificate Management:**
   - Store certificates securely
   - Use separate certificates for development and distribution
   - Regularly renew before expiration

2. **Private Key Protection:**
   - Never share private keys
   - Use secure keychain storage
   - Consider hardware security modules for production

3. **Entitlements:**
   - Request minimal necessary permissions
   - Document all capability requirements
   - Regular security audits

### Distribution Security

1. **DMG Distribution:**
   - Always sign and notarize
   - Use HTTPS for downloads
   - Provide checksums for verification

2. **App Store Distribution:**
   - Follow App Store security guidelines
   - Regular security updates
   - Monitor for security issues

## Monitoring and Maintenance

### Post-Deployment Monitoring

1. **Crash Reports:**
   - Monitor TestFlight and App Store Connect
   - Set up automated crash reporting
   - Regular analysis and fixes

2. **User Feedback:**
   - Monitor App Store reviews
   - TestFlight feedback collection
   - Support channel monitoring

3. **Performance Metrics:**
   - App launch times
   - Memory usage patterns
   - User engagement metrics

### Update Process

1. **Version Management:**
   - Semantic versioning (1.0.0, 1.0.1, 1.1.0)
   - Clear changelog documentation
   - Backward compatibility considerations

2. **Release Cadence:**
   - Regular security updates
   - Feature releases based on feedback
   - Emergency patches as needed

## Support and Resources

### Documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

### Tools and Utilities
- [create-dmg](https://github.com/create-dmg/create-dmg) - DMG creation tool
- [App Store Connect](https://appstoreconnect.apple.com) - App management
- [Xcode](https://developer.apple.com/xcode/) - Development environment

### Support Channels
- **Technical Issues:** Create GitHub issues
- **Deployment Questions:** Check documentation first
- **Apple-specific Issues:** Apple Developer Support

## Success Criteria

A successful deployment should achieve:

- ✅ Clean build with zero warnings
- ✅ Valid code signature and notarization
- ✅ Successful installation on clean macOS systems
- ✅ All features working as expected
- ✅ Proper App Store metadata and compliance
- ✅ Positive TestFlight feedback (if applicable)
- ✅ App Store approval (for store submissions)

## Next Steps

After successful deployment:

1. **Monitor Performance:** Track app performance and user feedback
2. **Plan Updates:** Schedule regular updates and feature additions
3. **Scale Distribution:** Consider additional distribution channels
4. **Community Building:** Engage with users and build community
5. **Feature Development:** Plan next version based on user needs

This deployment pipeline provides a robust foundation for distributing SerenaNet while maintaining security, compliance, and user experience standards.