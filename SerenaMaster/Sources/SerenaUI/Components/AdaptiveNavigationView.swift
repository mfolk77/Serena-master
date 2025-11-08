import SwiftUI
import SerenaCore
#if canImport(UIKit)
import UIKit
#endif

/// Adaptive navigation view that adjusts based on platform and screen size
public struct AdaptiveNavigationView<Sidebar: View, Content: View>: View {
    let sidebar: Sidebar
    let content: Content
    
    @Environment(\.platformConfiguration) private var platformConfig
    @State private var showingSidebar = true
    @State private var sidebarWidth: CGFloat = 320
    
    public init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) {
        self.sidebar = sidebar()
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if shouldUseSplitView(for: geometry.size) {
                splitViewLayout(geometry: geometry)
            } else {
                overlayLayout(geometry: geometry)
            }
        }
        .onAppear {
            sidebarWidth = PlatformManager.shared.preferredSidebarWidth
        }
    }
    
    // MARK: - Layout Decisions
    
    private func shouldUseSplitView(for size: CGSize) -> Bool {
        switch platformConfig.platform {
        case .macOS:
            return true
        case .iPadOS:
            return size.width >= 768 // Regular width class
        case .iOS:
            return false
        case .unknown:
            return size.width >= 768
        }
    }
    
    // MARK: - Split View Layout (iPad Regular, macOS)
    
    @ViewBuilder
    private func splitViewLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            if showingSidebar {
                sidebar
                    .frame(width: sidebarWidth)
                    .background(.gray.opacity(0.1))
                    .transition(.move(edge: .leading))
                
                Divider()
            }
            
            content
                .frame(maxWidth: .infinity)
                .clipped()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")
            }
        }
    }
    
    // MARK: - Overlay Layout (iPhone, iPad Compact)
    
    @ViewBuilder
    private func overlayLayout(geometry: GeometryProxy) -> some View {
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showingSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSidebar = false
                        }
                    }
                
                HStack {
                    sidebar
                        .frame(width: min(sidebarWidth, geometry.size.width * 0.85))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.background)
                                .shadow(radius: 20)
                        )
                        .padding(.leading, 8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: showingSidebar ? "xmark" : "line.3.horizontal")
                }
                .help(showingSidebar ? "Close Sidebar" : "Open Sidebar")
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSidebar.toggle()
        }
    }
}

/// iPad-specific multitasking support
public struct MultitaskingAwareView<Content: View>: View {
    let content: Content
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isInSplitView = false
    @State private var isInSlideOver = false
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .onChange(of: horizontalSizeClass) { newValue in
                updateMultitaskingState()
            }
            .onChange(of: verticalSizeClass) { newValue in
                updateMultitaskingState()
            }
            .onAppear {
                updateMultitaskingState()
            }
            .environment(\.isInSplitView, isInSplitView)
            .environment(\.isInSlideOver, isInSlideOver)
    }
    
    private func updateMultitaskingState() {
        #if os(iOS)
        // Detect if we're in Split View or Slide Over
        let isCompact = horizontalSizeClass == .compact
        let isRegular = horizontalSizeClass == .regular
        
        // This is a simplified detection - in a real app you might use more sophisticated methods
        isInSplitView = isRegular && UIDevice.current.userInterfaceIdiom == .pad
        isInSlideOver = isCompact && UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
}

// MARK: - Environment Keys

private struct IsInSplitViewKey: EnvironmentKey {
    static let defaultValue = false
}

private struct IsInSlideOverKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var isInSplitView: Bool {
        get { self[IsInSplitViewKey.self] }
        set { self[IsInSplitViewKey.self] = newValue }
    }
    
    var isInSlideOver: Bool {
        get { self[IsInSlideOverKey.self] }
        set { self[IsInSlideOverKey.self] = newValue }
    }
}

#Preview {
    AdaptiveNavigationView(
        sidebar: {
            List {
                ForEach(0..<10) { index in
                    Text("Item \(index)")
                }
            }
            .navigationTitle("Sidebar")
        },
        content: {
            VStack {
                Text("Main Content")
                    .font(.largeTitle)
                Spacer()
            }
            .navigationTitle("Content")
        }
    )
}