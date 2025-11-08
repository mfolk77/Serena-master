import Foundation
import SwiftUI

/// Protocol for components that need platform-specific adaptations
public protocol PlatformAdaptable {
    /// Adapt the component for the current platform
    func adaptForPlatform(_ platform: PlatformManager.Platform) -> Self
    
    /// Get platform-specific configuration
    var platformConfig: PlatformConfiguration { get }
}

/// Configuration object for platform-specific settings
public struct PlatformConfiguration {
    public let platform: PlatformManager.Platform
    public let inputMethod: PlatformManager.InputMethod
    public let screenSize: CGSize
    public let isCompact: Bool
    
    public init(
        platform: PlatformManager.Platform,
        inputMethod: PlatformManager.InputMethod,
        screenSize: CGSize,
        isCompact: Bool
    ) {
        self.platform = platform
        self.inputMethod = inputMethod
        self.screenSize = screenSize
        self.isCompact = isCompact
    }
    
    public static var current: PlatformConfiguration {
        let platformManager = PlatformManager.shared
        return PlatformConfiguration(
            platform: platformManager.currentPlatform,
            inputMethod: platformManager.primaryInputMethod,
            screenSize: platformManager.screenSize,
            isCompact: platformManager.isCompactWidth
        )
    }
}

/// Protocol for services that need platform-specific implementations
public protocol PlatformSpecificService {
    /// Initialize the service for the current platform
    init(platform: PlatformManager.Platform) throws
    
    /// Check if the service is available on the current platform
    static func isAvailable(on platform: PlatformManager.Platform) -> Bool
}

/// Protocol for views that adapt their layout based on platform
public protocol ResponsiveView: View {
    /// The compact layout for small screens/mobile
    @ViewBuilder var compactLayout: Self { get }
    
    /// The regular layout for larger screens/desktop
    @ViewBuilder var regularLayout: Self { get }
    
    /// The current layout based on platform and screen size
    associatedtype AdaptiveLayoutView: View
    @ViewBuilder var adaptiveLayout: AdaptiveLayoutView { get }
}

public extension ResponsiveView {
    @ViewBuilder
    var adaptiveLayout: some View {
        if PlatformManager.shared.isCompactWidth {
            compactLayout
        } else {
            regularLayout
        }
    }
}

/// Protocol for components that handle touch vs mouse input differently
public protocol InputAdaptable {
    /// Handle touch-based input (iOS/iPadOS)
    func handleTouchInput(_ gesture: TouchGesture)
    
    /// Handle mouse-based input (macOS)
    func handleMouseInput(_ event: MouseEvent)
    
    /// Handle keyboard input (all platforms)
    func handleKeyboardInput(_ event: KeyboardEvent)
}

public struct TouchGesture {
    public let type: TouchType
    public let location: CGPoint
    public let force: CGFloat?
    
    public enum TouchType {
        case tap
        case longPress
        case swipe(direction: SwipeDirection)
        case pinch(scale: CGFloat)
        case pan(translation: CGSize)
    }
    
    public enum SwipeDirection {
        case up, down, left, right
    }
}

public struct MouseEvent {
    public let type: MouseType
    public let location: CGPoint
    public let clickCount: Int
    
    public enum MouseType {
        case leftClick
        case rightClick
        case hover
        case drag
    }
}

public struct KeyboardEvent {
    public let key: String
    public let modifiers: KeyModifiers
    public let type: KeyEventType
    
    public struct KeyModifiers: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let command = KeyModifiers(rawValue: 1 << 0)
        public static let shift = KeyModifiers(rawValue: 1 << 1)
        public static let option = KeyModifiers(rawValue: 1 << 2)
        public static let control = KeyModifiers(rawValue: 1 << 3)
    }
    
    public enum KeyEventType {
        case keyDown
        case keyUp
    }
}