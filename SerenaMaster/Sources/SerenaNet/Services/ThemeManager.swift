import SwiftUI
import AppKit

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var effectiveColorScheme: ColorScheme = .light
    @Published var accentColor: Color = .blue
    @Published var customColors: CustomColors = CustomColors()
    
    private var systemAppearanceObserver: NSKeyValueObservation?
    
    private init() {
        setupSystemAppearanceObserver()
        updateEffectiveColorScheme()
    }
    
    // MARK: - Theme Management
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        updateEffectiveColorScheme()
        applyThemeToSystem()
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
        updateCustomColors()
    }
    
    private func updateEffectiveColorScheme() {
        switch currentTheme {
        case .light:
            effectiveColorScheme = .light
        case .dark:
            effectiveColorScheme = .dark
        case .system:
            effectiveColorScheme = NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light
        }
        
        updateCustomColors()
    }
    
    private func updateCustomColors() {
        customColors = CustomColors(
            colorScheme: effectiveColorScheme,
            accentColor: accentColor
        )
    }
    
    private func applyThemeToSystem() {
        switch currentTheme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }
    
    // MARK: - System Appearance Observer
    
    private func setupSystemAppearanceObserver() {
        systemAppearanceObserver = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateEffectiveColorScheme()
            }
        }
    }
    
    deinit {
        systemAppearanceObserver?.invalidate()
    }
}

// MARK: - Custom Colors
struct CustomColors {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let background: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let surface: Color
    let border: Color
    let separator: Color
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    init(colorScheme: ColorScheme = .light, accentColor: Color = .blue) {
        self.accent = accentColor
        
        if colorScheme == .dark {
            // Dark theme colors
            primary = Color(NSColor.labelColor)
            secondary = Color(NSColor.secondaryLabelColor)
            tertiary = Color(NSColor.tertiaryLabelColor)
            background = Color(NSColor.windowBackgroundColor)
            secondaryBackground = Color(NSColor.controlBackgroundColor)
            tertiaryBackground = Color(NSColor.underPageBackgroundColor)
            surface = Color(NSColor.controlBackgroundColor)
            border = Color(NSColor.separatorColor)
            separator = Color(NSColor.separatorColor)
            success = Color.green
            warning = Color.orange
            error = Color.red
            info = accentColor
        } else {
            // Light theme colors
            primary = Color(NSColor.labelColor)
            secondary = Color(NSColor.secondaryLabelColor)
            tertiary = Color(NSColor.tertiaryLabelColor)
            background = Color(NSColor.windowBackgroundColor)
            secondaryBackground = Color(NSColor.controlBackgroundColor)
            tertiaryBackground = Color(NSColor.underPageBackgroundColor)
            surface = Color.white
            border = Color(NSColor.separatorColor)
            separator = Color(NSColor.separatorColor)
            success = Color.green
            warning = Color.orange
            error = Color.red
            info = accentColor
        }
    }
}

// MARK: - Animation Presets
struct AnimationPresets {
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let gentleSpring = Animation.spring(response: 0.7, dampingFraction: 0.9, blendDuration: 0)
    
    static let quickEase = Animation.easeInOut(duration: 0.2)
    static let smoothEase = Animation.easeInOut(duration: 0.3)
    static let gentleEase = Animation.easeInOut(duration: 0.5)
    
    static let messageAppear = Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    static let sidebarToggle = Animation.easeInOut(duration: 0.25)
    static let settingsTransition = Animation.easeInOut(duration: 0.3)
    static let errorShake = Animation.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0)
}

// MARK: - View Extensions
extension View {
    func themedBackground() -> some View {
        self.background(ThemeManager.shared.customColors.background)
    }
    
    func themedSurface() -> some View {
        self.background(ThemeManager.shared.customColors.surface)
    }
    
    func themedBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ThemeManager.shared.customColors.border, lineWidth: 1)
        )
    }
    
    func animatedAppearance() -> some View {
        self.transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }
    
    func messageTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }
}

// MARK: - Environment Values
@preconcurrency private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}