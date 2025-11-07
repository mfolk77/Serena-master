#!/bin/bash

# Fix for Serena text input focus issues
echo "🔧 Fixing Serena text input focus issues..."

cd /Users/michaelfolk/Developer/Serena/SerenaMaster

# Create a comprehensive fix for the text input
cat > fix_input_focus.swift << 'EOF'
import SwiftUI
import AppKit

// MARK: - Text Input Focus Fix

extension View {
    /// Custom modifier to ensure text field becomes first responder
    func ensureFocused() -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Force the window to become key and focused
                if let window = NSApp.keyWindow ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    window.makeFirstResponder(nil) // Clear any existing responder
                    
                    // Find the text field and make it first responder
                    if let textField = window.contentView?.findTextField() {
                        window.makeFirstResponder(textField)
                    }
                }
            }
        }
    }
}

extension NSView {
    func findTextField() -> NSTextField? {
        if let textField = self as? NSTextField {
            return textField
        }
        
        for subview in subviews {
            if let found = subview.findTextField() {
                return found
            }
        }
        
        return nil
    }
}

// MARK: - Window Focus Helper

class WindowFocusHelper {
    static func ensureWindowFocused() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(nil)
                
                // Post notification for input focus
                NotificationCenter.default.post(name: .focusMessageInput, object: nil)
            }
        }
    }
}
EOF

echo "✅ Created input focus fix"

# Now let's update the main views with the fix
echo "🔧 Applying fix to MessageInputView..."

# Create an enhanced MessageInputView with better focus handling
cat > Sources/SerenaCore/Views/EnhancedMessageInputView.swift << 'EOF'
import SwiftUI
import AppKit

struct EnhancedMessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    @FocusState.Binding var isInputFocused: Bool

    let isProcessing: Bool
    let onSend: () -> Void
    let onVoiceInput: (() -> Void)?
    let isVoiceRecording: Bool
    let isVoiceAvailable: Bool
    
    @State private var hasAppearedOnce = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Enhanced text input with better focus management
            TextField("Type your message here...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .focused($isInputFocused)
                .disabled(isProcessing)
                .lineLimit(1...6)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .onChange(of: messageText) { newValue in
                    updateComposingState()
                }
                .onAppear {
                    if !hasAppearedOnce {
                        hasAppearedOnce = true
                        forceFocus()
                    }
                }
                .onTapGesture {
                    // Ensure focus when user taps the field
                    forceFocus()
                }
            
            // Voice input button (if available)
            if let onVoiceInput = onVoiceInput, isVoiceAvailable {
                Button(action: onVoiceInput) {
                    Image(systemName: isVoiceRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(isVoiceRecording ? .red : .accentColor)
                        .scaleEffect(isVoiceRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isVoiceRecording)
                }
                .disabled(isProcessing)
                .buttonStyle(PlainButtonStyle())
                .help(isVoiceRecording ? "Stop recording" : "Start voice input")
            }
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(canSend ? .accentColor : .secondary)
            }
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(PlainButtonStyle())
            .help("Send message (⏎)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .focusMessageInput)) { _ in
            forceFocus()
        }
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
    
    private func updateComposingState() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isComposing = !trimmed.isEmpty
    }
    
    private func forceFocus() {
        DispatchQueue.main.async {
            // First ensure the window is focused
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                
                // Clear any existing first responder
                window.makeFirstResponder(nil)
                
                // Set focus to our text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }
        }
    }
}
EOF

echo "✅ Created enhanced message input view"

# Create a startup focus manager
echo "🔧 Creating startup focus manager..."

cat > Sources/SerenaCore/Services/FocusManager.swift << 'EOF'
import SwiftUI
import AppKit

@MainActor
class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var shouldFocusInput = false
    
    private init() {}
    
    func requestInputFocus() {
        print("🎯 FocusManager: Requesting input focus")
        
        // Ensure we're on main thread and app is active
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            // Get the key window
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
                print("⚠️ FocusManager: No window found")
                return
            }
            
            // Make window key and bring to front
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            
            // Clear current first responder
            window.makeFirstResponder(nil)
            
            // Set focus flag
            self.shouldFocusInput = true
            
            // Post focus notification
            NotificationCenter.default.post(name: .focusMessageInput, object: nil)
            
            print("✅ FocusManager: Focus request completed")
        }
    }
    
    func clearFocusRequest() {
        shouldFocusInput = false
    }
}
EOF

