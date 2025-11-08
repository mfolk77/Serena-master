import XCTest
import Speech
import AVFoundation
@testable import SerenaNet

@MainActor
final class VoiceManagerTests: XCTestCase {
    var voiceManager: VoiceManager!
    
    override func setUp() async throws {
        try await super.setUp()
        voiceManager = VoiceManager()
    }
    
    override func tearDown() async throws {
        if voiceManager.isRecording {
            _ = await voiceManager.stopRecording()
        }
        voiceManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertFalse(voiceManager.isRecording)
        XCTAssertEqual(voiceManager.transcription, "")
        XCTAssertFalse(voiceManager.isProcessing)
        XCTAssertEqual(voiceManager.audioLevel, 0.0)
    }
    
    // MARK: - Permission Tests
    
    func testPermissionStatusInitialization() {
        // Permission status should be one of the valid states
        let validStatuses: [VoicePermissionStatus] = [.notDetermined, .authorized, .denied, .restricted]
        XCTAssertTrue(validStatuses.contains(voiceManager.permissionStatus))
    }
    
    func testRequestPermissions() async {
        // Note: This test will depend on system permissions
        // In a real test environment, you might want to mock the permission system
        let result = await voiceManager.requestPermissions()
        
        // The result depends on system state, but the method should complete
        XCTAssertTrue(result == true || result == false)
        
        // Permission status should be updated after request
        XCTAssertTrue([.authorized, .denied, .restricted].contains(voiceManager.permissionStatus))
    }
    
    // MARK: - Recording State Tests
    
    func testRecordingStateManagement() async throws {
        // Skip if permissions not available
        guard voiceManager.permissionStatus == .authorized else {
            throw XCTSkip("Voice permissions not available for testing")
        }
        
        // Initially not recording
        XCTAssertFalse(voiceManager.isRecording)
        
        // Start recording
        try await voiceManager.startRecording()
        XCTAssertTrue(voiceManager.isRecording)
        XCTAssertTrue(voiceManager.isProcessing)
        
        // Stop recording
        let transcription = await voiceManager.stopRecording()
        XCTAssertFalse(voiceManager.isRecording)
        XCTAssertFalse(voiceManager.isProcessing)
        XCTAssertNotNil(transcription) // Should return a string, even if empty
    }
    
