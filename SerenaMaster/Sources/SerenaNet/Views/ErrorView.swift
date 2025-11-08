import SwiftUI

struct ErrorView: View {
    let error: SerenaError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    @StateObject private var errorManager = ErrorManager()
    
    init(error: SerenaError, onRetry: (() -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Error icon
            Image(systemName: error.severity.systemImageName)
                .font(.system(size: 48))
                .foregroundColor(errorColor)
            
            // Error title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Error description
            if let description = error.errorDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Recovery suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                if error.isRecoverable, let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private var errorTitle: String {
        switch error.severity {
        case .info:
            return "Information"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        case .critical:
            return "Critical Error"
        }
    }
    
    private var errorColor: Color {
        switch error.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
}

struct ErrorBannerView: View {
    let error: SerenaError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.severity.systemImageName)
                .foregroundColor(errorColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.localizedDescription)
                    .font(.callout)
                    .fontWeight(.medium)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(errorColor.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var errorColor: Color {
        switch error.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error, .critical:
            return .red
        }
    }
    
    private var backgroundColor: Color {
        switch error.severity {
        case .info:
            return Color.blue.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .error, .critical:
            return Color.red.opacity(0.1)
        }
    }
}

struct OfflineIndicatorView: View {
    let networkManager: NetworkConnectivityManager
    @State private var showDetails = false
    
    var body: some View {
        if !networkManager.isConnected {
            Button(action: { showDetails.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    
                    Text("Offline Mode")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: "info.circle")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showDetails) {
                OfflineModeDetailsView(networkManager: networkManager)
            }
        }
    }
}

struct OfflineModeDetailsView: View {
    let networkManager: NetworkConnectivityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Offline Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("No internet connection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Features:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                FeatureStatusRow(
                    icon: "brain.head.profile",
                    title: "AI Conversations",
                    status: .available,
                    description: "Processed locally on your device"
                )
                
                FeatureStatusRow(
                    icon: "mic",
                    title: "Voice Input",
                    status: .available,
                    description: "Uses local speech recognition"
                )
                
                FeatureStatusRow(
                    icon: "externaldrive",
                    title: "Data Storage",
                    status: .available,
                    description: "Conversations saved locally"
                )
                
                FeatureStatusRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Data Sync",
                    status: .unavailable,
                    description: "Will sync when connection is restored"
                )
            }
            
            Text(networkManager.getOfflineModeGuidance())
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 350)
    }
}

struct FeatureStatusRow: View {
    let icon: String
    let title: String
    let status: FeatureStatus
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: status.systemImage)
                        .foregroundColor(status.color)
                        .font(.caption)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

enum FeatureStatus {
    case available
    case unavailable
    case limited
    
    var color: Color {
        switch self {
        case .available:
            return .green
        case .unavailable:
            return .red
        case .limited:
            return .orange
        }
    }
    
    var systemImage: String {
        switch self {
        case .available:
            return "checkmark.circle.fill"
        case .unavailable:
            return "xmark.circle.fill"
        case .limited:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview("Error View") {
    ErrorView(
        error: .aiResponseGenerationFailed("Model timeout"),
        onRetry: {},
        onDismiss: {}
    )
}

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(
            error: .networkUnavailable,
            onDismiss: {}
        )
        
        ErrorBannerView(
            error: .voicePermissionDenied,
            onDismiss: {}
        )
        
        Spacer()
    }
}

#Preview("Offline Indicator") {
    OfflineIndicatorView(networkManager: NetworkConnectivityManager())
}