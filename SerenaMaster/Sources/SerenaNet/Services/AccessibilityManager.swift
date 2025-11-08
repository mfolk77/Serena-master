import SwiftUI
import AppKit

@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverEnabled = false
    @Published var isReduceMotionEnabled = false
    @Published var isIncreaseContrastEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    
    private init() {
        setupAccessibilityObservers()
        updateAccessibilitySettings()
    }
    
    // MARK: - Accessibility Settings
    
    private func updateAccessibilitySettings() {
        isVoiceOverEnabled = NSWorkspace.shared.isVoiceOverEnabled
        isReduceMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        isIncreaseContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        
        // Update content size category based on system settings
        updateContentSizeCategory()
    }
    
    private func updateContentSizeCategory() {
        // Map system text size to SwiftUI ContentSizeCategory
        let systemTextSize = NSFont.systemFontSize
        
        switch systemTextSize {
        case ...11:
            preferredContentSizeCategory = .extraSmall
        case 12:
            preferredContentSizeCategory = .small
        case 13:
            preferredContentSizeCategory = .medium
        case 14:
            preferredContentSizeCategory = .large
        case 15:
            preferredContentSizeCategory = .extraLarge
        case 16:
            preferredContentSizeCategory = .extraExtraLarge
        default:
            preferredContentSizeCategory = .extraExtraExtraLarge
        }
    }
    
    // MARK: - Accessibility Helpers
    
    func announceMessage(_ message: String) {
        guard isVoiceOverEnabled else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: [.announcement: message]
            )
        }
    }
    
    func announceAIResponse(_ response: String) {
        let announcement = "AI response: \(response.prefix(100))\(response.count > 100 ? "..." : "")"
        announceMessage(announcement)
    }
    
    func announceVoiceInputStart() {
        announceMessage("Voice input started. Speak now.")
    }
    
    func announceVoiceInputEnd(_ transcription: String) {
        let announcement = transcription.isEmpty ? 
            "Voice input ended. No speech detected." :
            "Voice input transcribed: \(transcription)"
        announceMessage(announcement)
    }
    
    func announceError(_ error: String) {
        announceMessage("Error: \(error)")
    }
    
    // MARK: - Animation Helpers
    
    var shouldReduceMotion: Bool {
        return isReduceMotionEnabled
    }
    
    func adaptedAnimation<V>(_ animation: Animation, value: V) -> Animation where V: Equatable {
        return shouldReduceMotion ? Animation.linear(duration: 0) : animation
    }
    
    func adaptedTransition(_ transition: AnyTransition) -> AnyTransition {
        return shouldReduceMotion ? .opacity : transition
    }
    
    // MARK: - Color Helpers
    
    func adaptedColor(_ color: Color) -> Color {
        if isIncreaseContrastEnabled {
            // Increase contrast by adjusting opacity and saturation
            return color.opacity(0.9)
        }
        return color
    }
    
    func adaptedBackgroundColor(_ color: Color) -> Color {
        if isIncreaseContrastEnabled {
            // Make backgrounds more distinct
            return color.opacity(0.95)
        }
        return color
    }
    
    // MARK: - Text Helpers
    
    func adaptedFont(_ font: Font) -> Font {
        // Adjust font based on content size category
        switch preferredContentSizeCategory {
        case .extraSmall, .small:
            return font
        case .medium:
            return font
        case .large:
            return font.weight(.medium)
        case .extraLarge, .extraExtraLarge:
            return font.weight(.semibold)
        default:
            return font.weight(.bold)
        }
    }
    
    // MARK: - Observers
    
    private func setupAccessibilityObservers() {
        // VoiceOver state changes
        DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateAccessibilitySettings() }
        }
        
        // Reduce motion changes
        DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleReduceDesktopTinting"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateAccessibilitySettings() }
        }
        
        // System font size changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateContentSizeCategory() }
        }
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - View Extensions
extension View {
    func accessibilityAdapted() -> some View {
        let accessibilityManager = AccessibilityManager.shared
        
        return self
            .dynamicTypeSize(accessibilityManager.preferredContentSizeCategory.dynamicTypeSize)
            .accessibilityShowsLargeContentViewer()
    }
    
    func accessibilityMessage(_ message: String) -> some View {
        self.accessibilityLabel(message)
            .accessibilityAddTraits(.isStaticText)
    }
    
    func accessibilityButton(_ label: String, hint: String? = nil) -> some View {
        self.accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint ?? "")
    }
    
    func accessibilityTextInput(_ label: String, value: String) -> some View {
        self.accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityAddTraits(.isSearchField)
    }
}

// MARK: - ContentSizeCategory Extension
extension ContentSizeCategory {
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .extraSmall:
            return .xSmall
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .extraLarge:
            return .xLarge
        case .extraExtraLarge:
            return .xxLarge
        case .extraExtraExtraLarge:
            return .xxxLarge
        default:
            return .medium
        }
    }
}