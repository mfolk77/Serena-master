#!/bin/bash

# Aggressive fix for Serena text input issues
echo "🔧 Applying aggressive text input fix..."

cd /Users/michaelfolk/Developer/Serena/SerenaMaster

# First, let's check if there are any system-level issues
echo "🔍 Checking system text input capabilities..."

# Test basic text input
osascript << 'EOF'
tell application "System Events"
    try
        set textInputEnabled to (do shell script "echo 'Text input test'")
        return "Text input system available"
    on error
        return "Text input system error"
    end try
end tell
EOF

echo "✅ System check complete"

# Create a completely new MessageInputView that forces focus more aggressively
echo "🔧 Creating enhanced text input component..."

cat > Sources/SerenaNet/Views/FixedMessageInputView.swift << 'EOF'
import SwiftUI
import AppKit

struct FixedMessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    @FocusState.Binding var isInputFocused: Bool

    let isProcessing: Bool
    let onSend: () -> Void
    let onVoiceInput: (() -> Void)?
    let isVoiceRecording: Bool
    let isVoiceAvailable: Bool
    
    @State private var textFieldID = UUID()
    @State private var forceRefreshID = UUID()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // AGGRESSIVE TEXT FIELD with multiple focus strategies
            ZStack {
                // Hidden backup text field
                TextField("", text: .constant(""))
                    .opacity(0.01)
                    .allowsHitTesting(false)
                
                // Main text field with aggressive focus
                TextField("Type your message here... (click if not focused)", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .focused($isInputFocused)
                    .disabled(isProcessing)
                    .lineLimit(1...6)
                    .id(textFieldID)
                    .background(isInputFocused ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isInputFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .onSubmit {
                        if canSend {
                            onSend()
                        }
                    }
                    .onChange(of: messageText) { newValue in
                        updateComposingState()
                    }
                    .onAppear {
                        aggressiveFocus()
                    }
                    .onTapGesture {
                        print("🎯 Text field tapped - forcing focus")
                        aggressiveFocus()
                    }
                    .gesture(
                        // Additional gesture handling
                        TapGesture()
                            .onEnded { _ in
                                aggressiveFocus()
                            }
                    )
            }
            
            // Focus button (visible helper)
            Button(action: {
                print("🎯 Focus button pressed")
                aggressiveFocus()
            }) {
                Image(systemName: isInputFocused ? "target" : "target.dashed")
                    .font(.title2)
                    .foregroundColor(isInputFocused ? .green : .orange)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Click to focus text input")
            
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
            print("🎯 Focus notification received")
            aggressiveFocus()
        }
        .id(forceRefreshID)
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
    
    private func updateComposingState() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isComposing = !trimmed.isEmpty
    }
    
    private func aggressiveFocus() {
        print("🎯 AGGRESSIVE FOCUS: Starting focus sequence")
        
        DispatchQueue.main.async {
            // Step 1: Activate the application
            NSApp.activate(ignoringOtherApps: true)
            print("🎯 Step 1: App activated")
            
            // Step 2: Get and activate window
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
                print("❌ No window found for focus")
                return
            }
            
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.makeFirstResponder(nil)
            print("🎯 Step 2: Window focused")
            
            // Step 3: Force text field focus with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
                print("🎯 Step 3: Text field focused (\(isInputFocused))")
                
                // Step 4: Refresh the text field ID to force recreation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    textFieldID = UUID()
                    forceRefreshID = UUID()
                    print("🎯 Step 4: Text field refreshed")
                    
                    // Step 5: Final focus attempt
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isInputFocused = true
                        print("🎯 Step 5: Final focus attempt (\(isInputFocused))")
                    }
                }
            }
        }
    }
}
EOF

echo "✅ Created enhanced text input component"

# Update ChatView to use the new fixed component
echo "🔧 Updating ChatView to use fixed input..."

