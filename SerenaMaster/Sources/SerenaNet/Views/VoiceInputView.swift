import SwiftUI

struct VoiceInputView: View {
    @ObservedObject var voiceManager: VoiceManager
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation: Bool = false
    
    let onTranscriptionComplete: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Voice recording button with visual feedback
            Button(action: {
                Task {
                    if voiceManager.isRecording {
                        let transcription = await voiceManager.stopRecording()
                        if !transcription.isEmpty {
                            onTranscriptionComplete(transcription)
                        }
                    } else {
                        await startVoiceInput()
                    }
                }
            }) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(voiceManager.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    // Microphone icon
                    Image(systemName: voiceManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(voiceManager.permissionStatus != .authorized)
            
            // Audio level indicator
            if voiceManager.isRecording {
                AudioLevelIndicator(level: voiceManager.audioLevel)
                    .frame(height: 20)
                    .padding(.horizontal)
            }
            
            // Status text
            VStack(spacing: 4) {
                if voiceManager.isRecording {
                    if voiceManager.isProcessing {
                        Text("Listening...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Processing...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    switch voiceManager.permissionStatus {
                    case .authorized:
                        Text("Tap to speak")
                            .font(.headline)
                            .foregroundColor(.primary)
                    case .denied:
                        Text("Microphone access denied")
                            .font(.headline)
                            .foregroundColor(.red)
                    case .restricted:
                        Text("Microphone access restricted")
                            .font(.headline)
                            .foregroundColor(.orange)
                    case .notDetermined:
                        Text("Microphone permission needed")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Permission help text
                if voiceManager.permissionStatus != .authorized {
                    Text("Enable microphone access in System Preferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Live transcription preview
            if voiceManager.isRecording && !voiceManager.transcription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(voiceManager.transcription)
                        .font(.body)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: voiceManager.isRecording) { isRecording in
            if isRecording {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }
    
    private func startVoiceInput() async {
        // Request permissions if needed
        if voiceManager.permissionStatus != .authorized {
            let granted = await voiceManager.requestPermissions()
            if !granted {
                return
            }
        }
        
        // Start recording
        do {
            try await voiceManager.startRecording()
        } catch {
            print("Failed to start voice recording: \(error)")
        }
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
        animationScale = voiceManager.isRecording ? 1.2 : 1.0
    }
    
    private func stopPulseAnimation() {
        pulseAnimation = false
        animationScale = 1.0
    }
}

struct AudioLevelIndicator: View {
    let level: Float
    private let barCount = 20
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 3)
                    .frame(height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let normalizedLevel = min(max(level * 10, 0), 1) // Scale and clamp
        let threshold = Float(index) / Float(barCount)
        
        if normalizedLevel > threshold {
            return 20
        } else {
            return 4
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let normalizedLevel = min(max(level * 10, 0), 1)
        let threshold = Float(index) / Float(barCount)
        
        if normalizedLevel > threshold {
            if threshold < 0.6 {
                return .green
            } else if threshold < 0.8 {
                return .yellow
            } else {
                return .red
            }
        } else {
            return .gray.opacity(0.3)
        }
    }
}

#Preview {
    VoiceInputView(voiceManager: VoiceManager()) { transcription in
        print("Transcription: \(transcription)")
    }
}