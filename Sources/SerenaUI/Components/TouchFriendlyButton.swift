import SwiftUI
import SerenaCore
#if canImport(UIKit)
import UIKit
#endif

/// Touch-friendly button component optimized for iPad
public struct TouchFriendlyButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let style: ButtonStyle
    
    @Environment(\.platformConfiguration) private var platformConfig
    
    public enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case minimal
    }
    
    public init(
        _ title: String,
        systemImage: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
        self.style = style
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize))
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: fontSize, weight: fontWeight))
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(TouchFriendlyButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Computed Properties
    
    private var minTouchTarget: CGFloat {
        platformConfig.platform == .iPadOS ? 44 : 32
    }
    
    private var horizontalPadding: CGFloat {
        switch platformConfig.platform {
        case .iPadOS:
            return 20
        case .iOS:
            return 16
        case .macOS:
            return 12
        case .unknown:
            return 12
        }
    }
    
    private var verticalPadding: CGFloat {
        switch platformConfig.platform {
        case .iPadOS:
            return 14
        case .iOS:
            return 12
        case .macOS:
            return 8
        case .unknown:
            return 8
        }
    }
    
    private var fontSize: CGFloat {
        switch platformConfig.platform {
        case .iPadOS:
            return 18
        case .iOS:
            return 16
        case .macOS:
            return 14
        case .unknown:
            return 14
        }
    }
    
    private var iconSize: CGFloat {
        switch platformConfig.platform {
        case .iPadOS:
            return 20
        case .iOS:
            return 18
        case .macOS:
            return 16
        case .unknown:
            return 16
        }
    }
    
    private var fontWeight: Font.Weight {
        switch style {
        case .primary:
            return .semibold
        case .secondary, .minimal:
            return .medium
        case .destructive:
            return .semibold
        }
    }
    
    private var cornerRadius: CGFloat {
        PlatformManager.shared.preferredCornerRadius
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .accentColor
        case .secondary:
            return .gray.opacity(0.2)
        case .destructive:
            return .red
        case .minimal:
            return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        case .minimal:
            return .accentColor
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .minimal:
            return .accentColor.opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        style == .minimal ? 1 : 0
    }
    
    private var accessibilityHint: String {
        switch style {
        case .primary:
            return "Primary action button"
        case .secondary:
            return "Secondary action button"
        case .destructive:
            return "Destructive action button"
        case .minimal:
            return "Minimal action button"
        }
    }
}

/// Custom button style for touch-friendly interactions
struct TouchFriendlyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        TouchFriendlyButton("Primary Button", systemImage: "checkmark") {
            print("Primary tapped")
        }
        
        TouchFriendlyButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }
        
        TouchFriendlyButton("Delete", systemImage: "trash", style: .destructive) {
            print("Delete tapped")
        }
        
        TouchFriendlyButton("Minimal", style: .minimal) {
            print("Minimal tapped")
        }
    }
    .padding()
}