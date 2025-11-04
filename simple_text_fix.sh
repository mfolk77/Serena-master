#!/bin/bash

echo "🔧 Applying SIMPLE text input fix (no loops)..."

cd /Users/michaelfolk/Developer/Serena/SerenaMaster

# Kill any running Serena processes first
pkill -f SerenaNet 2>/dev/null || true

# Create a simple, non-looping text input component
echo "🔧 Creating simple text input component..."

cat > Sources/SerenaNet/Views/SimpleMessageInputView.swift << 'EOF'
import SwiftUI
import AppKit

struct SimpleMessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    @FocusState.Binding var isInputFocused: Bool

    let isProcessing: Bool
    let onSend: () -> Void
    let onVoiceInput: (() -> Void)?
    let isVoiceRecording: Bool
    let isVoiceAvailable: Bool
    
    @State private var hasTriedFocus = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Simple text field - NO AGGRESSIVE LOOPS
            TextField("Type your message here...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .focused($isInputFocused)
                .disabled(isProcessing)
                .lineLimit(1...6)
                .background(isInputFocused ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .onChange(of: messageText) { newValue in
                    updateComposingState()
                }
                .onAppear {
                    if !hasTriedFocus {
                        hasTriedFocus = true
                        simpleFocus()
                    }
                }
                .onTapGesture {
                    simpleFocus()
                }
            
            // Simple focus button - ONE CLICK ONLY
            Button("FOCUS") {
                print("🎯 Focus button clicked - ONE TIME ONLY")
                simpleFocus()
            }
            .foregroundColor(isInputFocused ? .green : .red)
            .help("Click once to focus text input")
            
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
    
    private func simpleFocus() {
        print("🎯 Simple focus - ONE ATTEMPT ONLY")
        
        // ONE simple focus attempt - NO LOOPS
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            isInputFocused = true
            print("🎯 Focus set: \(isInputFocused)")
        }
    }
}
EOF

echo "✅ Created simple text input component"

# Update ChatView to use the simple component
echo "🔧 Updating ChatView to use simple input..."

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
                            // Simple welcome message
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
                                    
                                    Text("Text field: GREEN = focused, RED = not focused")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                    
                                    Text("Click FOCUS button if text input doesn't work")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.top, 4)
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
                    // Auto-scroll to bottom when new messages arrive
                    if let lastMessage = chatManager.currentConversation?.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .background(themeManager.customColors.border)
            
            // SIMPLE message input area - NO LOOPS
            SimpleMessageInputView(
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
            print("🎯 ChatView appeared - simple focus")
            // ONE simple focus attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isInputFocused = true
                print("🎯 ChatView: Focus set (\(isInputFocused))")
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        print("📤 Sending message: \(trimmedMessage)")
        
        // Clear the input
        messageText = ""
        isComposing = false
        
        // Send the message through ChatManager
        Task {
            await chatManager.sendMessage(trimmedMessage)
        }
        
        // Simple focus restore - NO LOOPS
        isInputFocused = true
    }
    
    private func startVoiceInput() {
        print("🎤 Voice input requested")
        messageText = "Voice input placeholder - type to replace this"
        isInputFocused = true
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
        .frame(width: 600, height: 400)
}
EOF

echo "✅ Updated ChatView with simple input"

# Simplify the SerenaNetApp - NO COMPLEX FOCUS LOGIC
echo "🔧 Simplifying SerenaNetApp..."

cat > Sources/SerenaNet/SerenaNetApp.swift << 'EOF'
import SwiftUI
import SerenaCore

@main
struct SerenaNetApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var configManager = ConfigManager()
    
    init() {
        print("🚀 SerenaNet Starting (SIMPLE VERSION)...")
        
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
                .onAppear {
                    print("✅ SerenaNet UI loaded - NO COMPLEX FOCUS")
                    
                    // Record app startup completion
                    Task { @MainActor in
                        PerformanceMonitor.shared.recordAppStartupComplete()
                    }
                    
                    // SIMPLE window focus - ONE TIME ONLY
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        print("✅ App activated - done")
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
}
EOF

echo "✅ Simplified SerenaNetApp"

# Build the simple version
echo "🔨 Building simple version (no loops)..."
./build_with_rtai.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SIMPLE Text Input Fix Applied!"
    echo ""
    echo "🔧 What's Different:"
    echo "   • NO aggressive focus loops"
    echo "   • Simple one-time focus attempts"
    echo "   • Clear visual feedback:"
    echo "     - GREEN background = text field focused"
    echo "     - RED background = text field not focused"
    echo "   • FOCUS button for manual control"
    echo "   • Minimal debug messages"
    echo ""
    echo "🚀 To test:"
    echo "   ./run_serena_with_rtai.sh"
    echo ""
    echo "💡 Usage:"
    echo "   1. Look for GREEN or RED background in text field"
    echo "   2. If RED, click the FOCUS button ONCE"
    echo "   3. Should turn GREEN and accept text input"
    echo "   4. No more endless loop messages!"
    echo ""
    echo "Ready to test the simple version!"
else
    echo "❌ Build failed - check errors above"
fi