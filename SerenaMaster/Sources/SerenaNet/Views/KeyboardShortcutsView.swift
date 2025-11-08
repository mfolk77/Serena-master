import SwiftUI

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let shortcuts = [
        ShortcutGroup(
            title: "Conversation",
            shortcuts: [
                KeyboardShortcut(key: "⌘N", description: "New Conversation"),
                KeyboardShortcut(key: "⌘⇧K", description: "Clear Current Conversation"),
                KeyboardShortcut(key: "⌘⌫", description: "Delete Conversation"),
                KeyboardShortcut(key: "⌘/", description: "Focus Message Input")
            ]
        ),
        ShortcutGroup(
            title: "Voice & Input",
            shortcuts: [
                KeyboardShortcut(key: "⌘⇧R", description: "Start Voice Input"),
                KeyboardShortcut(key: "⌘⇧C", description: "Copy Last Response")
            ]
        ),
        ShortcutGroup(
            title: "View",
            shortcuts: [
                KeyboardShortcut(key: "⌃⌘S", description: "Toggle Sidebar"),
                KeyboardShortcut(key: "⌘,", description: "Preferences"),
                KeyboardShortcut(key: "⌘?", description: "Show Keyboard Shortcuts")
            ]
        ),
        ShortcutGroup(
            title: "Standard",
            shortcuts: [
                KeyboardShortcut(key: "⌘C", description: "Copy"),
                KeyboardShortcut(key: "⌘V", description: "Paste"),
                KeyboardShortcut(key: "⌘Z", description: "Undo"),
                KeyboardShortcut(key: "⌘W", description: "Close Window"),
                KeyboardShortcut(key: "⌘Q", description: "Quit SerenaNet")
            ]
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView
            Divider()
            shortcutsListView
        }
        .padding(24)
        .frame(width: 450, height: 500)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Keyboard Shortcuts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Speed up your workflow with these shortcuts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.escape)
        }
    }
    
    private var shortcutsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(shortcuts, id: \.title) { group in
                    shortcutGroupView(group)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func shortcutGroupView(_ group: ShortcutGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.title)
                .font(.headline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                ForEach(group.shortcuts, id: \.key) { shortcut in
                    shortcutRowView(shortcut)
                }
            }
        }
    }
    
    private func shortcutRowView(_ shortcut: KeyboardShortcut) -> some View {
        HStack {
            Text(shortcut.description)
                .font(.system(size: 13))
            
            Spacer()
            
            Text(shortcut.key)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}

struct ShortcutGroup {
    let title: String
    let shortcuts: [KeyboardShortcut]
}

struct KeyboardShortcut {
    let key: String
    let description: String
}

#Preview {
    KeyboardShortcutsView()
}