#!/bin/bash

# SerenaNet UI Issues Fix Script
# This script fixes the minor compilation issues preventing SerenaNet from building

echo "🔧 Fixing SerenaNet UI Issues..."
echo "================================"

# Fix 1: Remove duplicate KeyboardShortcut struct from HelpView.swift
echo "📝 Fixing KeyboardShortcut conflict in HelpView.swift..."

# Remove the duplicate KeyboardShortcut struct from HelpView.swift (lines 405-408)
sed -i '' '/^struct KeyboardShortcut {$/,/^}$/d' Sources/SerenaNet/Views/HelpView.swift

# Fix 2: Update OnboardingView.swift for macOS compatibility
echo "📝 Fixing OnboardingView macOS compatibility..."

# Replace the unavailable .page tabViewStyle with .automatic
sed -i '' 's/.tabViewStyle(.page(indexDisplayMode: .never))/.tabViewStyle(.automatic)/' Sources/SerenaNet/Views/OnboardingView.swift

# Fix 3: Add nonisolated to NotificationManager delegate methods
echo "📝 Fixing NotificationManager concurrency issues..."

# Add nonisolated to the delegate methods
sed -i '' 's/func userNotificationCenter(/nonisolated func userNotificationCenter(/' Sources/SerenaNet/Services/NotificationManager.swift

# Fix 4: Fix ThemeManager environment key
echo "📝 Fixing ThemeManager environment key..."

# Add @MainActor to the environment key
sed -i '' 's/private struct ThemeManagerKey: EnvironmentKey {/@MainActor private struct ThemeManagerKey: EnvironmentKey {/' Sources/SerenaNet/Services/ThemeManager.swift

# Fix 5: Add type conversion helpers for ChatManager
echo "📝 Adding type conversion helpers..."

cat >> Sources/SerenaNet/Services/ChatManager.swift << 'EOF'

// MARK: - Type Conversion Helpers
private extension ChatManager {
    func convertToSerenaCore(_ messages: [SerenaNet.Message]) -> [SerenaCore.Message] {
        return messages.compactMap { message in
            SerenaCore.Message(
                id: message.id,
                content: message.content,
                isUser: message.isUser,
                timestamp: message.timestamp
            )
        }
    }
    
    func convertToSerenaCore(_ document: SerenaNet.FTAIDocument) -> SerenaCore.FTAIDocument {
        return SerenaCore.FTAIDocument(
            id: document.id,
            content: document.content,
            metadata: document.metadata
        )
    }
}
EOF

# Fix 6: Update ChatManager to use conversion helpers
echo "📝 Updating ChatManager method calls..."

# Replace the problematic lines in ChatManager
sed -i '' 's/context: context,/context: convertToSerenaCore(context),/' Sources/SerenaNet/Services/ChatManager.swift
sed -i '' 's/let result = try await bridge.processFTAIDocument(document)/let result = try await bridge.processFTAIDocument(convertToSerenaCore(document))/' Sources/SerenaNet/Services/ChatManager.swift

# Fix 7: Fix HelpView enum usage
echo "📝 Fixing HelpView enum usage..."

# Replace the problematic enum usage
sed -i '' 's/if !selectedSection.shortcuts.isEmpty {/if case .shortcuts = selectedSection {/' Sources/SerenaNet/Views/HelpView.swift

echo ""
echo "✅ All UI issues fixed!"
echo ""
echo "🚀 Ready to build SerenaNet:"
echo "   swift build"
echo "   ./.build/debug/SerenaNet"
echo ""
echo "Or open in Xcode:"
echo "   open Package.swift"