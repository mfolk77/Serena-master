import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection = .gettingStarted
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with help sections
            List(HelpSection.allCases, id: \.self, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Help Topics")
            .frame(minWidth: 200)
        } detail: {
            // Detail view with help content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(selectedSection.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(selectedSection.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    if !selectedSection.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ForEach(selectedSection.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    
                                    Text(tip)
                                        .font(.callout)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if case .shortcuts = selectedSection {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Keyboard Shortcuts")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ForEach(selectedSection.shortcuts, id: \.key) { shortcut in
                                HStack {
                                    Text(shortcut.key)
                                        .font(.system(.callout, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                    
                                    Text(shortcut.description)
                                        .font(.callout)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle(selectedSection.title)
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

enum HelpSection: CaseIterable {
    case gettingStarted
    case voiceInput
    case conversations
    case settings
    case privacy
    case troubleshooting
    case shortcuts
    case about
    
    var title: String {
        switch self {
        case .gettingStarted:
            return "Getting Started"
        case .voiceInput:
            return "Voice Input"
        case .conversations:
            return "Managing Conversations"
        case .settings:
            return "Settings & Preferences"
        case .privacy:
            return "Privacy & Security"
        case .troubleshooting:
            return "Troubleshooting"
        case .shortcuts:
            return "Keyboard Shortcuts"
        case .about:
            return "About SerenaNet"
        }
    }
    
    var icon: String {
        switch self {
        case .gettingStarted:
            return "play.circle"
        case .voiceInput:
            return "mic"
        case .conversations:
            return "bubble.left.and.bubble.right"
        case .settings:
            return "gearshape"
        case .privacy:
            return "lock.shield"
        case .troubleshooting:
            return "wrench.and.screwdriver"
        case .shortcuts:
            return "keyboard"
        case .about:
            return "info.circle"
        }
    }
    
    var content: String {
        switch self {
        case .gettingStarted:
            return """
            Welcome to SerenaNet, your local AI assistant!
            
            SerenaNet is designed to provide intelligent assistance while keeping your data completely private. All AI processing happens locally on your device - nothing is sent to external servers.
            
            To get started:
            1. Type your question or request in the message field at the bottom
            2. Press Enter or click Send to get a response
            3. Use the microphone button for voice input
            4. Access settings through the gear icon or Cmd+, (comma)
            
            Your conversations are automatically saved and encrypted locally. You can create new conversations anytime and switch between them using the sidebar.
            """
            
        case .voiceInput:
            return """
            SerenaNet supports voice input for hands-free interaction with your AI assistant.
            
            Voice input features:
            • Local speech recognition using Apple's SpeechKit
            • No audio data leaves your device
            • Works offline once permissions are granted
            • Visual feedback during recording
            
            To use voice input:
            1. Click the microphone button or press Cmd+Shift+V
            2. Speak clearly when the recording indicator appears
            3. Click stop or press the shortcut again to finish
            4. Your speech will be converted to text and sent to the AI
            
            Note: You'll need to grant microphone permission when first using this feature.
            """
            
        case .conversations:
            return """
            SerenaNet helps you organize your interactions through conversations.
            
            Conversation features:
            • Automatic saving and encryption
            • Search through conversation history
            • Context maintained within each conversation
            • Easy switching between topics
            
            Managing conversations:
            • Create new conversations with Cmd+N
            • Switch conversations using the sidebar
            • Search conversations with Cmd+F
            • Delete conversations you no longer need
            • Export conversations for backup
            
            Each conversation maintains context for up to 10 previous exchanges to provide relevant responses.
            """
            
        case .settings:
            return """
            Customize SerenaNet to match your preferences and workflow.
            
            Available settings:
            • Theme selection (Light, Dark, System)
            • AI response parameters (temperature, length)
            • Voice input preferences
            • Privacy and security options
            • Keyboard shortcuts
            
            Privacy settings:
            • Optional passcode protection
            • Conversation encryption (always enabled)
            • Local-only data storage
            • No telemetry or tracking
            
            All settings are saved locally and apply immediately. You can reset to defaults anytime if needed.
            """
            
        case .privacy:
            return """
            Your privacy is our top priority. SerenaNet is designed with privacy-first principles.
            
            Privacy features:
            • All AI processing happens locally on your device
            • No data is sent to external servers
            • Conversations are encrypted using Apple's CryptoKit
            • Optional passcode protection for app access
            • No telemetry, analytics, or tracking
            
            Data storage:
            • All data stays on your device
            • Encrypted SQLite database
            • Secure keychain storage for sensitive data
            • You control all your data
            
            Permissions:
            • Microphone: Only for voice input (optional)
            • Speech Recognition: For voice-to-text conversion
            • No network permissions required for core functionality
            """
            
        case .troubleshooting:
            return """
            Common issues and solutions:
            
            App won't start or crashes:
            • Ensure you're running macOS 13.0 or later
            • Try restarting the app
            • Check available memory (4GB recommended)
            
            AI responses are slow:
            • Close other memory-intensive applications
            • Check system performance in Activity Monitor
            • Restart the app to clear memory
            
            Voice input not working:
            • Check microphone permissions in System Settings
            • Ensure microphone is not being used by other apps
            • Try restarting the app
            
            Conversations not saving:
            • Check available disk space
            • Verify app has write permissions
            • Try creating a new conversation
            
            If problems persist, try resetting settings to defaults or reinstalling the app.
            """
            
        case .shortcuts:
            return """
            Keyboard shortcuts for efficient use of SerenaNet.
            
            These shortcuts help you navigate and use the app more efficiently. All shortcuts follow standard macOS conventions.
            """
            
        case .about:
            return """
            SerenaNet is a privacy-first AI assistant that runs entirely on your device.
            
            **Version:** 1.0.0
            **Build:** 1
            **Platform:** macOS 13.0+
            
            **Key Features:**
            • Local AI processing with Mixtral MoE
            • Complete privacy - no data leaves your device
            • Voice input with Apple SpeechKit
            • Encrypted conversation storage
            • Native macOS integration
            
            **Privacy Commitment:**
            SerenaNet is designed with privacy as the foundation. All AI processing happens locally using on-device models. We collect no data, have no analytics, and never transmit your conversations or personal information.
            
            **Support:**
            For help and support, visit our documentation or contact support through the app menu.
            
            **Open Source:**
            SerenaNet is built with transparency in mind. Core components are available for review and contribution.
            
            **Credits:**
            Built with Swift and SwiftUI
            AI powered by Mixtral MoE
            Encryption by Apple CryptoKit
            Speech recognition by Apple SpeechKit
            
            © 2025 SerenaTools. All rights reserved.
            """
        }
    }
    
    var tips: [String] {
        switch self {
        case .gettingStarted:
            return [
                "Start with simple questions to get familiar with the AI's capabilities",
                "Use specific, clear language for better responses",
                "Try different conversation topics to explore the AI's knowledge",
                "All processing happens locally - no internet required for core features",
                "Your conversations are automatically encrypted and saved locally"
            ]
            
        case .voiceInput:
            return [
                "Speak clearly and at a normal pace for best recognition",
                "Use voice input in quiet environments for better accuracy",
                "You can edit the transcribed text before sending if needed"
            ]
            
        case .conversations:
            return [
                "Give conversations descriptive names for easy organization",
                "Use separate conversations for different topics or projects",
                "The AI remembers context within each conversation"
            ]
            
        case .settings:
            return [
                "Experiment with AI temperature settings to find your preference",
                "Enable passcode protection if you share your device",
                "Dark mode can be easier on the eyes during extended use"
            ]
            
        case .privacy:
            return [
                "Your data never leaves your device - it's completely private",
                "Regular backups of your device will include your conversations",
                "You can delete all data anytime through the settings",
                "SerenaNet has no analytics, tracking, or telemetry",
                "All AI processing uses local models - no cloud services",
                "Conversations are encrypted using Apple's CryptoKit framework"
            ]
            
        case .troubleshooting:
            return [
                "Most issues can be resolved by restarting the app",
                "Check system requirements if you experience performance issues",
                "Keep your system updated for best compatibility"
            ]
            
        case .shortcuts:
            return [
                "Learn a few key shortcuts to speed up your workflow",
                "Shortcuts are shown in menus next to their commands",
                "You can customize some shortcuts in System Settings"
            ]
            
        case .about:
            return [
                "SerenaNet is designed for users who value privacy and local control",
                "All features work offline once the app is installed",
                "Regular updates improve performance and add new capabilities",
                "Your feedback helps us make SerenaNet better for everyone"
            ]
        }
    }
    
    var shortcuts: [KeyboardShortcut] {
        switch self {
        case .shortcuts:
            return [
                KeyboardShortcut(key: "⌘N", description: "New conversation"),
                KeyboardShortcut(key: "⌘W", description: "Close window"),
                KeyboardShortcut(key: "⌘,", description: "Open settings"),
                KeyboardShortcut(key: "⌘F", description: "Search conversations"),
                KeyboardShortcut(key: "⌘⇧V", description: "Start/stop voice input"),
                KeyboardShortcut(key: "⌘⇧D", description: "Delete current conversation"),
                KeyboardShortcut(key: "⌘R", description: "Refresh/retry last message"),
                KeyboardShortcut(key: "⌘⇧?", description: "Show help"),
                KeyboardShortcut(key: "⌘Q", description: "Quit SerenaNet"),
                KeyboardShortcut(key: "⌘M", description: "Minimize window"),
                KeyboardShortcut(key: "⌘⇧T", description: "Toggle theme"),
                KeyboardShortcut(key: "⌘↑", description: "Previous conversation"),
                KeyboardShortcut(key: "⌘↓", description: "Next conversation")
            ]
        default:
            return []
        }
    }
}


#Preview {
    HelpView()
}