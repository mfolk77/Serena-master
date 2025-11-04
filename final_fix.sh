#!/bin/bash

# SerenaNet Final Fix Script
# This script fixes all remaining compilation issues

echo "🔧 Final SerenaNet Fixes..."
echo "=========================="

# Fix 1: Simplify ChatManager conversion - remove complex schema conversion
echo "📝 Simplifying ChatManager type conversion..."

cat > temp_chatmanager_fix.swift << 'EOF'
// MARK: - Type Conversion Helpers
private extension ChatManager {
    func convertToSerenaCore(_ messages: [Message]) -> [SerenaCore.Message] {
        return messages.map { message in
            SerenaCore.Message(
                id: message.id,
                content: message.content,
                role: SerenaCore.MessageRole(rawValue: message.role.rawValue) ?? .assistant,
                timestamp: message.timestamp
            )
        }
    }
    
    func convertToSerenaCore(_ document: FTAIDocument) -> SerenaCore.FTAIDocument {
        return SerenaCore.FTAIDocument(
            version: document.version,
            metadata: document.metadata,
            content: document.content
        )
    }
}
EOF

# Replace the conversion helpers section
sed -i '' '/\/\/ MARK: - Type Conversion Helpers/,$d' Sources/SerenaNet/Services/ChatManager.swift

cat temp_chatmanager_fix.swift >> Sources/SerenaNet/Services/ChatManager.swift
rm temp_chatmanager_fix.swift

# Fix 2: Clean up NotificationManager - remove duplicate methods
echo "📝 Fixing NotificationManager duplicates..."

# Remove everything after the first nonisolated func and rebuild properly
sed -i '' '/nonisolated func userNotificationCenter(/,$d' Sources/SerenaNet/Services/NotificationManager.swift

cat >> Sources/SerenaNet/Services/NotificationManager.swift << 'EOF'
    func userNotificationCenter(
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
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
EOF

# Fix 3: Fix ThemeManager environment key with @preconcurrency
echo "📝 Fixing ThemeManager environment key..."

sed -i '' 's/private struct ThemeManagerKey: EnvironmentKey {/@preconcurrency private struct ThemeManagerKey: EnvironmentKey {/' Sources/SerenaNet/Services/ThemeManager.swift
sed -i '' 's/@MainActor static let defaultValue/static let defaultValue/' Sources/SerenaNet/Services/ThemeManager.swift

# Fix 4: Remove @MainActor from notification handlers (causes issues)
echo "📝 Fixing notification handler concurrency..."

sed -i '' 's/) { @MainActor \[weak self\] _ in/) { [weak self] _ in/' Sources/SerenaNet/Services/WindowManager.swift
sed -i '' 's/) { @MainActor \[weak self\] notification in/) { [weak self] notification in/' Sources/SerenaNet/Services/WindowManager.swift
sed -i '' 's/) { @MainActor \[weak self\] _ in/) { [weak self] _ in/' Sources/SerenaNet/Services/AccessibilityManager.swift

# Fix 5: Add Task wrapper for main actor calls in notification handlers
echo "📝 Adding Task wrappers for main actor calls..."

# WindowManager fixes
sed -i '' 's/self?.isFullScreen = true/Task { @MainActor in self?.isFullScreen = true }/' Sources/SerenaNet/Services/WindowManager.swift
sed -i '' 's/self?.isFullScreen = false/Task { @MainActor in self?.isFullScreen = false }/' Sources/SerenaNet/Services/WindowManager.swift
sed -i '' 's/self?.windowFrame = window.frame/Task { @MainActor in self?.windowFrame = window.frame }/' Sources/SerenaNet/Services/WindowManager.swift

# AccessibilityManager fixes
sed -i '' 's/self?.updateAccessibilitySettings()/Task { @MainActor in self?.updateAccessibilitySettings() }/' Sources/SerenaNet/Services/AccessibilityManager.swift
sed -i '' 's/self?.updateContentSizeCategory()/Task { @MainActor in self?.updateContentSizeCategory() }/' Sources/SerenaNet/Services/AccessibilityManager.swift

echo ""
echo "✅ All final fixes applied!"
echo ""
echo "🚀 Ready to build SerenaNet:"
echo "   swift build"
echo ""