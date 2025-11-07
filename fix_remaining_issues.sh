#!/bin/bash

# SerenaNet Remaining Issues Fix Script
# This script fixes the remaining compilation issues

echo "🔧 Fixing Remaining SerenaNet Issues..."
echo "======================================"

# Fix 1: Remove navigationBarTitleDisplayMode from HelpView (macOS incompatible)
echo "📝 Fixing HelpView navigationBarTitleDisplayMode..."
sed -i '' '/\.navigationBarTitleDisplayMode(.inline)/d' Sources/SerenaNet/Views/HelpView.swift

# Fix 2: Fix ThemeManager environment key
echo "📝 Fixing ThemeManager environment key..."
cat > temp_theme_fix.swift << 'EOF'
// MARK: - Environment Values
private struct ThemeManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = ThemeManager.shared
}
EOF

# Replace the problematic section
sed -i '' '/\/\/ MARK: - Environment Values/,/^}$/c\
// MARK: - Environment Values\
private struct ThemeManagerKey: EnvironmentKey {\
    @MainActor static let defaultValue = ThemeManager.shared\
}' Sources/SerenaNet/Services/ThemeManager.swift

# Fix 3: Fix ChatManager type conversion helpers
echo "📝 Fixing ChatManager type conversion..."

# Remove the incorrect conversion helpers and replace with correct ones
sed -i '' '/\/\/ MARK: - Type Conversion Helpers/,$d' Sources/SerenaNet/Services/ChatManager.swift

cat >> Sources/SerenaNet/Services/ChatManager.swift << 'EOF'

// MARK: - Type Conversion Helpers
private extension ChatManager {
    func convertToSerenaCore(_ messages: [SerenaNet.Message]) -> [SerenaCore.Message] {
        return messages.compactMap { message in
            SerenaCore.Message(
                id: message.id,
                content: message.content,
                role: message.isUser ? .user : .assistant,
                timestamp: message.timestamp
            )
        }
    }
    
    func convertToSerenaCore(_ document: SerenaNet.FTAIDocument) -> SerenaCore.FTAIDocument {
        return SerenaCore.FTAIDocument(
            version: document.version ?? "1.0",
            metadata: document.metadata,
            content: document.content
        )
    }
}
EOF

# Fix 4: Add @MainActor to WindowManager notification handlers
echo "📝 Fixing WindowManager concurrency..."
sed -i '' 's/) { \[weak self\] _ in/) { @MainActor [weak self] _ in/' Sources/SerenaNet/Services/WindowManager.swift
sed -i '' 's/) { \[weak self\] notification in/) { @MainActor [weak self] notification in/' Sources/SerenaNet/Services/WindowManager.swift

# Fix 5: Add @MainActor to AccessibilityManager notification handlers
echo "📝 Fixing AccessibilityManager concurrency..."
sed -i '' 's/) { \[weak self\] _ in/) { @MainActor [weak self] _ in/' Sources/SerenaNet/Services/AccessibilityManager.swift

# Fix 6: Add @MainActor to NotificationManager NSApp calls
echo "📝 Fixing NotificationManager NSApp calls..."
sed -i '' 's/NSApp.activate(ignoringOtherApps: true)/await MainActor.run { NSApp.activate(ignoringOtherApps: true) }/' Sources/SerenaNet/Services/NotificationManager.swift

# But we need to make the function async, so let's fix that properly
cat > temp_notification_fix.swift << 'EOF'
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            let actionIdentifier = response.actionIdentifier
            
            switch actionIdentifier {
            case "VIEW_RESPONSE", "VIEW_TRANSCRIPTION":
                // Bring app to foreground and focus on chat
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: .focusMessageInput, object: nil)
                
            default:
                // Default action (tap on notification)
                NSApp.activate(ignoringOtherApps: true)
            }
            
            completionHandler()
        }
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
EOF

# Replace the notification delegate methods
sed -i '' '/nonisolated func userNotificationCenter(/,/^    }$/c\
    nonisolated func userNotificationCenter(\
        _ center: UNUserNotificationCenter,\
        didReceive response: UNNotificationResponse,\
        withCompletionHandler completionHandler: @escaping () -> Void\
    ) {\
        Task { @MainActor in\
            let actionIdentifier = response.actionIdentifier\
            \
            switch actionIdentifier {\
            case "VIEW_RESPONSE", "VIEW_TRANSCRIPTION":\
                // Bring app to foreground and focus on chat\
                NSApp.activate(ignoringOtherApps: true)\
                NotificationCenter.default.post(name: .focusMessageInput, object: nil)\
                \
            default:\
                // Default action (tap on notification)\
                NSApp.activate(ignoringOtherApps: true)\
            }\
            \
            completionHandler()\
        }\
    }\
    \
    nonisolated func userNotificationCenter(\
        _ center: UNUserNotificationCenter,\
        willPresent notification: UNNotification,\
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void\
    ) {\
        // Show notification even when app is in foreground\
        completionHandler([.banner, .sound, .badge])\
    }' Sources/SerenaNet/Services/NotificationManager.swift

echo ""
echo "✅ All remaining issues fixed!"
echo ""
echo "🚀 Ready to build SerenaNet:"
echo "   swift build"
echo ""