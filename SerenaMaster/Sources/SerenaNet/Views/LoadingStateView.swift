import SwiftUI

struct LoadingStateView: View {
    let message: String
    let showProgress: Bool
    @State private var progress: Double = 0.0
    
    init(message: String = "Loading...", showProgress: Bool = false) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Loading animation
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle())
            
            // Loading message
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
            
            // Progress bar (optional)
            if showProgress {
                ProgressView(value: progress, total: 1.0)
                    .frame(width: 200)
                    .onAppear {
                        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                            progress = 1.0
                        }
                    }
            }
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct InlineLoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle())
            
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct AIProcessingIndicator: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated brain icon
            Image(systemName: "brain.head.profile")
                .font(.callout)
                .foregroundColor(.accentColor)
                .opacity(0.6 + 0.4 * sin(animationPhase))
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: animationPhase)
            
            Text("AI is thinking...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(Capsule())
        .onAppear {
            animationPhase = .pi * 2
        }
    }
}

struct ModelLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var loadingStage = 0
    @State private var progress: Double = 0.0
    @State private var iconRotation: Double = 0
    @State private var iconScale: Double = 1.0
    @State private var isVisible = false
    
    private let stages = [
        "Initializing AI model...",
        "Loading model weights...",
        "Optimizing for your device...",
        "Almost ready..."
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated model icon
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .scaleEffect(iconScale)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: iconScale
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
                    .rotationEffect(.degrees(iconRotation))
                    .animation(
                        .linear(duration: 4.0)
                        .repeatForever(autoreverses: false),
                        value: iconRotation
                    )
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .animation(AnimationPresets.gentleSpring.delay(0.2), value: isVisible)
            
            VStack(spacing: 12) {
                Text("Setting up SerenaNet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.customColors.primary)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(AnimationPresets.gentleSpring.delay(0.4), value: isVisible)
                
                // Current stage with smooth transition
                Text(stages[loadingStage])
                    .font(.callout)
                    .foregroundColor(themeManager.customColors.secondary)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id("stage-\(loadingStage)")
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(AnimationPresets.gentleSpring.delay(0.6), value: isVisible)
            }
            
            VStack(spacing: 8) {
                // Enhanced progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.customColors.tertiaryBackground)
                        .frame(width: 300, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 300 * progress, height: 8)
                        .animation(AnimationPresets.smoothEase, value: progress)
                }
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(AnimationPresets.gentleSpring.delay(0.8), value: isVisible)
                
                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.customColors.secondary)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(AnimationPresets.gentleSpring.delay(1.0), value: isVisible)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.customColors.surface)
                .shadow(
                    color: .black.opacity(themeManager.effectiveColorScheme == .dark ? 0.4 : 0.1),
                    radius: 20,
                    x: 0,
                    y: 8
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(AnimationPresets.gentleSpring, value: isVisible)
        .onAppear {
            isVisible = true
            iconScale = 1.1
            iconRotation = 360
            simulateLoading()
        }
    }
    
    private func simulateLoading() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.01
            
            // Update stage based on progress
            let newStage = min(Int(progress * Double(stages.count)), stages.count - 1)
            if newStage != loadingStage {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadingStage = newStage
                }
            }
            
            if progress >= 1.0 {
                timer.invalidate()
            }
        }
        timer.fire()
    }
}

struct NetworkStatusView: View {
    @Binding var isOffline: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isOffline ? "wifi.slash" : "wifi")
                .font(.caption)
                .foregroundColor(isOffline ? .orange : .green)
            
            Text(isOffline ? "Offline" : "Online")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isOffline ? .orange : .green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isOffline ? Color.orange : Color.green).opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview("Loading State") {
    LoadingStateView(message: "Initializing AI model...", showProgress: true)
}

#Preview("Inline Loading") {
    VStack {
        InlineLoadingView(message: "Saving conversation...")
        InlineLoadingView()
    }
}

#Preview("AI Processing") {
    AIProcessingIndicator()
}

#Preview("Model Loading") {
    ModelLoadingView()
}

#Preview("Network Status") {
    VStack {
        NetworkStatusView(isOffline: .constant(false))
        NetworkStatusView(isOffline: .constant(true))
    }
}