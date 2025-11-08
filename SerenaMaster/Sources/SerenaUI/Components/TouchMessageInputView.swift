import SwiftUI
import SerenaCore
#if canImport(UIKit)
import UIKit
#endif

/// iPad-optimized message input with touch-friendly controls and gesture support
public struct TouchMessageInputView: View {
    @Binding var messageText: String
    @Binding var isComposing: Bool
    
    let isProcessing: Bool
    let isVoiceRecording: Bool
    let isVoiceAvailable: Bool
    
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    let onAttachment: (() -> Void)?
    
    @Environment(\.platformConfiguration) private var platformConfig
    @FocusState private var isInputFocused: Bool
    @State private var inputHeight: CGFloat = 44
    @State private var showingVoiceInput = false
    
    private let maxInputHeight: CGFloat = 120
    private let minInputHeight: CGFloat = 44
    
    public init(
        messageText: Binding<String>,
        isComposing: Binding<Bool>,
        isProcessing: Bool,
        isVoiceRecording: Bool,
        isVoiceAvailable: Bool,
        onSend: @escaping () -> Void,
        onVoiceInput: @escaping () -> Void,
        onAttachment: (() -> Void)? = nil
    ) {
        self._messageText = messageText
        self._isComposing = isComposing
        self.isProcessing = isProcessing
        self.isVoiceRecording = isVoiceRecording
        self.isVoiceAvailable = isVoiceAvailable
        self.onSend = onSend
        self.onVoiceInput = onVoiceInput
        self.onAttachment = onAttachment
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Typing indicator or processing state
            if isProcessing {
                processingIndicator
            }
            
            Divider()
            
            // Main input area
            HStack(alignment: .bottom, spacing: 12) {
                // Attachment button (if provided)
                if let onAttachment = onAttachment {
                    attachmentButton(action: onAttachment)
                }
                
                // Text input area
                textInputArea
                
                // Voice/Send button
                actionButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.background)
        }
        .sheet(isPresented: $showingVoiceInput) {
            voiceInputSheet
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var processingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("SerenaNet is thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.gray.opacity(0.1))
    }
    
    @ViewBuilder
    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.gray.opacity(0.1))
                .frame(minHeight: minInputHeight)
            
            // Placeholder
            if messageText.isEmpty {
                Text("Message SerenaNet...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
            
            // Text editor
            TextEditor(text: $messageText)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .font(.body)
                .onChange(of: messageText) { newValue in
                    isComposing = !newValue.isEmpty
                    updateInputHeight()
                }
                .onTapGesture {
                    isInputFocused = true
                }
        }
        .frame(minHeight: minInputHeight, maxHeight: min(inputHeight, maxInputHeight))
        .animation(.easeInOut(duration: 0.2), value: inputHeight)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if isComposing && !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Send button
            TouchFriendlyButton(
                "",
                systemImage: "paperplane.fill",
                style: .primary
            ) {
                onSend()
            }
            .frame(width: buttonSize, height: buttonSize)
        } else if isVoiceAvailable {
            // Voice button
            TouchFriendlyButton(
                "",
                systemImage: isVoiceRecording ? "stop.fill" : "mic.fill",
                style: isVoiceRecording ? .destructive : .secondary
            ) {
                if platformConfig.platform == .iPadOS {
                    showingVoiceInput = true
                } else {
                    onVoiceInput()
                }
            }
            .frame(width: buttonSize, height: buttonSize)
        }
    }
    
    @ViewBuilder
    private func attachmentButton(action: @escaping () -> Void) -> some View {
        TouchFriendlyButton(
            "",
            systemImage: "plus",
            style: .minimal
        ) {
            action()
        }
        .frame(width: buttonSize, height: buttonSize)
    }
    
    @ViewBuilder
    private var voiceInputSheet: some View {
        TouchVoiceInputView(
            isRecording: .constant(isVoiceRecording),
            transcription: $messageText,
            onStartRecording: {
                onVoiceInput()
            },
            onStopRecording: {
                onVoiceInput()
            },
            onSendTranscription: {
                showingVoiceInput = false
                onSend()
            },
            onCancel: {
                showingVoiceInput = false
            }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Computed Properties
    
    private var cornerRadius: CGFloat {
        PlatformManager.shared.preferredCornerRadius
    }
    
    private var buttonSize: CGFloat {
        switch platformConfig.platform {
        case .iPadOS:
            return 44
        case .iOS:
            return 36
        case .macOS:
            return 32
        case .unknown:
            return 32
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateInputHeight() {
        let textHeight = messageText.boundingRect(
            with: CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [:],
            context: nil
        ).height
        
        let newHeight = max(minInputHeight, textHeight + 24) // 24 for padding
        inputHeight = min(newHeight, maxInputHeight)
    }
}

/// Gesture-enhanced message bubble for iPad
public struct TouchMessageBubbleView: View {
    let message: Message
    let onCopy: (() -> Void)?
    let onRegenerate: (() -> Void)?
    
    @Environment(\.platformConfiguration) private var platformConfig
    @State private var showingContextMenu = false
    @State private var isPressed = false
    
    public init(
        message: Message,
        onCopy: (() -> Void)? = nil,
        onRegenerate: (() -> Void)? = nil
    ) {
        self.message = message
        self.onCopy = onCopy
        self.onRegenerate = onRegenerate
    }
    
    public var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(cornerRadius)
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 50)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(
            minimumDuration: 0.5,
            maximumDistance: 10,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {
                showContextMenu()
            }
        )
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        if let onCopy = onCopy {
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        
        if message.role == .assistant, let onRegenerate = onRegenerate {
            Button(action: onRegenerate) {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
        
        Button(action: {}) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .accentColor
        case .assistant:
            return .gray.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch message.role {
        case .user:
            return .white
        case .assistant:
            return .primary
        }
    }
    
    private var cornerRadius: CGFloat {
        PlatformManager.shared.preferredCornerRadius
    }
    
    // MARK: - Actions
    
    private func showContextMenu() {
        // Haptic feedback for iPad
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        showingContextMenu = true
    }
}

#Preview {
    VStack {
        TouchMessageBubbleView(
            message: Message(content: "Hello, this is a test message from the user.", role: .user)
        )
        
        TouchMessageBubbleView(
            message: Message(content: "This is a response from SerenaNet with some longer content to show how it wraps.", role: .assistant)
        )
        
        Spacer()
        
        TouchMessageInputView(
            messageText: .constant(""),
            isComposing: .constant(false),
            isProcessing: false,
            isVoiceRecording: false,
            isVoiceAvailable: true,
            onSend: {},
            onVoiceInput: {},
            onAttachment: {}
        )
    }
    .padding()
}