import SwiftUI

struct PerformanceView: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @State private var showingDetailedReport = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Performance Status Header
                performanceStatusHeader
                
                // Key Metrics
                metricsGrid
                
                // Performance Alerts
                if !performanceMonitor.getPerformanceReport().activeAlerts.isEmpty {
                    alertsSection
                }
                
                // Controls
                controlsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Performance Monitor")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Detailed Report") {
                        showingDetailedReport = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailedReport) {
            DetailedPerformanceReportView()
        }
        .onAppear {
            if !performanceMonitor.isMonitoring {
                performanceMonitor.startMonitoring()
            }
        }
    }
    
    private var performanceStatusHeader: some View {
        let report = performanceMonitor.getPerformanceReport()
        
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: report.isPerformingWell ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(report.isPerformingWell ? .green : .orange)
                    .font(.title2)
                
                Text(report.isPerformingWell ? "Performance Good" : "Performance Issues Detected")
                    .font(.headline)
                    .foregroundColor(report.isPerformingWell ? .green : .orange)
            }
            
            Text("Memory: \(report.formattedMemoryUsage) • Response: \(String(format: "%.2f", report.averageResponseTime))s")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Memory Usage",
                value: performanceMonitor.getPerformanceReport().formattedMemoryUsage,
                subtitle: "Peak: \(performanceMonitor.getPerformanceReport().formattedPeakMemoryUsage)",
                icon: "memorychip",
                color: memoryUsageColor
            )
            
            MetricCard(
                title: "Response Time",
                value: "\(String(format: "%.2f", performanceMonitor.averageResponseTime))s",
                subtitle: "Last: \(String(format: "%.2f", performanceMonitor.lastResponseTime))s",
                icon: "speedometer",
                color: responseTimeColor
            )
            
            MetricCard(
                title: "Startup Time",
                value: "\(String(format: "%.2f", performanceMonitor.appStartupTime))s",
                subtitle: "Target: <10s",
                icon: "power",
                color: startupTimeColor
            )
            
            MetricCard(
                title: "Monitoring",
                value: performanceMonitor.isMonitoring ? "Active" : "Inactive",
                subtitle: "Real-time tracking",
                icon: "chart.line.uptrend.xyaxis",
                color: performanceMonitor.isMonitoring ? .green : .gray
            )
        }
    }
    
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Performance Alerts")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(performanceMonitor.getPerformanceReport().activeAlerts) { alert in
                AlertRow(alert: alert) {
                    performanceMonitor.resolveAlert(alert.id)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: {
                    if performanceMonitor.isMonitoring {
                        performanceMonitor.stopMonitoring()
                    } else {
                        performanceMonitor.startMonitoring()
                    }
                }) {
                    Label(
                        performanceMonitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                        systemImage: performanceMonitor.isMonitoring ? "stop.circle" : "play.circle"
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Clear Data") {
                    performanceMonitor.clearPerformanceData()
                }
                .buttonStyle(.bordered)
            }
            
            Button("Trigger Memory Optimization") {
                NotificationCenter.default.post(
                    name: .performanceOptimizationRequested,
                    object: nil,
                    userInfo: ["reason": "manual_trigger"]
                )
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Computed Properties
    
    private var memoryUsageColor: Color {
        let percentage = performanceMonitor.getPerformanceReport().memoryUsagePercentage
        if percentage > 75 { return .red }
        if percentage > 50 { return .orange }
        return .green
    }
    
    private var responseTimeColor: Color {
        let time = performanceMonitor.averageResponseTime
        if time > 4.0 { return .red }
        if time > 2.0 { return .orange }
        return .green
    }
    
    private var startupTimeColor: Color {
        let time = performanceMonitor.appStartupTime
        if time > 8.0 { return .red }
        if time > 5.0 { return .orange }
        return .green
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AlertRow: View {
    let alert: PerformanceAlert
    let onResolve: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.message)
                    .font(.body)
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Resolve") {
                onResolve()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
    
    private var severityIcon: String {
        switch alert.severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        }
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct DetailedPerformanceReportView: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    let report = performanceMonitor.getPerformanceReport()
                    
                    // Summary Section
                    summarySection(report)
                    
                    // Memory Details
                    memorySection(report)
                    
                    // Response Time Details
                    responseTimeSection(report)
                    
                    // Alert History
                    alertHistorySection(report)
                }
                .padding()
            }
            .navigationTitle("Performance Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func summarySection(_ report: PerformanceReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Overall Status:")
                        .fontWeight(.medium)
                    Text(report.isPerformingWell ? "Good" : "Needs Attention")
                        .foregroundColor(report.isPerformingWell ? .green : .orange)
                }
                
                GridRow {
                    Text("Memory Usage:")
                        .fontWeight(.medium)
                    Text("\(report.formattedMemoryUsage) (\(String(format: "%.1f", report.memoryUsagePercentage))%)")
                }
                
                GridRow {
                    Text("Average Response:")
                        .fontWeight(.medium)
                    Text("\(String(format: "%.3f", report.averageResponseTime))s")
                }
                
                GridRow {
                    Text("Startup Time:")
                        .fontWeight(.medium)
                    Text("\(String(format: "%.3f", report.appStartupTime))s")
                }
                
                GridRow {
                    Text("Total Measurements:")
                        .fontWeight(.medium)
                    Text("\(report.totalResponseMeasurements)")
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func memorySection(_ report: PerformanceReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current:")
                    Spacer()
                    Text(report.formattedMemoryUsage)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Peak:")
                    Spacer()
                    Text(report.formattedPeakMemoryUsage)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Target Limit:")
                    Spacer()
                    Text("2.0 GB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Maximum Limit:")
                    Spacer()
                    Text("4.0 GB")
                        .foregroundColor(.secondary)
                }
                
                // Memory usage bar
                ProgressView(value: report.memoryUsagePercentage / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: memoryUsageColor(report.memoryUsagePercentage)))
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func responseTimeSection(_ report: PerformanceReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response Times")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Average:")
                    Spacer()
                    Text("\(String(format: "%.3f", report.averageResponseTime))s")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Last Response:")
                    Spacer()
                    Text("\(String(format: "%.3f", report.lastResponseTime))s")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Target:")
                    Spacer()
                    Text("< 5.0s")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Measurements:")
                    Spacer()
                    Text("\(report.totalResponseMeasurements)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func alertHistorySection(_ report: PerformanceReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Alerts")
                .font(.title2)
                .fontWeight(.semibold)
            
            if report.activeAlerts.isEmpty {
                Text("No active performance alerts")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(report.activeAlerts) { alert in
                    AlertRow(alert: alert) {
                        performanceMonitor.resolveAlert(alert.id)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func memoryUsageColor(_ percentage: Double) -> Color {
        if percentage > 75 { return .red }
        if percentage > 50 { return .orange }
        return .green
    }
}

#Preview {
    PerformanceView()
}