# Backup original
cp Sources/SerenaNet/Views/ChatView.swift Sources/SerenaNet/Views/ChatView.swift.backup

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
                            // Welcome message when no conversation is selected
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
                                    
                                    Text("Click the text field below to start typing.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                    
                                    if !isInputFocused {
                                        Text("⚠️ If text input doesn't work, click the target button (🎯)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.top, 4)
                                    }
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
            
            // FIXED message input area
            FixedMessageInputView(
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
            print("🎯 ChatView appeared - setting up focus")
            // Initial focus attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
                print("🎯 ChatView: Initial focus set (\(isInputFocused))")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusMessageInput)) { _ in
            print("🎯 ChatView: Received focus notification")
            isInputFocused = true
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
        
        // Keep focus on input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
        }
    }
    
    private func startVoiceInput() {
        print("🎤 Voice input requested")
        // TODO: Implement voice input
        // For now, just show a placeholder message
        messageText = "Voice input activated (placeholder)"
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
        .frame(width: 600, height: 400)
}
EOF

echo "✅ Updated ChatView with fixed input"

# Also update the SerenaNetApp to have working menu commands
echo "🔧 Fixing menu commands..."

cat > Sources/SerenaNet/SerenaNetApp.swift << 'EOF'
import SwiftUI
import SerenaCore

@main
struct SerenaNetApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var configManager = ConfigManager()
    
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
            CommandGroup(replacing: .textEditing) {
                Button("Focus Input Field") {
                    print("🎯 Menu: Focus Input Field requested")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .focusMessageInput, object: nil)
                    }
                }
                .keyboardShortcut("l", modifiers: .command)
                
                Button("Reset Window Focus") {
                    print("🎯 Menu: Reset Window Focus requested")
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
                            window.makeKeyAndOrderFront(nil)
                            window.orderFrontRegardless()
                            window.makeFirstResponder(nil)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                NotificationCenter.default.post(name: .focusMessageInput, object: nil)
                            }
                        }
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Button("Force App Activation") {
                    print("🎯 Menu: Force App Activation requested")
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        
                        // Force bring all windows to front
                        for window in NSApplication.shared.windows {
                            window.orderFrontRegardless()
                            window.makeKeyAndOrderFront(nil)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .focusMessageInput, object: nil)
                        }
                    }
                }
                .keyboardShortcut("a", modifiers: [.command, .option])
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
    
    private func setupWindowFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            print("🎯 SerenaNetApp: Setting up window focus...")
            
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(nil)
                
                print("✅ Window focus: Set key window")
                
                // Post focus notification after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .focusMessageInput, object: nil)
                    print("✅ Window focus: Posted focus notification")
                }
            } else {
                print("⚠️ Window focus: No window found")
            }
        }
    }
}
EOF

echo "✅ Updated SerenaNetApp with working menu commands"

# Build with the new fixes
echo "🔨 Building with aggressive fixes..."
./build_with_rtai.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Aggressive Text Input Fix Applied!"
    echo ""
    echo "🔧 What's New:"
    echo "   • Completely rewritten text input component"
    echo "   • Visible focus helper button (🎯 target icon)"
    echo "   • Multiple focus recovery strategies"
    echo "   • Working menu commands"
    echo "   • Enhanced debug logging"
    echo ""
    echo "🎯 New Controls:"
    echo "   • Target button (🎯) - Click to force focus"
    echo "   • Cmd+L - Focus input field"
    echo "   • Cmd+Shift+R - Reset window focus"
    echo "   • Cmd+Option+A - Force app activation"
    echo ""
    echo "🚀 To test:"
    echo "   ./run_serena_with_rtai.sh"
    echo ""
    echo "💡 Look for:"
    echo "   • Target button turns GREEN when focused"
    echo "   • Blue border around text field when focused"
    echo "   • Debug messages in terminal"
    echo ""
    echo "If STILL not working, try clicking the target button (🎯)!"
else
    echo "❌ Build failed - check errors above"
fi