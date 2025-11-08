import Foundation
import SwiftUI
import SerenaCore

/// Main UI module for SerenaNet
public struct SerenaUI {
    public static let version = "1.0.0"
}

/// Platform-aware view modifier
public struct PlatformAware: ViewModifier {
    private let platformManager = PlatformManager.shared
    
    public func body(content: Content) -> some View {
        content
            .environment(\.platformConfiguration, PlatformConfiguration.current)
    }
}

public extension View {
    func platformAware() -> some View {
        modifier(PlatformAware())
    }
}

/// Environment key for platform configuration
private struct PlatformConfigurationKey: EnvironmentKey {
    static let defaultValue = PlatformConfiguration.current
}

public extension EnvironmentValues {
    var platformConfiguration: PlatformConfiguration {
        get { self[PlatformConfigurationKey.self] }
        set { self[PlatformConfigurationKey.self] = newValue }
    }
}