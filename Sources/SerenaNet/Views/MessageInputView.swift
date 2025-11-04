import SwiftUI

struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    @FocusState.Binding var isInputFocused: Bool

    let isProcessing: Bool
    let onSend: () -> Void
    let onVoiceInput: (() -> Void)?
    let isVoiceRecording: Bool
    let isVoiceAvailable: Bool
    
    @State private var textHeight: CGFloat = 20
    private let maxHeight: CGFloat = 120
    private let minHeight: CGFloat = 20
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text input area - FIXED VERSION
            TextField("Message SerenaNet...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .focused($isInputFocused)
                .disabled(isProcessing)
                .lineLimit(1...6)
                .onSubmit {
                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
                .onChange(of: messageText) { newValue in
                    updateComposingState()
                }
                .onAppear {
                    // Enhanced focus handling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Ensure window is active first
                        NSApp.activate(ignoringOtherApps: true)
                        
                        // Force focus on the text field
                        isInputFocused = true
                        
                        print("🎯 MessageInputView: Forced focus on text input")
                    }
                }
                .onTapGesture {
                    // Ensure focus when user taps the field
                    isInputFocused = true
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
            .help("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
    
    private func updateComposingState() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isComposing = !trimmed.isEmpty
    }
    
    private func updateTextHeight() {
        // Calculate text height for dynamic sizing
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let textStorage = NSTextStorage(string: messageText)
        let textContainer = NSTextContainer(containerSize: NSSize(width: 300, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(.font, value: font, range: NSRange(location: 0, length: textStorage.length))
        
        textContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: textContainer)
        
        let newHeight = max(minHeight, min(maxHeight, layoutManager.usedRect(for: textContainer).height))
        
        if abs(newHeight - textHeight) > 1 {
            withAnimation(.easeInOut(duration: 0.1)) {
                textHeight = newHeight
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        MessageInputView(
            messageText: .constant(""),
            isComposing: .constant(false),
            isInputFocused: FocusState<Bool>().projectedValue,
            isProcessing: false,
            onSend: {},
            onVoiceInput: {},
            isVoiceRecording: false,
            isVoiceAvailable: true
        )
    }
    .frame(width: 600, height: 400)
}