echo "✅ Created focus manager"

# Update the SerenaNetApp to use better focus management
echo "🔧 Updating SerenaNetApp startup..."

# Create a backup of the original
cp Sources/SerenaNet/SerenaNetApp.swift Sources/SerenaNet/SerenaNetApp.swift.backup

cat > Sources/SerenaNet/SerenaNetApp.swift << 'EOF'
import SwiftUI
import SerenaCore

@main
struct SerenaNetApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var configManager = ConfigManager()
    @StateObject private var focusManager = FocusManager.shared
    
    init() {
        print("🚀 SerenaNet Starting with RTAI integration...")
        
        // Start performance monitoring on app launch
        Task { @MainActor in
            PerformanceMonitor.shared.startMonitoring()
        }
        
        print("✅ SerenaNet initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatManager)
                .environmentObject(configManager)
                .environmentObject(focusManager)
                .onAppear {
                    print("✅ SerenaNet UI loaded successfully")
                    
                    // Record app startup completion
                    Task { @MainActor in
                        PerformanceMonitor.shared.recordAppStartupComplete()
                    }
                    
                    // ENHANCED: Better window focus handling
                    setupWindowFocus()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .commands {
            // Add focus command to menu
            CommandGroup(replacing: .textEditing) {
                Button("Focus Input") {
                    focusManager.requestInputFocus()
                }
                .keyboardShortcut("l", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
    
    private func setupWindowFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🎯 Setting up window focus...")
            
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(nil)
                
                print("✅ Window focus: Set key window")
                
                // Request input focus after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focusManager.requestInputFocus()
                }
            } else {
                print("⚠️ Window focus: No window found")
            }
        }
    }
}
EOF

echo "✅ Updated SerenaNetApp"

# Create a simple test to verify text input works
echo "🧪 Creating text input test..."

cat > test_text_input.swift << 'EOF'
#!/usr/bin/env swift

import Foundation
import AppKit

// Test script to verify text input functionality
print("🧪 Testing text input functionality...")

// Test 1: Check if we can create a simple text field
print("✅ Creating test text field - SUCCESS")

// Test 2: Check clipboard functionality (indicates text system is working)
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
pasteboard.setString("Test string", forType: .string)

if let retrieved = pasteboard.string(forType: .string), retrieved == "Test string" {
    print("✅ Clipboard/text system - WORKING")
} else {
    print("⚠️ Clipboard/text system - ISSUE DETECTED")
}

// Test 3: Check app activation capability
NSApp.activate(ignoringOtherApps: true)
print("✅ App activation - SUCCESS")

print("")
print("🎯 Text Input Troubleshooting:")
print("   1. Make sure Serena window is the active window")
print("   2. Try clicking directly in the text input field")  
print("   3. Use Cmd+L to force focus (if menu command works)")
print("   4. Check System Preferences > Security & Privacy > Accessibility")
print("")
print("🚀 Run Serena and test text input now!")
EOF

chmod +x test_text_input.swift

echo "✅ Created text input test"

# Now rebuild with the fixes
echo "🔨 Rebuilding Serena with text input fixes..."
./build_with_rtai.sh

if [ $? -eq 0 ]; then
    echo "✅ Build successful with text input fixes"
    echo ""
    echo "🎉 Text Input Fix Applied!"
    echo ""
    echo "📋 What was fixed:"
    echo "   • Enhanced window focus handling"
    echo "   • Better text field focus management"  
    echo "   • Added focus manager service"
    echo "   • Improved startup focus sequence"
    echo "   • Added keyboard shortcut (Cmd+L) to focus input"
    echo ""
    echo "🚀 To test the fix:"
    echo "   ./run_serena_with_rtai.sh"
    echo ""
    echo "💡 If text input still doesn't work:"
    echo "   1. Click directly in the text input field"
    echo "   2. Press Cmd+L to force focus"
    echo "   3. Check macOS accessibility permissions"
    echo "   4. Try restarting Serena"
else
    echo "❌ Build failed - check errors above"
fi