    func testStartRecordingWithoutPermissions() async {
        // Create a voice manager that we know doesn't have permissions
        let unauthorizedManager = VoiceManager()
        
        // Manually set permission status to denied for testing
        // Note: In a real implementation, you might need to mock this
        
        do {
            try await unauthorizedManager.startRecording()
            XCTFail("Should have thrown an error for missing permissions")
        } catch SerenaError.voicePermissionDenied {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Audio Level Tests
    
    func testAudioLevelInitialization() {
        XCTAssertEqual(voiceManager.audioLevel, 0.0)
    }
    
    func testAudioLevelDuringRecording() async throws {
        guard voiceManager.permissionStatus == .authorized else {
            throw XCTSkip("Voice permissions not available for testing")
        }
        
        try await voiceManager.startRecording()
        
        // Wait a moment for audio processing to start
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Audio level should be updated (might be 0 if no audio input)
        XCTAssertGreaterThanOrEqual(voiceManager.audioLevel, 0.0)
        
        _ = await voiceManager.stopRecording()
        
        // Audio level should reset after stopping
        XCTAssertEqual(voiceManager.audioLevel, 0.0)
    }
    
    // MARK: - Transcription Tests
    
    func testTranscriptionReset() async throws {
        guard voiceManager.permissionStatus == .authorized else {
            throw XCTSkip("Voice permissions not available for testing")
        }
        
        // Set some transcription text
        voiceManager.transcription = "Test transcription"
        XCTAssertEqual(voiceManager.transcription, "Test transcription")
        
        // Start recording should reset transcription
        try await voiceManager.startRecording()
        XCTAssertEqual(voiceManager.transcription, "")
        
        _ = await voiceManager.stopRecording()
    }
    
    func testStopRecordingReturnsTranscription() async throws {
        guard voiceManager.permissionStatus == .authorized else {
            throw XCTSkip("Voice permissions not available for testing")
        }
        
        try await voiceManager.startRecording()
        
        // Simulate some transcription
        voiceManager.transcription = "Test transcription"
        
        let result = await voiceManager.stopRecording()
        XCTAssertEqual(result, "Test transcription")
        
        // Transcription should be cleared after stopping
        XCTAssertEqual(voiceManager.transcription, "")
    }
    
    // MARK: - Error Handling Tests
    
    func testMultipleStartRecordingCalls() async throws {
        guard voiceManager.permissionStatus == .authorized else {
            throw XCTSkip("Voice permissions not available for testing")
        }
        
        // Start recording
        try await voiceManager.startRecording()
        XCTAssertTrue(voiceManager.isRecording)
        
        // Starting again should not cause issues (should cancel previous)
        try await voiceManager.startRecording()
        XCTAssertTrue(voiceManager.isRecording)
        
        _ = await voiceManager.stopRecording()
    }
    
    func testStopRecordingWhenNotRecording() async {
        XCTAssertFalse(voiceManager.isRecording)
        
        // Stopping when not recording should not cause issues
        let result = await voiceManager.stopRecording()
        XCTAssertEqual(result, "")
        XCTAssertFalse(voiceManager.isRecording)
    }
    
    // MARK: - Voice Settings Tests
    
    func testVoiceSettingsInitialization() {
        let settings = voiceManager.currentSettings
        XCTAssertTrue(settings.noiseReductionEnabled)
        XCTAssertTrue(settings.voiceCommandsEnabled)
        XCTAssertFalse(settings.autoSendEnabled)
        XCTAssertEqual(settings.microphoneSensitivity, 0.5)
        XCTAssertEqual(settings.speechTimeout, 3.0)
        XCTAssertEqual(settings.language, "en-US")
    }
    
    func testUpdateVoiceSettings() {
        var newSettings = VoiceSettings()
        newSettings.noiseReductionEnabled = false
        newSettings.voiceCommandsEnabled = false
        newSettings.autoSendEnabled = true
        newSettings.microphoneSensitivity = 0.8
        newSettings.speechTimeout = 5.0
        newSettings.language = "es-ES"
        
        voiceManager.updateSettings(newSettings)
        
        let updatedSettings = voiceManager.currentSettings
        XCTAssertFalse(updatedSettings.noiseReductionEnabled)
        XCTAssertFalse(updatedSettings.voiceCommandsEnabled)
        XCTAssertTrue(updatedSettings.autoSendEnabled)
        XCTAssertEqual(updatedSettings.microphoneSensitivity, 0.8)
        XCTAssertEqual(updatedSettings.speechTimeout, 5.0)
        XCTAssertEqual(updatedSettings.language, "es-ES")
    }
    
    func testGetAvailableCommands() {
        let commands = voiceManager.getAvailableCommands()
        XCTAssertTrue(commands.contains(.stop))
        XCTAssertTrue(commands.contains(.cancel))
        XCTAssertTrue(commands.contains(.send))
        XCTAssertTrue(commands.contains(.clear))
        XCTAssertTrue(commands.contains(.newConversation))
        XCTAssertTrue(commands.contains(.openSettings))
    }
    
    func testVoiceCommandDescriptions() {
        XCTAssertEqual(VoiceCommand.stop.description, "Stop recording")
        XCTAssertEqual(VoiceCommand.cancel.description, "Cancel current input")
        XCTAssertEqual(VoiceCommand.send.description, "Send message")
        XCTAssertEqual(VoiceCommand.clear.description, "Clear input")
        XCTAssertEqual(VoiceCommand.newConversation.description, "Start new conversation")
        XCTAssertEqual(VoiceCommand.openSettings.description, "Open settings")
    }
    
    // MARK: - Performance Tests
    
    func testRecordingStartupTime() async throws {
        guard voiceManager.permissionStatus == .authorized else {
            throw XCTSkip("Voice permissions not available for testing")
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await voiceManager.startRecording()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Recording should start within 2 seconds
        XCTAssertLessThan(duration, 2.0, "Voice recording startup took too long: \(duration) seconds")
        
        _ = await voiceManager.stopRecording()
    }
}

// MARK: - Mock Classes for Testing

class MockSpeechRecognizer {
    var isAvailable: Bool = true
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .authorized
    
    static var mockAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .authorized
    
    static func requestAuthorization(_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        DispatchQueue.main.async {
            handler(mockAuthorizationStatus)
        }
    }
}