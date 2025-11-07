import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var chatManager: ChatManager
    @EnvironmentObject private var configManager: ConfigManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingSidebar = true
    @State private var showingSettings = false
    @State private var showingKeyboardShortcuts = false
    @State private var showingHelp = false
    @State private var showingOnboarding = false
    @State private var windowSize: CGSize = .zero
    @State private var textSizeMultiplier: Double = UserDefaults.standard.double(forKey: "SerenaNet.TextSizeMultiplier") == 0 ? 1.0 : UserDefaults.standard.double(forKey: "SerenaNet.TextSizeMultiplier")

    // Responsive breakpoints
    private var isCompact: Bool { windowSize.width < 800 }
    private var shouldAutoHideSidebar: Bool { windowSize.width < 600 }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with theme support
                themeManager.customColors.background
                    .ignoresSafeArea()
                
                if isCompact {
                    // Compact layout for smaller windows
                    compactLayout
                } else {
                    // Full layout for larger windows
                    fullLayout
                }
            }
            .onAppear {
                windowSize = geometry.size
            }
            .onChange(of: geometry.size) { newSize in
                windowSize = newSize
                
                // Auto-hide sidebar on very small windows
                if shouldAutoHideSidebar && showingSidebar {
                    withAnimation(AnimationPresets.sidebarToggle) {
                        showingSidebar = false
                    }
                }
            }
        }
        .environment(\.textSizeMultiplier, textSizeMultiplier)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .textSizeChanged)) { notification in
            if let newValue = notification.object as? Double {
                textSizeMultiplier = newValue
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation(AnimationPresets.sidebarToggle) {
                showingSidebar.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showKeyboardShortcuts)) { _ in
            showingKeyboardShortcuts = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showHelp)) { _ in
            showingHelp = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showOnboarding)) { _ in
            showingOnboarding = true
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(configManager)
        }
        .sheet(isPresented: $showingKeyboardShortcuts) {
            Text("Keyboard Shortcuts")
                .padding()
                .frame(minWidth: 400, minHeight: 300)
        }
        .sheet(isPresented: $showingHelp) {
            Text("Help & Documentation")
                .padding()
                .frame(minWidth: 400, minHeight: 300)
        }
        .sheet(isPresented: $showingOnboarding) {
            Text("Welcome to SerenaNet!")
                .padding()
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowManager()
    }
    
    @ViewBuilder
    private var fullLayout: some View {
        NavigationView {
            // Sidebar for conversation list
            if showingSidebar {
                ConversationSidebarView()
                    .frame(minWidth: 200, maxWidth: 300)
                    .background(themeManager.customColors.secondaryBackground)
                    .transition(.move(edge: .leading))
            }
            
            // Main chat area
            ChatView()
                .frame(minWidth: 400, minHeight: 300)
                .focusedValue(\.chatManager, chatManager)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation(AnimationPresets.sidebarToggle) {
                        showingSidebar.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(themeManager.customColors.primary)
                }
                .help("Toggle Sidebar (⌃⌘S)")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    chatManager.createNewConversation()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.customColors.primary)
                }
                .help("New Conversation (⌘N)")
            }
        }
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        ZStack {
            // Main chat area (always visible in compact mode)
            ChatView()
                .focusedValue(\.chatManager, chatManager)
            
            // Overlay sidebar for compact mode
            if showingSidebar {
                HStack {
                    ConversationSidebarView()
                        .frame(width: min(300, windowSize.width * 0.8))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.customColors.surface)
                                .shadow(
                                    color: .black.opacity(0.3),
                                    radius: 20,
                                    x: 0,
                                    y: 8
                                )
                        )
                        .padding(.leading, 8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    Spacer()
                }
                .background(
                    Color.black.opacity(0.3)
                        .onTapGesture {
                            withAnimation(AnimationPresets.sidebarToggle) {
                                showingSidebar = false
                            }
                        }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation(AnimationPresets.sidebarToggle) {
                        showingSidebar.toggle()
                    }
                }) {
                    Image(systemName: showingSidebar ? "xmark" : "line.3.horizontal")
                        .foregroundColor(themeManager.customColors.primary)
                }
                .help(showingSidebar ? "Close Sidebar" : "Open Sidebar")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    chatManager.createNewConversation()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.customColors.primary)
                }
                .help("New Conversation")
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}