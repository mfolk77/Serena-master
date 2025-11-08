import SwiftUI

struct TypingIndicatorView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animationPhase = 0.0
    @State private var isVisible = false
    @State private var pulseScale = 1.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Assistant avatar with pulse animation
            Circle()
                .fill(themeManager.accentColor.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.accentColor)
                )
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(AnimationPresets.quickSpring.delay(0.1), value: isVisible)
            
            VStack(alignment: .leading, spacing: 6) {
                // Typing bubble with animated dots
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.8))
                                .frame(width: 6, height: 6)
                                .scaleEffect(dotScale(for: index))
                                .animation(
                                    .easeInOut(duration: 0.8)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: animationPhase
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(themeManager.effectiveColorScheme == .dark ?
                                  Color(NSColor.controlBackgroundColor) :
                                  themeManager.customColors.surface)
                            .shadow(
                                color: .black.opacity(themeManager.effectiveColorScheme == .dark ? 0.3 : 0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    )
                    .scaleEffect(isVisible ? 1.0 : 0.9)
                    .animation(AnimationPresets.messageAppear.delay(0.2), value: isVisible)
                    
                    Spacer()
                }
                
                // Status text with animated ellipsis
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.accentColor)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(AnimationPresets.quickSpring.delay(0.4), value: isVisible)
                    
                    Text("SerenaNet is thinking")
                        .font(.caption2)
                        .foregroundColor(themeManager.customColors.secondary)
                        .opacity(isVisible ? 0.8 : 0.0)
                        .animation(AnimationPresets.quickSpring.delay(0.3), value: isVisible)
                    
                    // Animated ellipsis
                    HStack(spacing: 1) {
                        ForEach(0..<3) { index in
                            Text(".")
                                .font(.caption2)
                                .foregroundColor(themeManager.customColors.secondary)
                                .opacity(ellipsisOpacity(for: index))
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever()
                                    .delay(Double(index) * 0.3),
                                    value: animationPhase
                                )
                        }
                    }
                    .opacity(isVisible ? 0.8 : 0.0)
                    .animation(AnimationPresets.quickSpring.delay(0.5), value: isVisible)
                }
                .padding(.horizontal, 4)
            }
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(AnimationPresets.messageAppear) {
                isVisible = true
                animationPhase = 1.0
                pulseScale = 1.1
            }
        }
        .onDisappear {
            isVisible = false
            animationPhase = 0.0
            pulseScale = 1.0
        }
    }
    
    private func dotScale(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
        return 0.6 + 0.4 * sin(phase * .pi * 2)
    }
    
    private func ellipsisOpacity(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 0.33).truncatingRemainder(dividingBy: 1.0)
        return 0.3 + 0.7 * sin(phase * .pi * 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        TypingIndicatorView()
        
        // Show alongside a user message for context
        HStack {
            Spacer(minLength: 60)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Can you help me with Swift programming?")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Text("You • now")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        
        TypingIndicatorView()
    }
    .padding()
    .frame(width: 600)
}