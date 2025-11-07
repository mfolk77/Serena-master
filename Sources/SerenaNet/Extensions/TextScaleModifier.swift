import SwiftUI

/// Environment key for text size multiplier
struct TextSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var textSizeMultiplier: Double {
        get { self[TextSizeMultiplierKey.self] }
        set { self[TextSizeMultiplierKey.self] = newValue }
    }
}

/// View modifier that applies dynamic font sizing based on user preferences
struct DynamicFontModifier: ViewModifier {
    @Environment(\.textSizeMultiplier) var multiplier
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content
            .font(.system(size: baseSize * multiplier, weight: weight, design: design))
    }
}

/// Extension to make it easy to apply dynamic font sizing
extension Text {
    func dynamicFont(size: CGFloat = 14, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(DynamicFontModifier(baseSize: size, weight: weight, design: design))
    }
}
