#!/bin/bash

echo "🔧 Fixing keyboard input capture (text going to terminal instead of GUI)..."

cd /Users/michaelfolk/Developer/Serena/SerenaMaster

# This is a window focus and input routing issue
# Text is being captured by terminal instead of the GUI window

echo "🔧 Creating window focus manager..."

# Create a proper window focus and input capture system
cat > Sources/SerenaNet/Views/FinalMessageInputView.swift << 'EOF'
import SwiftUI
import AppKit

struct FinalMessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    @FocusState.Binding var isInputFocused: Bool

    let isProcessing: Bool
    let onSend: () -> Void
    let onVoiceInput: (() -> Void)?
    let isVoiceRecording: Bool
    let isVoiceAvailable: Bool
    
    @State private var windowCapture = WindowCaptureHelper()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text field with proper window capture
            TextField("Type your message here...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .focused($isInputFocused)
                .disabled(isProcessing)
                .lineLimit(1...6)
                .background(isInputFocused ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .onChange(of: messageText) { newValue in
                    updateComposingState()
                    print("✅ Text changed in GUI: '\(newValue)'")
                }
                .onAppear {
                    setupWindowCapture()
                }
                .onTapGesture {
                    print("🎯 Text field tapped")
                    captureWindowInput()
                }
            
            // Window capture button
            Button("CAPTURE") {
                print("🎯 Capture button pressed")
                captureWindowInput()
            }
            .foregroundColor(isInputFocused ? .green : .red)
            .help("Click to capture keyboard input to GUI")
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(canSend ? .accentColor : .secondary)
            }
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(PlainButtonStyle())
            .help("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
    
    private func updateComposingState() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isComposing = !trimmed.isEmpty
    }
    
    private func setupWindowCapture() {
        print("🎯 Setting up window capture")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            captureWindowInput()
        }
    }
    
    private func captureWindowInput() {
        print("🎯 Capturing window input...")
        
        DispatchQueue.main.async {
            // Step 1: Activate the application
            NSApp.activate(ignoringOtherApps: true)
            print("🎯 Step 1: App activated")
            
            // Step 2: Get the window and make it key
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
                print("❌ No window found")
                return
            }
            
            // Make window key and front
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            
            // CRITICAL: Ensure window accepts key input
            window.makeFirstResponder(window.contentView)
            
            print("🎯 Step 2: Window made key and first responder set")
            
            // Step 3: Set text field focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isInputFocused = true
                print("🎯 Step 3: Text field focused")
                
                // Step 4: Verify input routing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let keyWindow = NSApp.keyWindow {
                        print("✅ Key window: \(keyWindow)")
                        print("✅ First responder: \(keyWindow.firstResponder?.description ?? "none")")
                        print("✅ Can become key: \(keyWindow.canBecomeKey)")
                        print("✅ Is key window: \(keyWindow.isKeyWindow)")
                    }
                }
            }
        }
    }
}

// Helper class for window management
class WindowCaptureHelper: ObservableObject {
    func ensureWindowFocus() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(window.contentView)
            }
        }
    }
}
EOF

echo "✅ Created final message input with window capture"

# Update ChatView to use the new component
echo "🔧 Updating ChatView with window capture..."

cat > Sources/SerenaNet/Views/ChatView.swift << 'EOF'
import SwiftUI
import SerenaCore

struct ChatView: View {
    @EnvironmentObject private var chatManager: ChatManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var messageText = ""
    @State private var isComposing = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if let conversation = chatManager.currentConversation {
                            ForEach(conversation.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        } else {
                            // Welcome message
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 64))
                                    .foregroundColor(themeManager.customColors.primary.opacity(0.6))
                                
                                VStack(spacing: 8) {
                                    Text("Welcome to SerenaNet")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.customColors.primary)
                                    
                                    Text("🦀 Powered by FolkTech RTAI")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("Your AI assistant is ready to help.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    if isInputFocused {
                                        Text("✅ Keyboard input captured - type in the text field below")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                    } else {
                                        Text("⚠️ Click CAPTURE button to route keyboard to GUI")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .fontWeight(.medium)
                                    }
                                    
