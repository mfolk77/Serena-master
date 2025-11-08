import XCTest
@testable import SerenaCore

final class PlatformManagerTests: XCTestCase {
    
    func testPlatformDetection() {
        let platformManager = PlatformManager.shared
        
        // Test that we can detect the current platform
        let platform = platformManager.currentPlatform
        XCTAssertNotEqual(platform, .unknown)
        
        // Test platform-specific properties
        switch platform {
        case .macOS:
            XCTAssertTrue(platformManager.isDesktop)
            XCTAssertFalse(platformManager.isMobile)
            XCTAssertFalse(platformManager.isTablet)
        case .iOS:
            XCTAssertFalse(platformManager.isDesktop)
            XCTAssertTrue(platformManager.isMobile)
            XCTAssertFalse(platformManager.isTablet)
        case .iPadOS:
            XCTAssertFalse(platformManager.isDesktop)
            XCTAssertFalse(platformManager.isMobile)
            XCTAssertTrue(platformManager.isTablet)
        case .unknown:
            break
        }
    }
    
    func testFeatureAvailability() {
        let platformManager = PlatformManager.shared
        
        // Test that voice input is available on all platforms
        XCTAssertTrue(platformManager.voiceInputAvailable)
        
        // Test platform-specific features
        if platformManager.isTablet {
            XCTAssertTrue(platformManager.supportsMultitasking)
            XCTAssertTrue(platformManager.supportsTouchInput)
            XCTAssertTrue(platformManager.supportsKeyboardShortcuts)
        }
        
        if platformManager.isDesktop {
            XCTAssertTrue(platformManager.supportsKeyboardShortcuts)
            XCTAssertTrue(platformManager.supportsHoverEffects)
        }
    }
    
    func testUIAdaptations() {
        let platformManager = PlatformManager.shared
        
        // Test that UI preferences are reasonable
        let sidebarWidth = platformManager.preferredSidebarWidth
        XCTAssertGreaterThan(sidebarWidth, 200)
        XCTAssertLessThan(sidebarWidth, 400)
        
        let messageWidth = platformManager.preferredMessageBubbleMaxWidth
        XCTAssertGreaterThan(messageWidth, 300)
        
        let cornerRadius = platformManager.preferredCornerRadius
        XCTAssertGreaterThan(cornerRadius, 0)
        XCTAssertLessThan(cornerRadius, 20)
    }
    
    func testPlatformConfiguration() {
        let config = PlatformConfiguration.current
        
        XCTAssertNotEqual(config.platform, .unknown)
        XCTAssertGreaterThan(config.screenSize.width, 0)
        XCTAssertGreaterThan(config.screenSize.height, 0)
    }
    
    func testFeatureFlags() {
        let platformManager = PlatformManager.shared
        
        // Test that feature flags work correctly
        let voiceEnabled = platformManager.isFeatureEnabled(.voiceInput)
        XCTAssertTrue(voiceEnabled) // Should be available on all platforms
        
        let contextMenus = platformManager.isFeatureEnabled(.contextMenus)
        XCTAssertTrue(contextMenus) // Should be available on all platforms
        
        // Platform-specific features
        if platformManager.isTablet {
            let splitView = platformManager.isFeatureEnabled(.splitView)
            XCTAssertTrue(splitView)
            
            let multitasking = platformManager.isFeatureEnabled(.multitasking)
            XCTAssertTrue(multitasking)
        }
    }
    
    func testInputMethods() {
        let platformManager = PlatformManager.shared
        let inputMethod = platformManager.primaryInputMethod
        
        switch platformManager.currentPlatform {
        case .macOS:
            XCTAssertEqual(inputMethod, .keyboardMouse)
        case .iOS:
            XCTAssertEqual(inputMethod, .touch)
        case .iPadOS:
            XCTAssertEqual(inputMethod, .touchKeyboard)
        case .unknown:
            break
        }
    }
    
    func testPerformanceSettings() {
        let platformManager = PlatformManager.shared
        
        let maxOperations = platformManager.maxConcurrentOperations
        XCTAssertGreaterThan(maxOperations, 0)
        XCTAssertLessThan(maxOperations, 20)
        
        let imageQuality = platformManager.preferredImageQuality
        XCTAssertNotNil(imageQuality)
    }
}