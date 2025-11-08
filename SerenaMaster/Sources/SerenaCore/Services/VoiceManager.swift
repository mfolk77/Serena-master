import Foundation
import Speech
import AVFoundation
import Combine

#if os(macOS)
import AppKit
#endif

/// Manages voice input functionality using SFSpeechRecognizer
@MainActor
class VoiceManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording: Bool = false
    @Published var transcription: String = ""
    @Published var isProcessing: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var permissionStatus: VoicePermissionStatus = .notDetermined
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioLevelTimer: Timer?
    
    // Voice processing and optimization
    private var noiseReductionNode: AVAudioUnitEQ?
    private var voiceSettings: VoiceSettings
    
    // Voice commands
    private let voiceCommands: [String: VoiceCommand] = [
        "stop": .stop,
        "cancel": .cancel,
        "send": .send,
        "clear": .clear,
        "new conversation": .newConversation,
        "settings": .openSettings
    ]
    
    // Performance monitoring
    private let performanceMonitor = PerformanceMonitor.shared
    
    // MARK: - Initialization
    init(voiceSettings: VoiceSettings = .default) {
        self.voiceSettings = voiceSettings
        
        // Initialize with configured locale, fallback to English
        let locale = Locale(identifier: voiceSettings.language)
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Check initial permission status
        Task {
            await updatePermissionStatus()
        }
    }
    
    // MARK: - Permission Management
    func requestPermissions() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await requestSpeechRecognitionPermission()
        
        // Request microphone permission
        let microphoneStatus = await requestMicrophonePermission()
        
        let hasPermissions = speechStatus && microphoneStatus
        await updatePermissionStatus()
        
        return hasPermissions
    }
    
    private func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        #if os(macOS)
        // On macOS, microphone permission is handled automatically when accessing audio input
        // We'll check if we can access the audio engine input node
        return true
        #else
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        #endif
    }
    
    private func updatePermissionStatus() async {
        let speechAuth = SFSpeechRecognizer.authorizationStatus()
        
        #if os(macOS)
        // On macOS, we primarily need speech recognition permission
        // Microphone access is handled by the system when needed
        if speechAuth == .authorized {
            permissionStatus = .authorized
        } else if speechAuth == .denied {
            permissionStatus = .denied
        } else if speechAuth == .restricted {
            permissionStatus = .restricted
        } else {
            permissionStatus = .notDetermined
        }
        #else
        let micAuth = AVAudioSession.sharedInstance().recordPermission
        
        if speechAuth == .authorized && micAuth == .granted {
            permissionStatus = .authorized
        } else if speechAuth == .denied || micAuth == .denied {
            permissionStatus = .denied
        } else if speechAuth == .restricted {
            permissionStatus = .restricted
        } else {
            permissionStatus = .notDetermined
        }
        #endif
    }
    
    // MARK: - Voice Recording
    func startRecording() async throws {
        guard permissionStatus == .authorized else {
            throw SerenaError.voicePermissionDenied
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SerenaError.voiceRecognitionUnavailable
        }
        
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        try configureAudioSession()
        
        // Setup audio processing
        setupNoiseReduction()
        optimizeForMicrophoneType()
        optimizePerformance()
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SerenaError.voiceRecognitionSetupFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure for better accuracy
        if #available(macOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = true // Use on-device processing when available
        }
        
        // Start audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Connect audio nodes if noise reduction is enabled
        if voiceSettings.noiseReductionEnabled {
            connectAudioNodes()
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for visual feedback
            self?.updateAudioLevel(from: buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    self?.transcription = transcribedText
                    self?.isProcessing = !result.isFinal
                    
                    // Process voice commands if enabled
                    if let voiceCommand = self?.processVoiceCommand(in: transcribedText) {
                        await self?.handleVoiceCommand(voiceCommand)
                    }
                }
                
                if let error = error {
                    print("Speech recognition error: \(error)")
                    _ = await self?.stopRecording()
                }
            }
        }
        
        isRecording = true
        isProcessing = true
        transcription = ""
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
    }
    
    func stopRecording() async -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Disconnect audio nodes if they were connected
        if let eqNode = noiseReductionNode {
            audioEngine.disconnectNodeInput(eqNode)
            audioEngine.detach(eqNode)
            noiseReductionNode = nil
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        isProcessing = false
        
        stopAudioLevelMonitoring()
        
        let finalTranscription = transcription
        transcription = ""
        
        return finalTranscription
    }
    
    // MARK: - Voice Command Handling
    
    private func handleVoiceCommand(_ command: VoiceCommand) async {
        // This method would typically notify a delegate or use a callback
        // For now, we'll just handle commands that can be processed internally
        
        switch command {
        case .stop, .cancel:
            _ = await stopRecording()
        case .clear:
            transcription = ""
        case .send, .newConversation, .openSettings:
            // These commands would be handled by the ChatManager or UI
            // We'll just stop recording for now
            _ = await stopRecording()
        }
    }
    
    // MARK: - Audio Configuration
    private func configureAudioSession() throws {
        #if os(macOS)
        // On macOS, audio configuration is handled automatically by AVAudioEngine
        // No explicit session configuration needed
        #else
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
    }
    
    // MARK: - Audio Level Monitoring
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        
        Task { @MainActor in
            self.audioLevel = rms
        }
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Audio level is updated in updateAudioLevel method
            // This timer ensures regular updates even if audio is quiet
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioLevel = 0.0
    }
    
    // MARK: - Voice Settings
    
    func updateSettings(_ newSettings: VoiceSettings) {
        voiceSettings = newSettings
        
        // Update speech recognizer if language changed
        if voiceSettings.language != voiceSettings.language {
            // Note: This would require reinitializing the speech recognizer
            // For now, we'll just store the setting for next initialization
        }
    }
    
    var currentSettings: VoiceSettings {
        return voiceSettings
    }
    
    // MARK: - Voice Commands
    
    private func processVoiceCommand(in text: String) -> VoiceCommand? {
        guard voiceSettings.voiceCommandsEnabled else { return nil }
        
        let lowercaseText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for (command, voiceCommand) in voiceCommands {
            if lowercaseText.contains(command) {
                return voiceCommand
            }
        }
        
        return nil
    }
    
    func getAvailableCommands() -> [VoiceCommand] {
        return Array(voiceCommands.values)
    }
    
    // MARK: - Audio Processing
    
    private func setupNoiseReduction() {
        guard voiceSettings.noiseReductionEnabled else { return }
        
        noiseReductionNode = AVAudioUnitEQ(numberOfBands: 3)
        guard let eqNode = noiseReductionNode else { return }
        
        // Configure EQ for voice enhancement
        // Band 0: High-pass filter to reduce low-frequency noise
        eqNode.bands[0].frequency = 80
        eqNode.bands[0].gain = -6
        eqNode.bands[0].bandwidth = 0.5
        eqNode.bands[0].filterType = .highPass
        
        // Band 1: Boost voice frequencies (300-3000 Hz)
        eqNode.bands[1].frequency = 1000
        eqNode.bands[1].gain = 3
        eqNode.bands[1].bandwidth = 2.0
        eqNode.bands[1].filterType = .parametric
        
        // Band 2: Reduce high-frequency noise
        eqNode.bands[2].frequency = 8000
        eqNode.bands[2].gain = -3
        eqNode.bands[2].bandwidth = 1.0
        eqNode.bands[2].filterType = .lowPass
        
        audioEngine.attach(eqNode)
    }
    
    private func connectAudioNodes() {
        guard let eqNode = noiseReductionNode else { return }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // Connect: Input -> EQ -> Main Mixer
        audioEngine.connect(inputNode, to: eqNode, format: format)
        audioEngine.connect(eqNode, to: audioEngine.mainMixerNode, format: format)
    }
    
    // MARK: - Microphone Optimization
    
    private func optimizeForMicrophoneType() {
        // Detect and optimize for different microphone types
        // This is a simplified implementation for macOS
        
        #if os(macOS)
        // On macOS, microphone optimization is handled by the system
        // We can adjust our processing based on the voice settings
        #endif
        
        // Adjust sensitivity based on settings
        // Note: Direct microphone gain control is hardware-dependent
        // and may not be available on all devices
    }
    
    // MARK: - Performance Optimization
    
    func optimizePerformance() {
        // Optimize audio processing for better performance
        audioEngine.mainMixerNode.outputVolume = 0.0 // We don't need audio output
        
        // Note: Audio format optimization is handled automatically by the system
        // on macOS for speech recognition. Manual format changes may not be
        // supported on all devices and could cause compatibility issues.
    }
}

// MARK: - Supporting Types
enum VoicePermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    
    var description: String {
        switch self {
        case .notDetermined:
            return "Permission not requested"
        case .authorized:
            return "Permission granted"
        case .denied:
            return "Permission denied"
        case .restricted:
            return "Permission restricted"
        }
    }
}



enum VoiceCommand: String, CaseIterable {
    case stop = "stop"
    case cancel = "cancel"
    case send = "send"
    case clear = "clear"
    case newConversation = "new conversation"
    case openSettings = "settings"
    
    var description: String {
        switch self {
        case .stop:
            return "Stop recording"
        case .cancel:
            return "Cancel current input"
        case .send:
            return "Send message"
        case .clear:
            return "Clear input"
        case .newConversation:
            return "Start new conversation"
        case .openSettings:
            return "Open settings"
        }
    }
}