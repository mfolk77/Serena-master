import SwiftUI
import SerenaCore
#if canImport(UIKit)
import UIKit
#endif

/// iPad-optimized voice input interface with touch-friendly controls
public struct TouchVoiceInputView: View {
    @Binding var isRecording: Bool
    @Binding var transcription: String
    
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onSendTranscription: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.platformConfiguration) private var platformConfig
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.1, count: 20)
    @State private var animationTimer: Timer?
    
    public init(
        isRecording: Binding<Bool>,
        transcription: Binding<String>,
        onStartRecording: @escaping () -> Void,
        onStopRecording: @escaping () -> Void,
        onSendTranscription: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._isRecording = isRecording
        self._transcription = transcription
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording
        self.onSendTranscription = onSendTranscription
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            headerView
            
            // Audio visualization
            audioVisualizationView
            
            // Transcription display
            transcriptionView
            
            // Control buttons
            controlButtonsView
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(radius: 20)
        )
        .frame(maxWidth: maxWidth)
        .onAppear {
            startAudioAnimation()
        }
        .onDisappear {
            stopAudioAnimation()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .font(.system(size: 32))
                .foregroundColor(isRecording ? .red : .accentColor)
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isRecording)
            
            Text(isRecording ? "Listening..." : "Voice Input")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isRecording {
                Text("Tap the microphone to stop")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var audioVisualizationView: some View {
        HStack(spacing: 4) {
            ForEach(0..<audioLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isRecording ? .red : .gray)
                    .frame(width: 4, height: max(4, audioLevels[index] * 40))
                    .animation(.easeInOut(duration: 0.1), value: audioLevels[index])
            }
        }
        .frame(height: 50)
        .opacity(isRecording ? 1.0 : 0.3)
    }
    
    @ViewBuilder
    private var transcriptionView: some View {
        ScrollView {
            Text(transcription.isEmpty ? "Your speech will appear here..." : transcription)
                .font(.body)
                .foregroundColor(transcription.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.1))
                )
        }
        .frame(minHeight: 100, maxHeight: 200)
    }
    
    @ViewBuilder
    private var controlButtonsView: some View {
        HStack(spacing: 16) {
            // Cancel button
            TouchFriendlyButton(
                "Cancel",
                systemImage: "xmark",
                style: .secondary
            ) {
                onCancel()
            }
            .frame(maxWidth: .infinity)
            
            // Record/Stop button
            TouchFriendlyButton(
                isRecording ? "Stop" : "Record",
                systemImage: isRecording ? "stop.fill" : "mic.fill",
                style: isRecording ? .destructive : .primary
            ) {
                if isRecording {
                    onStopRecording()
                } else {
                    onStartRecording()
                }
            }
            .frame(maxWidth: .infinity)
            
            // Send button (only visible when there's transcription)
            if !transcription.isEmpty {
                TouchFriendlyButton(
                    "Send",
                    systemImage: "paperplane.fill",
                    style: .primary
                ) {
                    onSendTranscription()
                }
                .frame(maxWidth: .infinity)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: transcription.isEmpty)
    }
    
    // MARK: - Computed Properties
    
    private var maxWidth: CGFloat {
        switch platformConfig.platform {
        case .iPadOS:
            return 500
        case .iOS:
            return 350
        case .macOS:
            return 400
        case .unknown:
            return 400
        }
    }
    
    // MARK: - Audio Animation
    
    private func startAudioAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isRecording {
                // Simulate audio levels with random values
                for index in audioLevels.indices {
                    audioLevels[index] = CGFloat.random(in: 0.1...1.0)
                }
            } else {
                // Fade to baseline when not recording
                for index in audioLevels.indices {
                    audioLevels[index] = 0.1
                }
            }
        }
    }
    
    private func stopAudioAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

/// Floating voice input button for iPad
public struct FloatingVoiceButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    @Environment(\.platformConfiguration) private var platformConfig
    
    public init(isRecording: Bool, action: @escaping () -> Void) {
        self.isRecording = isRecording
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isRecording ? .red : .accentColor)
                        .shadow(radius: 8)
                )
        }
        .scaleEffect(isRecording ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start voice input")
    }
}

#Preview {
    VStack {
        TouchVoiceInputView(
            isRecording: .constant(false),
            transcription: .constant("This is a sample transcription that shows how the voice input interface looks."),
            onStartRecording: {},
            onStopRecording: {},
            onSendTranscription: {},
            onCancel: {}
        )
        
        Spacer()
        
        HStack {
            Spacer()
            FloatingVoiceButton(isRecording: false) {}
                .padding()
        }
    }
    .padding()
}