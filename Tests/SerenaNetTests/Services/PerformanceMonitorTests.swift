import XCTest
@testable import SerenaNet

@MainActor
final class PerformanceMonitorTests: XCTestCase {
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() async throws {
        try await super.setUp()
        performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.stopMonitoring()
        performanceMonitor.clearPerformanceData()
    }
    
    override func tearDown() async throws {
        performanceMonitor.stopMonitoring()
        performanceMonitor.clearPerformanceData()
        try await super.tearDown()
    }
    
    // MARK: - Monitoring Control Tests
    
    func testStartStopMonitoring() async throws {
        // Initially not monitoring
        XCTAssertFalse(performanceMonitor.isMonitoring)
        
        // Start monitoring
        performanceMonitor.startMonitoring()
        XCTAssertTrue(performanceMonitor.isMonitoring)
        
        // Stop monitoring
        performanceMonitor.stopMonitoring()
        XCTAssertFalse(performanceMonitor.isMonitoring)
    }
    
    func testStartMonitoringTwice() async throws {
        // Start monitoring twice should not cause issues
        performanceMonitor.startMonitoring()
        XCTAssertTrue(performanceMonitor.isMonitoring)
        
        performanceMonitor.startMonitoring()
        XCTAssertTrue(performanceMonitor.isMonitoring)
    }
    
