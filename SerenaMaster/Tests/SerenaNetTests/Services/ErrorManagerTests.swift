import XCTest
@testable import SerenaNet

@MainActor
final class ErrorManagerTests: XCTestCase {
    var errorManager: ErrorManager!
    
    override func setUp() {
        super.setUp()
        errorManager = ErrorManager()
    }
    
    override func tearDown() {
        errorManager = nil
        super.tearDown()
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleSerenaError() {
        let error = SerenaError.aiModelNotLoaded
        let context = "Test context"
        
        errorManager.handle(error, context: context)
        
        XCTAssertEqual(errorManager.errorHistory.count, 1)
        XCTAssertEqual(errorManager.errorHistory.first?.error, error)
        XCTAssertEqual(errorManager.errorHistory.first?.context, context)
        XCTAssertEqual(errorManager.errorHistory.first?.severity, error.severity)
        XCTAssertFalse(errorManager.errorHistory.first?.wasRecovered ?? true)
    }
    
    func testHandleGenericError() {
        let genericError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        errorManager.handle(genericError, context: "Generic error test")
        
        XCTAssertEqual(errorManager.errorHistory.count, 1)
        if case .unknownError(let message) = errorManager.errorHistory.first?.error {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected unknownError")
        }
    }
    
    func testErrorHistoryLimit() {
        // Add more errors than the limit
        for i in 0..<60 {
            errorManager.handle(.emptyMessage, context: "Error \(i)")
        }
        
        XCTAssertEqual(errorManager.errorHistory.count, 50) // maxErrorHistory
    }
    
    func testDismissError() {
        errorManager.handle(.aiModelNotLoaded)
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
        
        errorManager.dismissError()
        XCTAssertFalse(errorManager.isShowingError)
        XCTAssertNil(errorManager.currentError)
    }
    
    // MARK: - Error Recovery Tests
    
    func testGetRecoveryActionForRetryableError() {
        let action = errorManager.getRecoveryAction(for: .aiResponseGenerationFailed("Test"))
        
        if case .retry(let message) = action {
            XCTAssertEqual(message, "Try sending your message again")
        } else {
            XCTFail("Expected retry action")
        }
    }
    
    func testGetRecoveryActionForUserInterventionError() {
        let action = errorManager.getRecoveryAction(for: .voicePermissionDenied)
        
        if case .userIntervention(let message) = action {
            XCTAssertEqual(message, "Enable microphone permission in System Preferences")
        } else {
            XCTFail("Expected userIntervention action")
        }
    }
    
    func testGetRecoveryActionForIgnorableError() {
        let action = errorManager.getRecoveryAction(for: .networkUnavailable)
        
        if case .ignore(let message) = action {
            XCTAssertEqual(message, "Continue using offline mode")
        } else {
            XCTFail("Expected ignore action")
        }
    }
    
    func testMarkErrorAsRecovered() {
        errorManager.handle(.aiResponseGenerationFailed("Test"))
        let errorId = errorManager.errorHistory.first!.id
        
        errorManager.markErrorAsRecovered(errorId)
        
        XCTAssertTrue(errorManager.errorHistory.first?.wasRecovered ?? false)
    }
    
    // MARK: - Error Statistics Tests
    
    func testGetErrorCount() {
        errorManager.handle(.networkUnavailable) // info
        errorManager.handle(.voicePermissionDenied) // warning
        errorManager.handle(.aiResponseGenerationFailed("Test")) // error
        errorManager.handle(.databaseError("Test")) // critical
        
        XCTAssertEqual(errorManager.getErrorCount(for: .info), 1)
        XCTAssertEqual(errorManager.getErrorCount(for: .warning), 1)
        XCTAssertEqual(errorManager.getErrorCount(for: .error), 1)
        XCTAssertEqual(errorManager.getErrorCount(for: .critical), 1)
    }
    
    func testGetRecentErrors() {
        for i in 0..<15 {
            errorManager.handle(.emptyMessage, context: "Error \(i)")
        }
        
        let recentErrors = errorManager.getRecentErrors(limit: 10)
        XCTAssertEqual(recentErrors.count, 10)
        
        // Should be in reverse chronological order (most recent first)
        XCTAssertEqual(recentErrors.first?.context, "Error 14")
        XCTAssertEqual(recentErrors.last?.context, "Error 5")
    }
    
    func testClearErrorHistory() {
        errorManager.handle(.emptyMessage)
        errorManager.handle(.networkUnavailable)
        
        XCTAssertEqual(errorManager.errorHistory.count, 2)
        
        errorManager.clearErrorHistory()
        
        XCTAssertEqual(errorManager.errorHistory.count, 0)
    }
    
    // MARK: - User Guidance Tests
    
    func testGetUserGuidanceMessage() {
        let aiModelMessage = errorManager.getUserGuidanceMessage(for: .aiModelNotLoaded)
        XCTAssertTrue(aiModelMessage.contains("10-30 seconds"))
        
        let voiceMessage = errorManager.getUserGuidanceMessage(for: .voicePermissionDenied)
        XCTAssertTrue(voiceMessage.contains("type your messages"))
        
        let networkMessage = errorManager.getUserGuidanceMessage(for: .networkUnavailable)
        XCTAssertTrue(networkMessage.contains("locally"))
        
        let databaseMessage = errorManager.getUserGuidanceMessage(for: .databaseError("Test"))
        XCTAssertTrue(databaseMessage.contains("backing up"))
    }
    
    // MARK: - Diagnostic Report Tests
    
    func testGenerateDiagnosticReport() {
        errorManager.handle(.aiModelNotLoaded)
        errorManager.handle(.voicePermissionDenied)
        errorManager.handle(.databaseError("Test"))
        
        let report = errorManager.generateDiagnosticReport()
        
        XCTAssertTrue(report.contains("SerenaNet Error Diagnostic Report"))
        XCTAssertTrue(report.contains("Total Errors: 3"))
        XCTAssertTrue(report.contains("Recent Errors:"))
        XCTAssertTrue(report.contains("AI model is not ready"))
    }
    
    // MARK: - Error Severity Display Tests
    
    func testInfoErrorsDoNotShowDialog() {
        errorManager.handle(.networkUnavailable) // info severity
        
        XCTAssertFalse(errorManager.isShowingError)
        XCTAssertNil(errorManager.currentError)
    }
    
    func testWarningErrorsShowDialog() {
        errorManager.handle(.voicePermissionDenied) // warning severity
        
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
    }
    
    func testErrorSeverityShowsDialog() {
        errorManager.handle(.aiResponseGenerationFailed("Test")) // error severity
        
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
    }
    
    func testCriticalErrorsShowDialog() {
        errorManager.handle(.databaseError("Test")) // critical severity
        
        XCTAssertTrue(errorManager.isShowingError)
        XCTAssertNotNil(errorManager.currentError)
    }
}

// MARK: - Error Recovery Action Tests

final class ErrorRecoveryActionTests: XCTestCase {
    
    func testRetryActionProperties() {
        let action = ErrorRecoveryAction.retry("Test retry message")
        
        XCTAssertEqual(action.actionText, "Test retry message")
        XCTAssertEqual(action.buttonText, "Retry")
    }
    
    func testWaitActionProperties() {
        let action = ErrorRecoveryAction.wait("Test wait message")
        
        XCTAssertEqual(action.actionText, "Test wait message")
        XCTAssertEqual(action.buttonText, "OK")
    }
    
    func testRestartActionProperties() {
        let action = ErrorRecoveryAction.restart("Test restart message")
        
        XCTAssertEqual(action.actionText, "Test restart message")
        XCTAssertEqual(action.buttonText, "Restart")
    }
    
    func testUserInterventionActionProperties() {
        let action = ErrorRecoveryAction.userIntervention("Test intervention message")
        
        XCTAssertEqual(action.actionText, "Test intervention message")
        XCTAssertEqual(action.buttonText, "Open Settings")
    }
    
    func testIgnoreActionProperties() {
        let action = ErrorRecoveryAction.ignore("Test ignore message")
        
        XCTAssertEqual(action.actionText, "Test ignore message")
        XCTAssertEqual(action.buttonText, "Continue")
    }
}