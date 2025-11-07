#!/bin/bash

echo "🔧 Creating Minimal SerenaNet Version"
echo "===================================="

# Create a backup of the original app
cp Sources/SerenaNet/SerenaNetApp.swift Sources/SerenaNet/SerenaNetApp_Backup.swift

# Create a minimal version without UserNotifications
cat > Sources/SerenaNet/SerenaNetApp.swift << 'EOF'
import SwiftUI

@main
struct SerenaNetApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var configManager = ConfigManager()
    
    init() {
        print("🚀 SerenaNet Minimal Launch")
        print("===========================")
        
        // Skip UserNotifications for now to avoid crashes
        print("✅ App initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            MinimalContentView()
                .environmentObject(chatManager)
                .environmentObject(configManager)
                .onAppear {
                    print("✅ Main window appeared")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct MinimalContentView: View {
    @EnvironmentObject private var chatManager: ChatManager
    @EnvironmentObject private var configManager: ConfigManager
    @State private var messageText = ""
    @State private var messages: [String] = [
        "🤖 Welcome to SerenaNet!",
        "Your AI assistant is ready to help.",
        "This is a minimal version to test the UI."
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("SerenaNet MVP")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("AI Assistant - Minimal Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Chat Area
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        MessageRow(message: message, isUser: index % 2 == 1)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            // Input Area
            HStack {
                TextField("Type your message here...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("Send") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(messageText.isEmpty)
                
                Button(action: {
                    // Voice input simulation
                    addMessage("🎤 Voice input activated", isUser: true)
                    simulateAIResponse("I heard your voice input!")
                }) {
                    Image(systemName: "mic.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            print("✅ Minimal UI loaded successfully")
            print("📝 You can now interact with SerenaNet!")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        print("📤 User message: \(messageText)")
        addMessage(messageText, isUser: true)
        
        let userMessage = messageText
        messageText = ""
        
        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            simulateAIResponse(userMessage)
        }
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        messages.append(text)
    }
    
    private func simulateAIResponse(_ userMessage: String) {
        let responses = [
            "I understand you said: '\(userMessage)'. How can I help further?",
            "That's interesting! Tell me more about '\(userMessage)'.",
            "I'm processing your request about '\(userMessage)'. Here's what I think...",
            "Thanks for sharing '\(userMessage)'. Let me provide some insights.",
            "I see you mentioned '\(userMessage)'. Would you like me to elaborate on that?"
        ]
        
        let response = responses.randomElement() ?? "I received your message about '\(userMessage)'."
        addMessage("🤖 " + response, isUser: false)
        
        print("🤖 AI response generated")
    }
}

struct MessageRow: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
                Text(message)
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: 300, alignment: .trailing)
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                Text(message)
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: 300, alignment: .leading)
                Spacer()
            }
        }
    }
}
EOF

echo "✅ Minimal version created"
echo ""
echo "🔨 Building minimal SerenaNet..."
swift build

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 BUILD SUCCESSFUL!"
    echo ""
    echo "🚀 Launching SerenaNet Minimal..."
    echo "   This should open a working chat window!"
    echo ""
    
    # Launch the app
    ./.build/debug/SerenaNet
    
else
    echo "❌ Build failed"
    
    # Restore backup if build failed
    if [ -f "Sources/SerenaNet/SerenaNetApp_Backup.swift" ]; then
        mv Sources/SerenaNet/SerenaNetApp_Backup.swift Sources/SerenaNet/SerenaNetApp.swift
        echo "📝 Restored original app file"
    fi
fi