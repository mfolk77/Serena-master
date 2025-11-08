import Foundation

/// User subscription tier
public enum UserTier: String, Codable {
    case free = "free"
    case paid = "paid"

    /// Memory retention period in days
    public var memoryRetentionDays: Int {
        switch self {
        case .free:
            return 30  // Free tier: 30 days only
        case .paid:
            return 365 * 10  // Paid tier: effectively unlimited (10 years)
        }
    }

    /// Maximum conversation history messages
    public var maxHistoryMessages: Int {
        switch self {
        case .free:
            return 1000
        case .paid:
            return 10000
        }
    }

    /// Display name
    public var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .paid:
            return "Paid"
        }
    }

    /// Feature descriptions
    public var features: [String] {
        switch self {
        case .free:
            return [
                "30-day conversation memory",
                "Up to 1,000 stored messages",
                "Semantic search within 30 days",
                "Basic conversation history"
            ]
        case .paid:
            return [
                "Unlimited conversation memory",
                "Up to 10,000 stored messages",
                "Semantic search across all time",
                "Full conversation archive",
                "Priority support"
            ]
        }
    }
}

/// User tier configuration
public struct UserTierConfig: Codable {
    public var currentTier: UserTier
    public var tierStartDate: Date
    public var lastCleanupDate: Date?

    public init(tier: UserTier = .free, startDate: Date = Date()) {
        self.currentTier = tier
        self.tierStartDate = startDate
        self.lastCleanupDate = nil
    }

    /// Check if a date is within the retention period for current tier
    public func isWithinRetention(_ date: Date) -> Bool {
        let retentionDays = currentTier.memoryRetentionDays
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else {
            return false
        }
        return date >= cutoffDate
    }

    /// Should run cleanup?
    public func shouldRunCleanup() -> Bool {
        guard let lastCleanup = lastCleanupDate else { return true }

        // Run cleanup daily
        let daysSinceCleanup = Calendar.current.dateComponents([.day], from: lastCleanup, to: Date()).day ?? 0
        return daysSinceCleanup >= 1
    }
}
