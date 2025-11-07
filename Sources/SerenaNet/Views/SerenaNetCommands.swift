import SwiftUI

struct SerenaNetCommands: Commands {
    @FocusedValue(\.chatManager) var chatManager
    @FocusedValue(\.showingSettings) var showingSettings
    
    var body: some Commands {
        // File menu commands
        CommandGroup(replacing: .newItem) {
            Button("New Conversation") {
                chatManager?.createNewConversation()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(chatManager == nil)
        }
        
        CommandGroup(after: .newItem) {
            Divider()
            
            Button("Clear Current Conversation") {
                chatManager?.clearCurrentConversation()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .disabled(chatManager?.currentConversation == nil)
            
            Button("Delete Conversation") {
                chatManager?.deleteCurrentConversation()
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(chatManager?.currentConversation == nil)
        }
        
        // Edit menu enhancements
        CommandGroup(after: .pasteboard) {
            Divider()
            
            Button("Copy Last Response") {
                chatManager?.copyLastResponse()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(chatManager?.canCopyLastResponse != true)
        }
        
        // View menu
        CommandGroup(replacing: .sidebar) {
            Button("Toggle Sidebar") {
                // This will be handled by the ContentView
                NotificationCenter.default.post(name: .toggleSidebar, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
        
        // Window menu enhancements
        CommandGroup(after: .windowSize) {
            Divider()
            
            Button("Focus Message Input") {
                NotificationCenter.default.post(name: .focusMessageInput, object: nil)
            }
            .keyboardShortcut("/", modifiers: .command)
            
            Button("Start Voice Input") {
                chatManager?.startVoiceInput()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(chatManager == nil)
        }
        
        // Settings
        CommandGroup(replacing: .appSettings) {
            Button("Preferences...") {
                NotificationCenter.default.post(name: .showSettings, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        
        // Help menu
        CommandGroup(replacing: .help) {
            Button("SerenaNet Help") {
                NotificationCenter.default.post(name: .showHelp, object: nil)
            }
            .keyboardShortcut("?", modifiers: [.command, .shift])
            
            Button("Quick Start Guide") {
                NotificationCenter.default.post(name: .showOnboarding, object: nil)
            }
            
            Button("Keyboard Shortcuts") {
                NotificationCenter.default.post(name: .showKeyboardShortcuts, object: nil)
            }
            .keyboardShortcut("?", modifiers: .command)
            
            Divider()
            
            Button("Privacy Policy") {
                NSWorkspace.shared.open(URL(string: "https://serenatools.com/privacy")!)
            }
            
            Button("Support") {
                NSWorkspace.shared.open(URL(string: "https://serenatools.com/support")!)
            }
        }
    }
}

// MARK: - FocusedValues Extensions
extension FocusedValues {
    struct ChatManagerKey: FocusedValueKey {
        typealias Value = ChatManager
    }
    
    struct ShowingSettingsKey: FocusedValueKey {
        typealias Value = Bool
    }
    
    var chatManager: ChatManagerKey.Value? {
        get { self[ChatManagerKey.self] }
        set { self[ChatManagerKey.self] = newValue }
    }
    
    var showingSettings: ShowingSettingsKey.Value? {
        get { self[ShowingSettingsKey.self] }
        set { self[ShowingSettingsKey.self] = newValue }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let focusMessageInput = Notification.Name("focusMessageInput")
    static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
    static let showSettings = Notification.Name("showSettings")
    static let showHelp = Notification.Name("showHelp")
    static let showOnboarding = Notification.Name("showOnboarding")
}