                                    Text("If text appears in terminal instead of here, click CAPTURE")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(themeManager.customColors.background)
                .onChange(of: chatManager.currentConversation?.messages.count) { _ in
                    if let lastMessage = chatManager.currentConversation?.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .background(themeManager.customColors.border)
            
            // FINAL message input with window capture
            FinalMessageInputView(
                messageText: $messageText,
                isComposing: $isComposing,
                isInputFocused: $isInputFocused,
                isProcessing: chatManager.isProcessing,
                onSend: sendMessage,
                onVoiceInput: startVoiceInput,
                isVoiceRecording: false, 
                isVoiceAvailable: true
            )
            .background(themeManager.customColors.surface)
        }
        .onAppear {
            print("🎯 ChatView appeared - setting up window capture")
            setupWindowCapture()
        }
        .background(Color.clear)
        .onTapGesture {
            // Capture input when anywhere in chat is tapped
            print("🎯 ChatView tapped - capturing input")
            setupWindowCapture()
        }
    }
    
    private func setupWindowCapture() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(window.contentView)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                    print("🎯 ChatView: Window capture setup complete")
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        print("📤 Sending message from GUI: \(trimmedMessage)")
        
        // Clear the input
        messageText = ""
        isComposing = false
        
        // Send the message through ChatManager
        Task {
            await chatManager.sendMessage(trimmedMessage)
        }
        
        // Maintain input capture
        isInputFocused = true
    }
    
    private func startVoiceInput() {
        print("🎤 Voice input requested")
        messageText = "Voice input placeholder - replace with your message"
        isInputFocused = true
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
        .frame(width: 600, height: 400)
}
EOF

echo "✅ Updated ChatView with window capture"

# Also update the SerenaNetApp to ensure proper window setup
echo "🔧 Updating SerenaNetApp for proper window management..."

cat > Sources/SerenaNet/SerenaNetApp.swift << 'EOF'
import SwiftUI
import SerenaCore
import AppKit

@main
struct SerenaNetApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var configManager = ConfigManager()
    
    init() {
        print("🚀 SerenaNet Starting (WINDOW CAPTURE VERSION)...")
        
        // Configure window behavior
        setupWindowBehavior()
        
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
                .onAppear {
                    print("✅ SerenaNet UI loaded - setting up window capture")
                    setupProperWindowFocus()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
    
    private func setupWindowBehavior() {
        // Ensure windows can become key and accept input
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
        }
    }
    
    private func setupProperWindowFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🎯 Setting up proper window focus for input capture...")
            
            // Activate app
            NSApp.activate(ignoringOtherApps: true)
            
            // Get window and ensure it can capture input
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                
                // CRITICAL: Set window to accept key events
                window.makeFirstResponder(window.contentView)
                
                // Ensure window level is appropriate
                window.level = .normal
                
                print("✅ Window setup for input capture complete")
                print("   - Window is key: \(window.isKeyWindow)")
                print("   - Can become key: \(window.canBecomeKey)")
                print("   - First responder: \(window.firstResponder?.description ?? "none")")
            } else {
                print("⚠️ No window found for setup")
            }
        }
    }
}
EOF

echo "✅ Updated SerenaNetApp with window capture setup"

# Build with the window capture fix
echo "🔨 Building with window capture fix..."
./build_with_rtai.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 KEYBOARD CAPTURE FIX APPLIED!"
    echo ""
    echo "🔧 What's Fixed:"
    echo "   • Proper window focus and input capture"
    echo "   • Text should now appear in GUI instead of terminal"
    echo "   • CAPTURE button to force input routing"
    echo "   • Enhanced window management"
    echo "   • Debug info to track input routing"
    echo ""
    echo "🚀 To test:"
    echo "   ./run_serena_with_rtai.sh"
    echo ""
    echo "💡 What to try:"
    echo "   1. Wait for green background in text field"
    echo "   2. Click CAPTURE button if needed"
    echo "   3. Type - text should appear in GUI now"
    echo "   4. If still going to terminal, click anywhere in GUI first"
    echo ""
    echo "🎯 Debug info will show if window is capturing input properly"
else
    echo "❌ Build failed - check errors above"
fi