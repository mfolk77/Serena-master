import XCTest
@testable import SerenaNet

final class LoggingManagerTests: XCTestCase {
    var loggingManager: LoggingManager!
    
    override func setUp() async throws {
        try await super.setUp()
        loggingManager = LoggingManager.shared
        
        // Reset logging state
        UserDefaults.standard.removeObject(forKey: "SerenaNet.LocalLogging")
        UserDefaults.standard.removeObject(forKey: "SerenaNet.LastLogTime")
        UserDefaults.standard.removeObject(forKey: "SerenaNet.EstimatedLogSize")
    }
    
    override func tearDown() async throws {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "SerenaNet.LocalLogging")
        UserDefaults.standard.removeObject(forKey: "SerenaNet.LastLogTime")
        UserDefaults.standard.removeObject(forKey: "SerenaNet.EstimatedLogSize")
        try await super.tearDown()
    }
    
    func testInitialLoggingState() {
        let status = loggingManager.getLogStatus()
        
        XCTAssertFalse(status.isEnabled) // Should be disabled by default
        XCTAssertNil(status.lastLogTime)
        XCTAssertEqual(status.estimatedLogSize, 0)
    }
    
    func testEnableLogging() {
        loggingManager.enableLogging()
        
        let status = loggingManager.getLogStatus()
        XCTAssertTrue(status.isEnabled)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "SerenaNet.LocalLogging"))
    }
    
    func testDisableLogging() {
        // First enable logging
        loggingManager.enableLogging()
        XCTAssertTrue(loggingManager.getLogStatus().isEnabled)
        
        // Then disable it
        loggingManager.disableLogging()
        
        let status = loggingManager.getLogStatus()
        XCTAssertFalse(status.isEnabled)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "SerenaNet.LocalLogging"))
    }
    
    func testLogWhenDisabled() {
        // Ensure logging is disabled
        loggingManager.disableLogging()
        
        // This should not crash and should complete silently
        XCTAssertNoThrow {
            self.loggingManager.log("Test message when disabled")
            self.loggingManager.logError(TestError.testError, context: "Test context")
            self.loggingManager.logSecurityEvent("Test security event")
        }
    }
    
    func testLogWhenEnabled() {
        loggingManager.enableLogging()
        
        // These should not crash
        XCTAssertNoThrow {
            self.loggingManager.log("Test info message", level: .info)
            self.loggingManager.log("Test debug message", level: .debug)
            self.loggingManager.log("Test warning message", level: .warning)
            self.loggingManager.log("Test error message", level: .error)
            self.loggingManager.log("Test fault message", level: .fault)
        }
    }
    
    func testLogCategories() {
        loggingManager.enableLogging()
        
        XCTAssertNoThrow {
            self.loggingManager.log("General message", category: .general)
            self.loggingManager.log("Error message", category: .error)
            self.loggingManager.log("Security message", category: .security)
        }
    }
    
    func testLogError() {
        loggingManager.enableLogging()
        
        let testError = TestError.testError
        
        XCTAssertNoThrow {
            self.loggingManager.logError(testError, context: "Test context")
            self.loggingManager.logError(testError) // Without context
        }
    }
    
    func testLogSecurityEvent() {
        loggingManager.enableLogging()
        
        XCTAssertNoThrow {
            self.loggingManager.logSecurityEvent("User login attempt")
            self.loggingManager.logSecurityEvent("Passcode changed", details: "User initiated passcode change")
            self.loggingManager.logSecurityEvent("App locked") // Without details
        }
    }
    
    func testLogWithPrivacyRedaction() {
        loggingManager.enableLogging()
        
        let sensitiveMessage = "User password: secret123, token: abc123xyz"
        
        XCTAssertNoThrow {
            self.loggingManager.logWithPrivacyRedaction(sensitiveMessage)
        }
    }
    
    func testClearLogs() {
        loggingManager.enableLogging()
        
        // This should not crash
        XCTAssertNoThrow {
            self.loggingManager.clearLogs()
        }
    }
    
    func testLogLevels() {
        loggingManager.enableLogging()
        
        for level in LogLevel.allCases {
            XCTAssertNoThrow {
                self.loggingManager.log("Test message for \(level.rawValue)", level: level)
            }
        }
    }
    
    func testLogCategories_AllCases() {
        loggingManager.enableLogging()
        
        for category in LogCategory.allCases {
            XCTAssertNoThrow {
                self.loggingManager.log("Test message for \(category.rawValue)", category: category)
            }
        }
    }
    
    func testLogStatus() {
        // Test disabled state
        loggingManager.disableLogging()
        var status = loggingManager.getLogStatus()
        XCTAssertFalse(status.isEnabled)
        
        // Test enabled state
        loggingManager.enableLogging()
        status = loggingManager.getLogStatus()
        XCTAssertTrue(status.isEnabled)
    }
    
    func testSingletonBehavior() {
        let instance1 = LoggingManager.shared
        let instance2 = LoggingManager.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testLogLevelRawValues() {
        XCTAssertEqual(LogLevel.debug.rawValue, "debug")
        XCTAssertEqual(LogLevel.info.rawValue, "info")
        XCTAssertEqual(LogLevel.warning.rawValue, "warning")
        XCTAssertEqual(LogLevel.error.rawValue, "error")
        XCTAssertEqual(LogLevel.fault.rawValue, "fault")
    }
    
    func testLogCategoryRawValues() {
        XCTAssertEqual(LogCategory.general.rawValue, "general")
        XCTAssertEqual(LogCategory.error.rawValue, "error")
        XCTAssertEqual(LogCategory.security.rawValue, "security")
    }
    
    func testDateFormatterExists() {
        let formatter = DateFormatter.logFormatter
        XCTAssertNotNil(formatter)
        XCTAssertEqual(formatter.dateFormat, "yyyy-MM-dd HH:mm:ss.SSS")
    }
}

// MARK: - Test Error Type

enum TestError: Error, LocalizedError {
    case testError
    
    var errorDescription: String? {
        switch self {
        case .testError:
            return "This is a test error"
        }
    }
}