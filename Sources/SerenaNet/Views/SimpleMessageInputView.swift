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
