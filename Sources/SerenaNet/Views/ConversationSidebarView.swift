import SwiftUI

struct ConversationSidebarView: View {
    @EnvironmentObject private var chatManager: ChatManager
    @State private var searchText = ""
    @State private var sortType: ConversationSortType = .mostRecent
    
    var filteredConversations: [Conversation] {
        let conversations = searchText.isEmpty ? 
            chatManager.conversations : 
            chatManager.searchConversations(query: searchText)
        
        return chatManager.getSortedConversations(by: sortType).filter { conversation in
            conversations.contains { $0.id == conversation.id }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("Conversations")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        chatManager.createNewConversation()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .help("New Conversation (⌘N)")
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Search conversations...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                // Sort picker
                Picker("Sort", selection: $sortType) {
                    ForEach(ConversationSortType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(size: 11))
            }
            .padding()
            
            Divider()
            
            // Conversation list
            if filteredConversations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No conversations yet" : "No matching conversations")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if searchText.isEmpty {
                        Button("Start New Conversation") {
                            chatManager.createNewConversation()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredConversations) { conversation in
                            ConversationRowView(
                                conversation: conversation,
                                isSelected: chatManager.currentConversation?.id == conversation.id
                            )
                            .onTapGesture {
                                chatManager.selectConversation(conversation)
                            }
                            .contextMenu {
                                ConversationContextMenu(conversation: conversation)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            // Footer with stats
            HStack {
                Text("\(chatManager.conversationCount) conversations")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if chatManager.isOffline {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 10))
                        Text("Offline")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            Task {
                await chatManager.loadConversations()
            }
        }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    let isSelected: Bool
    
    private var previewText: String {
        if let lastMessage = conversation.messages.last {
            let preview = lastMessage.content.prefix(60)
            return String(preview) + (lastMessage.content.count > 60 ? "..." : "")
        }
        return "No messages"
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: conversation.updatedAt, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                Text(timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            Text(previewText)
                .font(.system(size: 11))
                .lineLimit(2)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            
            HStack {
                Text("\(conversation.messages.count) messages")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .padding(.horizontal, 8)
    }
}

struct ConversationContextMenu: View {
    let conversation: Conversation
    @EnvironmentObject private var chatManager: ChatManager
    
    var body: some View {
        Button("Select") {
            chatManager.selectConversation(conversation)
        }
        
        Divider()
        
        Button("Rename...") {
            // TODO: Implement rename functionality
        }
        
        Button("Duplicate") {
            // TODO: Implement duplicate functionality
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            Task {
                await chatManager.deleteConversation(conversation)
            }
        }
    }
}

#Preview {
    ConversationSidebarView()
        .environmentObject(ChatManager())
        .frame(width: 250, height: 500)
}