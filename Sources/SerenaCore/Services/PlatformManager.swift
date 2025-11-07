import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Platform detection and feature adaptation service
public class PlatformManager {
    public static let shared = PlatformManager()
    
    private init() {}
    
    // MARK: - Platform Detection
    
    public enum Platform {
        case macOS
        case iOS
        case iPadOS
        case unknown
    }
    
    public var currentPlatform: Platform {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPadOS
        } else {
            return .iOS
        }
        #else
        return .unknown
        #endif
    }
    
    public var isDesktop: Bool {
        return currentPlatform == .macOS
    }
    
    public var isMobile: Bool {
        return currentPlatform == .iOS
    }
    
    public var isTablet: Bool {
        return currentPlatform == .iPadOS
    }
    
    // MARK: - Device Capabilities
    
    public var supportsMultitasking: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return true // macOS always supports multitasking
        #endif
    }
    
    public var supportsTouchInput: Bool {
        return isMobile || isTablet
    }
    
    public var supportsKeyboardShortcuts: Bool {
        return isDesktop || isTablet
    }
    
    public var supportsHoverEffects: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return true
        #endif
    }
    
    public var supportsContextMenus: Bool {
        return true // All platforms support context menus
    }
    
    // MARK: - Screen Information
    
    public var screenSize: CGSize {
        #if os(macOS)
        return NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        #elseif os(iOS)
        return UIScreen.main.bounds.size
        #else
        return CGSize(width: 1024, height: 768)
        #endif
    }
    
    public var isCompactWidth: Bool {
        return screenSize.width < 768
    }
    
    public var isCompactHeight: Bool {
        return screenSize.height < 600
    }
    
    // MARK: - Feature Availability
    
    public var voiceInputAvailable: Bool {
        // Voice input is available on all supported platforms
        return true
    }
    
    public var biometricsAvailable: Bool {
        #if os(iOS)
        return true // Touch ID/Face ID available on iOS devices
        #else
        return false // macOS biometrics would need additional implementation
        #endif
    }
    
    public var notificationsAvailable: Bool {
        return true // All platforms support notifications
    }
    
    public var fileSystemAccess: Bool {
        return true // All platforms have some level of file system access
    }
    
    // MARK: - UI Adaptations
    
    public var preferredSidebarWidth: CGFloat {
        switch currentPlatform {
        case .macOS:
            return 280
        case .iPadOS:
            return 320
        case .iOS:
            return min(screenSize.width * 0.8, 300)
        case .unknown:
            return 280
        }
    }
    
    public var preferredMessageBubbleMaxWidth: CGFloat {
        switch currentPlatform {
        case .macOS:
            return 600
        case .iPadOS:
            return min(screenSize.width * 0.7, 500)
        case .iOS:
            return screenSize.width * 0.8
        case .unknown:
            return 600
        }
    }
    
    public var preferredToolbarHeight: CGFloat {
        switch currentPlatform {
        case .macOS:
            return 44
        case .iPadOS:
            return 50
        case .iOS:
            return 44
        case .unknown:
            return 44
        }
    }
    
    public var preferredCornerRadius: CGFloat {
        switch currentPlatform {
        case .macOS:
            return 8
        case .iPadOS:
            return 12
        case .iOS:
            return 10
        case .unknown:
            return 8
        }
    }
    
    // MARK: - Input Methods
    
    public var primaryInputMethod: InputMethod {
        switch currentPlatform {
        case .macOS:
            return .keyboardMouse
        case .iPadOS:
            return .touchKeyboard
        case .iOS:
            return .touch
        case .unknown:
            return .keyboardMouse
        }
    }
    
    public enum InputMethod {
        case touch
        case touchKeyboard
        case keyboardMouse
    }
    
    // MARK: - Performance Considerations
    
    public var shouldUseReducedAnimations: Bool {
        #if os(iOS)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
    
    public var maxConcurrentOperations: Int {
        switch currentPlatform {
        case .macOS:
            return 8
        case .iPadOS:
            return 6
        case .iOS:
            return 4
        case .unknown:
            return 4
        }
    }
    
    public var preferredImageQuality: ImageQuality {
        switch currentPlatform {
        case .macOS:
            return .high
        case .iPadOS:
            return .high
        case .iOS:
            return .medium
        case .unknown:
            return .medium
        }
    }
    
    public enum ImageQuality {
        case low
        case medium
        case high
    }
    
    // MARK: - Layout Preferences
    
    public var shouldUseSplitView: Bool {
        return isDesktop || (isTablet && !isCompactWidth)
    }
    
    public var shouldUseTabBar: Bool {
        return isMobile && isCompactWidth
    }
    
    public var shouldUseNavigationDrawer: Bool {
        return isMobile || (isTablet && isCompactWidth)
    }
    
    public var shouldShowToolbar: Bool {
        return isDesktop || isTablet
    }
    
    // MARK: - Accessibility
    
    public var preferredFontSize: FontSize {
        #if os(iOS)
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        switch contentSize {
        case .extraSmall, .small:
            return .small
        case .medium:
            return .medium
        case .large, .extraLarge:
            return .large
        case .extraExtraLarge, .extraExtraExtraLarge:
            return .extraLarge
        default:
            return .medium
        }
        #else
        return .medium
        #endif
    }
    
    public enum FontSize {
        case small
        case medium
        case large
        case extraLarge
        
        public var pointSize: CGFloat {
            switch self {
            case .small:
                return 12
            case .medium:
                return 14
            case .large:
                return 16
            case .extraLarge:
                return 18
            }
        }
    }
    
    // MARK: - Feature Flags
    
    public func isFeatureEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .voiceInput:
            return voiceInputAvailable
        case .biometrics:
            return biometricsAvailable
        case .splitView:
            return shouldUseSplitView
        case .contextMenus:
            return supportsContextMenus
        case .keyboardShortcuts:
            return supportsKeyboardShortcuts
        case .hoverEffects:
            return supportsHoverEffects
        case .multitasking:
            return supportsMultitasking
        }
    }
    
    public enum Feature {
        case voiceInput
        case biometrics
        case splitView
        case contextMenus
        case keyboardShortcuts
        case hoverEffects
        case multitasking
    }
}