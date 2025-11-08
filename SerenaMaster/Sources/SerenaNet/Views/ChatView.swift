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
            let _ = print("🎯 ChatView rendering - messageText: '\(messageText)', currentConversation: \(chatManager.currentConversation?.id.uuidString ?? "none")")
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
                                    
                                    // System Status Debug Info
                                    VStack(spacing: 2) {
                                        Text("🔧 DEBUG STATUS:")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        
                                        Text("• Response System: ✅ Direct Pattern Matching")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Text("• RTAI Enabled: \(chatManager.networkConnectivityManager.isConnected ? "✅" : "❌") (Check Settings)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        
                                        if isInputFocused {
                                            Text("• Keyboard Input: ✅ CAPTURED")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("• Keyboard Input: ❌ NOT CAPTURED")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        
                                        Text("• Test Message: Try typing 'hello' and press Enter")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .italic()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    
                                    if !isInputFocused {
                                        Text("⚠️ Click CAPTURE button to route keyboard to GUI")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .fontWeight(.medium)
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
        guard !trimmedMessage.isEmpty else { 
            print("❌ ChatView.sendMessage: Empty message, not sending")
            return 
        }
        
        print("📤 ChatView.sendMessage: Sending message from GUI: \(trimmedMessage)")
        
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
