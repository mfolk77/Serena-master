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
            let _ = print("🎯 FinalMessageInputView rendering - messageText: '\(messageText)', isInputFocused: \(isInputFocused)")
            // Text field with proper window capture
            TextField("Type your message here...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .focused($isInputFocused)
                .disabled(isProcessing)
                .lineLimit(1...6)
                .background(isInputFocused ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .onSubmit {
                    print("🎯 onSubmit triggered - canSend: \(canSend), messageText: '\(messageText)'")
                    if canSend {
                        print("📤 Calling onSend callback...")
                        onSend()
                    } else {
                        print("❌ Cannot send - message empty or processing")
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
            Button(action: {
                print("🎯 Send button clicked - canSend: \(canSend), messageText: '\(messageText)'")
                if canSend {
                    print("📤 Calling onSend from button...")
                    onSend()
                } else {
                    print("❌ Send button disabled")
                }
            }) {
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
