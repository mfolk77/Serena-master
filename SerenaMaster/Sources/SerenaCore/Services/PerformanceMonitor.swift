import Foundation
import os.log
import SwiftUI

@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentMemoryUsage: Int64 = 0
    @Published var peakMemoryUsage: Int64 = 0
    @Published var averageResponseTime: TimeInterval = 0
    @Published var lastResponseTime: TimeInterval = 0
    @Published var appStartupTime: TimeInterval = 0
    @Published var isMonitoring: Bool = false
    
    private let logger = Logger(subsystem: "com.serenanet.app", category: "performance")
    private var startupStartTime: Date?
    private var responseTimeMeasurements: [TimeInterval] = []
    private var monitoringTimer: Timer?
    private var performanceAlerts: [PerformanceAlert] = []
    
    // Performance thresholds from requirements
    private let maxMemoryUsage: Int64 = 4 * 1024 * 1024 * 1024 // 4GB
    private let targetMemoryUsage: Int64 = 2 * 1024 * 1024 * 1024 // 2GB
    private let maxResponseTime: TimeInterval = 5.0 // 5 seconds
    private let maxStartupTime: TimeInterval = 10.0 // 10 seconds
    
    private init() {
        startupStartTime = Date()
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Performance monitoring started")
        
        // Start periodic memory monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
                self?.checkPerformanceThresholds()
            }
        }
        
        // Initial memory reading
        updateMemoryUsage()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        logger.info("Performance monitoring stopped")
    }
    
    func recordAppStartupComplete() {
        guard let startTime = startupStartTime else { return }
        
        appStartupTime = Date().timeIntervalSince(startTime)
        logger.info("App startup completed in \(self.appStartupTime, privacy: .public) seconds")
        
        if appStartupTime > maxStartupTime {
            addPerformanceAlert(.slowStartup(appStartupTime))
        }
        
        startupStartTime = nil
    }
    
    func measureResponseTime<T>(_ operation: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        let result = try await operation()
        let responseTime = Date().timeIntervalSince(startTime)
        
        await recordResponseTime(responseTime)
        return result
    }
    
    func recordResponseTime(_ time: TimeInterval) async {
        lastResponseTime = time
        responseTimeMeasurements.append(time)
        
        // Keep only last 100 measurements for average calculation
        if responseTimeMeasurements.count > 100 {
            responseTimeMeasurements.removeFirst()
        }
        
        averageResponseTime = responseTimeMeasurements.reduce(0, +) / Double(responseTimeMeasurements.count)
        
        logger.info("Response time recorded: \(time, privacy: .public)s (avg: \(self.averageResponseTime, privacy: .public)s)")
        
        if time > maxResponseTime {
            addPerformanceAlert(.slowResponse(time))
        }
    }
    
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            currentMemoryUsage: currentMemoryUsage,
            peakMemoryUsage: peakMemoryUsage,
            averageResponseTime: averageResponseTime,
            lastResponseTime: lastResponseTime,
            appStartupTime: appStartupTime,
            totalResponseMeasurements: responseTimeMeasurements.count,
            activeAlerts: performanceAlerts.filter { !$0.isResolved },
            memoryUsagePercentage: Double(currentMemoryUsage) / Double(maxMemoryUsage) * 100
        )
    }
    
    func clearPerformanceData() {
        responseTimeMeasurements.removeAll()
        performanceAlerts.removeAll()
        peakMemoryUsage = currentMemoryUsage
        averageResponseTime = 0
        lastResponseTime = 0
        
        logger.info("Performance data cleared")
    }
    
    func resolveAlert(_ alertId: UUID) {
        if let index = performanceAlerts.firstIndex(where: { $0.id == alertId }) {
            performanceAlerts[index].isResolved = true
            performanceAlerts[index].resolvedAt = Date()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        currentMemoryUsage = memoryUsage
        
        if memoryUsage > peakMemoryUsage {
            peakMemoryUsage = memoryUsage
        }
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            logger.error("Failed to get memory usage: \(kerr)")
            return 0
        }
    }
    
    private func checkPerformanceThresholds() {
        // Check memory usage
        if currentMemoryUsage > maxMemoryUsage {
            addPerformanceAlert(.memoryExceeded(currentMemoryUsage))
        } else if currentMemoryUsage > targetMemoryUsage {
            addPerformanceAlert(.memoryHigh(currentMemoryUsage))
        }
        
        // Auto-optimization triggers
        if currentMemoryUsage > targetMemoryUsage {
            triggerMemoryOptimization()
        }
    }
    
    private func addPerformanceAlert(_ type: PerformanceAlertType) {
        let alert = PerformanceAlert(type: type)
        
        // Avoid duplicate alerts of the same type within 5 minutes
        let recentAlerts = performanceAlerts.filter { 
            $0.type.rawValue == type.rawValue && 
            Date().timeIntervalSince($0.timestamp) < 300 
        }
        
        if recentAlerts.isEmpty {
            performanceAlerts.append(alert)
            logger.warning("Performance alert: \(alert.message, privacy: .public)")
        }
    }
    
    private func triggerMemoryOptimization() {
        logger.info("Triggering automatic memory optimization")
        
        // Notify other components to clean up
        NotificationCenter.default.post(
            name: .performanceOptimizationRequested,
            object: nil,
            userInfo: ["reason": "high_memory_usage"]
        )
    }
}

// MARK: - Supporting Types

struct PerformanceReport {
    let currentMemoryUsage: Int64
    let peakMemoryUsage: Int64
    let averageResponseTime: TimeInterval
    let lastResponseTime: TimeInterval
    let appStartupTime: TimeInterval
    let totalResponseMeasurements: Int
    let activeAlerts: [PerformanceAlert]
    let memoryUsagePercentage: Double
    
    var formattedMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: currentMemoryUsage, countStyle: .memory)
    }
    
    var formattedPeakMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: peakMemoryUsage, countStyle: .memory)
    }
    
    var isPerformingWell: Bool {
        return memoryUsagePercentage < 50 && 
               averageResponseTime < 3.0 && 
               activeAlerts.isEmpty
    }
}

struct PerformanceAlert: Identifiable {
    let id = UUID()
    let type: PerformanceAlertType
    let timestamp = Date()
    var isResolved = false
    var resolvedAt: Date?
    
    var message: String {
        switch type {
        case .memoryExceeded(let usage):
            return "Memory usage exceeded limit: \(ByteCountFormatter.string(fromByteCount: usage, countStyle: .memory))"
        case .memoryHigh(let usage):
            return "High memory usage detected: \(ByteCountFormatter.string(fromByteCount: usage, countStyle: .memory))"
        case .slowResponse(let time):
            return "Slow response detected: \(String(format: "%.2f", time))s"
        case .slowStartup(let time):
            return "Slow app startup: \(String(format: "%.2f", time))s"
        }
    }
    
    var severity: AlertSeverity {
        switch type {
        case .memoryExceeded, .slowStartup:
            return .high
        case .memoryHigh, .slowResponse:
            return .medium
        }
    }
}

enum PerformanceAlertType {
    case memoryExceeded(Int64)
    case memoryHigh(Int64)
    case slowResponse(TimeInterval)
    case slowStartup(TimeInterval)
    
    var rawValue: String {
        switch self {
        case .memoryExceeded: return "memory_exceeded"
        case .memoryHigh: return "memory_high"
        case .slowResponse: return "slow_response"
        case .slowStartup: return "slow_startup"
        }
    }
}

enum AlertSeverity {
    case low, medium, high
}

// MARK: - Notifications

extension Notification.Name {
    static let performanceOptimizationRequested = Notification.Name("performanceOptimizationRequested")
}