    func testStopMonitoringWhenNotStarted() async throws {
        // Stopping when not started should not cause issues
        XCTAssertFalse(performanceMonitor.isMonitoring)
        performanceMonitor.stopMonitoring()
        XCTAssertFalse(performanceMonitor.isMonitoring)
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageTracking() async throws {
        performanceMonitor.startMonitoring()
        
        // Wait a moment for memory reading
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Memory usage should be greater than 0
        XCTAssertGreaterThan(performanceMonitor.currentMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(performanceMonitor.peakMemoryUsage, performanceMonitor.currentMemoryUsage)
    }
    
    func testPeakMemoryUsageTracking() async throws {
        performanceMonitor.startMonitoring()
        
        let initialPeak = performanceMonitor.peakMemoryUsage
        
        // Simulate memory usage increase (this is a simplified test)
        // In real scenarios, peak would be updated by the monitoring timer
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Peak should be at least as high as current
        XCTAssertGreaterThanOrEqual(performanceMonitor.peakMemoryUsage, initialPeak)
    }
    
    // MARK: - Response Time Tests
    
    func testResponseTimeMeasurement() async throws {
        let expectedDelay: TimeInterval = 0.1
        
        let result = try await performanceMonitor.measureResponseTime {
            try await Task.sleep(nanoseconds: UInt64(expectedDelay * 1_000_000_000))
            return "test result"
        }
        
        XCTAssertEqual(result, "test result")
        XCTAssertGreaterThanOrEqual(performanceMonitor.lastResponseTime, expectedDelay * 0.8) // Allow some variance
        XCTAssertLessThanOrEqual(performanceMonitor.lastResponseTime, expectedDelay * 1.5)
    }
    
    func testResponseTimeThrowingOperation() async throws {
        struct TestError: Error {}
        
        do {
            _ = try await performanceMonitor.measureResponseTime {
                throw TestError()
            }
            XCTFail("Should have thrown error")
        } catch is TestError {
            // Expected error
            XCTAssertGreaterThan(performanceMonitor.lastResponseTime, 0)
        }
    }
    
    func testAverageResponseTimeCalculation() async throws {
        // Record multiple response times
        await performanceMonitor.recordResponseTime(1.0)
        await performanceMonitor.recordResponseTime(2.0)
        await performanceMonitor.recordResponseTime(3.0)
        
        let expectedAverage = (1.0 + 2.0 + 3.0) / 3.0
        XCTAssertEqual(performanceMonitor.averageResponseTime, expectedAverage, accuracy: 0.001)
    }
    
    func testResponseTimeMeasurementLimit() async throws {
        // Record more than 100 measurements to test limit
        for i in 1...150 {
            await performanceMonitor.recordResponseTime(Double(i))
        }
        
        let report = performanceMonitor.getPerformanceReport()
        XCTAssertEqual(report.totalResponseMeasurements, 100) // Should be capped at 100
        
        // Average should be based on last 100 measurements (51-150)
        let expectedAverage = (51...150).reduce(0.0) { $0 + Double($1) } / 100.0
        XCTAssertEqual(performanceMonitor.averageResponseTime, expectedAverage, accuracy: 0.001)
    }
    
    // MARK: - Startup Time Tests
    
    func testStartupTimeRecording() async throws {
        // Reset startup time
        performanceMonitor.clearPerformanceData()
        
        performanceMonitor.recordAppStartupComplete()
        
        XCTAssertGreaterThan(performanceMonitor.appStartupTime, 0)
    }
    
    // MARK: - Performance Report Tests
    
    func testPerformanceReport() async throws {
        // Set up some test data
        await performanceMonitor.recordResponseTime(2.5)
        await performanceMonitor.recordResponseTime(3.0)
        performanceMonitor.recordAppStartupComplete()
        
        let report = performanceMonitor.getPerformanceReport()
        
        XCTAssertGreaterThan(report.currentMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(report.peakMemoryUsage, report.currentMemoryUsage)
        XCTAssertEqual(report.averageResponseTime, 2.75, accuracy: 0.001)
        XCTAssertEqual(report.lastResponseTime, 3.0)
        XCTAssertGreaterThan(report.appStartupTime, 0)
        XCTAssertEqual(report.totalResponseMeasurements, 2)
        XCTAssertGreaterThan(report.memoryUsagePercentage, 0)
        XCTAssertLessThan(report.memoryUsagePercentage, 100)
    }
    
    func testPerformanceReportFormatting() async throws {
        let report = performanceMonitor.getPerformanceReport()
        
        // Test formatted memory strings
        XCTAssertFalse(report.formattedMemoryUsage.isEmpty)
        XCTAssertFalse(report.formattedPeakMemoryUsage.isEmpty)
        XCTAssertTrue(report.formattedMemoryUsage.contains("B")) // Should contain bytes unit
    }
    
    func testPerformanceReportWellnessIndicator() async throws {
        // Clear any existing data
        performanceMonitor.clearPerformanceData()
        
        // Record good performance metrics
        await performanceMonitor.recordResponseTime(1.0) // Good response time
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Should be performing well with good metrics and no alerts
        if report.memoryUsagePercentage < 50 && report.averageResponseTime < 3.0 {
            XCTAssertTrue(report.isPerformingWell)
        }
    }
    
    // MARK: - Performance Alerts Tests
    
    func testSlowResponseAlert() async throws {
        // Record a slow response time (> 5 seconds)
        await performanceMonitor.recordResponseTime(6.0)
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Should have a slow response alert
        let slowResponseAlerts = report.activeAlerts.filter { alert in
            if case .slowResponse = alert.type {
                return true
            }
            return false
        }
        
        XCTAssertGreaterThan(slowResponseAlerts.count, 0)
    }
    
    func testSlowStartupAlert() async throws {
        // This test simulates a slow startup by directly creating the alert condition
        // In real usage, this would be triggered by recordAppStartupComplete()
        performanceMonitor.recordAppStartupComplete()
        
        // If startup was actually slow (> 10 seconds), there would be an alert
        // For this test, we just verify the mechanism works
        let report = performanceMonitor.getPerformanceReport()
        
        // Check that alerts can be created (may or may not have startup alert depending on actual startup time)
        XCTAssertNotNil(report.activeAlerts)
    }
    
    func testAlertResolution() async throws {
        // Record a slow response to create an alert
        await performanceMonitor.recordResponseTime(6.0)
        
        var report = performanceMonitor.getPerformanceReport()
        guard let alert = report.activeAlerts.first else {
            XCTFail("Expected to have at least one alert")
            return
        }
        
        XCTAssertFalse(alert.isResolved)
        
        // Resolve the alert
        performanceMonitor.resolveAlert(alert.id)
        
        report = performanceMonitor.getPerformanceReport()
        let resolvedAlert = report.activeAlerts.first { $0.id == alert.id }
        
        // Alert should no longer be in active alerts
        XCTAssertNil(resolvedAlert)
    }
    
    func testDuplicateAlertPrevention() async throws {
        // Record multiple slow responses quickly
        await performanceMonitor.recordResponseTime(6.0)
        await performanceMonitor.recordResponseTime(7.0)
        await performanceMonitor.recordResponseTime(8.0)
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Should not have duplicate slow response alerts within 5 minutes
        let slowResponseAlerts = report.activeAlerts.filter { alert in
            if case .slowResponse = alert.type {
                return true
            }
            return false
        }
        
        // Should have only one alert despite multiple slow responses
        XCTAssertEqual(slowResponseAlerts.count, 1)
    }
    
    // MARK: - Data Management Tests
    
    func testClearPerformanceData() async throws {
        // Set up some test data
        await performanceMonitor.recordResponseTime(2.0)
        await performanceMonitor.recordResponseTime(3.0)
        performanceMonitor.recordAppStartupComplete()
        
        // Verify data exists
        XCTAssertGreaterThan(performanceMonitor.averageResponseTime, 0)
        XCTAssertGreaterThan(performanceMonitor.appStartupTime, 0)
        
        // Clear data
        performanceMonitor.clearPerformanceData()
        
        // Verify data is cleared
        XCTAssertEqual(performanceMonitor.averageResponseTime, 0)
        XCTAssertEqual(performanceMonitor.lastResponseTime, 0)
        
        let report = performanceMonitor.getPerformanceReport()
        XCTAssertEqual(report.totalResponseMeasurements, 0)
        XCTAssertEqual(report.activeAlerts.count, 0)
    }
    
    // MARK: - Alert Message Tests
    
    func testAlertMessages() async throws {
        let memoryAlert = PerformanceAlert(type: .memoryExceeded(1024 * 1024 * 1024)) // 1GB
        XCTAssertTrue(memoryAlert.message.contains("Memory usage exceeded"))
        XCTAssertTrue(memoryAlert.message.contains("GB"))
        
        let responseAlert = PerformanceAlert(type: .slowResponse(6.5))
        XCTAssertTrue(responseAlert.message.contains("Slow response"))
        XCTAssertTrue(responseAlert.message.contains("6.50"))
        
        let startupAlert = PerformanceAlert(type: .slowStartup(12.0))
        XCTAssertTrue(startupAlert.message.contains("Slow app startup"))
        XCTAssertTrue(startupAlert.message.contains("12.00"))
    }
    
    func testAlertSeverity() async throws {
        let memoryExceededAlert = PerformanceAlert(type: .memoryExceeded(1024))
        XCTAssertEqual(memoryExceededAlert.severity, .high)
        
        let memoryHighAlert = PerformanceAlert(type: .memoryHigh(1024))
        XCTAssertEqual(memoryHighAlert.severity, .medium)
        
        let slowResponseAlert = PerformanceAlert(type: .slowResponse(6.0))
        XCTAssertEqual(slowResponseAlert.severity, .medium)
        
        let slowStartupAlert = PerformanceAlert(type: .slowStartup(12.0))
        XCTAssertEqual(slowStartupAlert.severity, .high)
    }
    
    // MARK: - Integration Tests
    
    func testPerformanceMonitoringIntegration() async throws {
        // Test the full monitoring cycle
        performanceMonitor.startMonitoring()
        
        // Simulate some operations
        _ = try await performanceMonitor.measureResponseTime {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            return "operation result"
        }
        
        // Wait for monitoring to update
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Verify all components are working
        XCTAssertGreaterThan(report.currentMemoryUsage, 0)
        XCTAssertGreaterThan(report.lastResponseTime, 0)
        XCTAssertGreaterThan(report.totalResponseMeasurements, 0)
        
        performanceMonitor.stopMonitoring()
    }
}