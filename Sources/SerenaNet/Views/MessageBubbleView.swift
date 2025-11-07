import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isVisible = false
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                // Message content with avatar
                HStack(alignment: .bottom, spacing: 8) {
                    if message.role == .assistant {
                        // Assistant avatar
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.accentColor)
                            )
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(AnimationPresets.quickSpring.delay(0.1), value: isVisible)
                    }
                    
                    VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                        // Message bubble
                        Text(message.content)
                            .dynamicFont(size: 14, weight: .regular, design: .default)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(bubbleBackground)
                                    .shadow(
                                        color: .black.opacity(themeManager.effectiveColorScheme == .dark ? 0.3 : 0.1),
                                        radius: isHovered ? 8 : 4,
                                        x: 0,
                                        y: isHovered ? 4 : 2
                                    )
                            )
                            .foregroundColor(textColor)
                            .textSelection(.enabled)
                            .scaleEffect(isVisible ? 1.0 : 0.9)
                            .animation(AnimationPresets.messageAppear, value: isVisible)
                            .animation(AnimationPresets.quickSpring, value: isHovered)
                        
                        // Timestamp and status
                        HStack(spacing: 4) {
                            if message.role == .assistant {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.customColors.success)
                                    .opacity(isVisible ? 1.0 : 0.0)
                                    .animation(AnimationPresets.quickSpring.delay(0.3), value: isVisible)
                            }
                            
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(themeManager.customColors.secondary)
                                .opacity(isVisible ? 0.8 : 0.0)
                                .animation(AnimationPresets.quickSpring.delay(0.2), value: isVisible)
                            
                            if message.role == .user {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.accentColor)
                                    .opacity(isVisible ? 1.0 : 0.0)
                                    .animation(AnimationPresets.quickSpring.delay(0.3), value: isVisible)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    if message.role == .user {
                        // User avatar
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("U")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(AnimationPresets.quickSpring.delay(0.1), value: isVisible)
                    }
                }
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(AnimationPresets.quickSpring) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(AnimationPresets.messageAppear.delay(0.1)) {
                isVisible = true
            }
        }
        .contextMenu {
            MessageContextMenu(message: message)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.role == .user ? "You" : "SerenaNet") said")
        .accessibilityValue(message.content)
        .accessibilityHint("Message sent at \(formatTimestamp(message.timestamp))")
        .accessibilityAdapted()
    }
    
    private var bubbleBackground: Color {
        if message.role == .user {
            return themeManager.accentColor
        } else {
            return themeManager.effectiveColorScheme == .dark ?
                Color(NSColor.controlBackgroundColor) :
                themeManager.customColors.surface
        }
    }
    
    private var textColor: Color {
        if message.role == .user {
            return .white
        } else {
            return themeManager.customColors.primary
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
}

struct MessageContextMenu: View {
    let message: Message
    
    var body: some View {
        Button("Copy Message") {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(message.content, forType: .string)
        }
        
        Button("Copy Timestamp") {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            let timestampString = formatter.string(from: message.timestamp)
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(timestampString, forType: .string)
        }
        
        if message.role == .assistant {
            Divider()
            
            Button("Regenerate Response") {
                // TODO: Implement regenerate functionality
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: Message(
                content: "Hello! How can I help you today?",
                role: .assistant
            )
        )
        
        MessageBubbleView(
            message: Message(
                content: "I need help with a Swift programming question about async/await patterns.",
                role: .user
            )
        )
        
        MessageBubbleView(
            message: Message(
                content: "I'd be happy to help you with Swift async/await patterns! These are powerful tools for handling asynchronous operations in a more readable and maintainable way. What specific aspect would you like to explore?",
                role: .assistant
            )
        )
    }
    .padding()
    .frame(width: 600)
}