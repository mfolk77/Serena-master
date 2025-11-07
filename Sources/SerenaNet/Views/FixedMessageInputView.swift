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
