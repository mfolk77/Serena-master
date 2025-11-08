import SwiftUI
import AppKit

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var currentWindow: NSWindow?
    @Published var windowLevel: NSWindow.Level = .normal
    @Published var isFullScreen = false
    @Published var windowFrame: CGRect = .zero
    
    private init() {
        setupWindowObservers()
    }
    
    // MARK: - Window Management
    
    func setCurrentWindow(_ window: NSWindow?) {
        currentWindow = window
        if let window = window {
            windowFrame = window.frame
            isFullScreen = window.styleMask.contains(.fullScreen)
        }
    }
    
    func bringToFront() {
        guard let window = currentWindow else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func minimizeWindow() {
        currentWindow?.miniaturize(nil)
    }
    
    func toggleFullScreen() {
        currentWindow?.toggleFullScreen(nil)
    }
    
    func centerWindow() {
        currentWindow?.center()
    }
    
    func setWindowLevel(_ level: NSWindow.Level) {
        currentWindow?.level = level
        windowLevel = level
    }
    
    // MARK: - Window Behavior
    
    func configureWindow(_ window: NSWindow) {
        // Set minimum and maximum sizes
        window.minSize = CGSize(width: 600, height: 400)
        window.maxSize = CGSize(width: 2000, height: 1400)
        
        // Configure window behavior
        window.isRestorable = true
        window.tabbingMode = .preferred
        window.collectionBehavior = [.managed, .participatesInCycle]
        
        // Set up window delegate for custom behavior
        window.delegate = WindowDelegate.shared
        
        // Configure title bar
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        setCurrentWindow(window)
    }
    
    // MARK: - Window State
    
    func saveWindowState() {
        guard let window = currentWindow else { return }
        
        let defaults = UserDefaults.standard
        let frame = window.frame
        
        defaults.set(frame.origin.x, forKey: "WindowOriginX")
        defaults.set(frame.origin.y, forKey: "WindowOriginY")
        defaults.set(frame.size.width, forKey: "WindowWidth")
        defaults.set(frame.size.height, forKey: "WindowHeight")
        defaults.set(isFullScreen, forKey: "WindowIsFullScreen")
    }
    
    func restoreWindowState() {
        guard let window = currentWindow else { return }
        
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "WindowOriginX") != nil {
            let x = defaults.double(forKey: "WindowOriginX")
            let y = defaults.double(forKey: "WindowOriginY")
            let width = defaults.double(forKey: "WindowWidth")
            let height = defaults.double(forKey: "WindowHeight")
            let wasFullScreen = defaults.bool(forKey: "WindowIsFullScreen")
            
            let frame = CGRect(x: x, y: y, width: width, height: height)
            window.setFrame(frame, display: true)
            
            if wasFullScreen && !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        } else {
            // First launch - center the window
            centerWindow()
        }
    }
    
    // MARK: - Observers
    
    private func setupWindowObservers() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isFullScreen = true }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isFullScreen = false }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let window = notification.object as? NSWindow,
               window == self?.currentWindow {
                Task { @MainActor in self?.windowFrame = window.frame }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let window = notification.object as? NSWindow,
               window == self?.currentWindow {
                Task { @MainActor in self?.windowFrame = window.frame }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Window Delegate
class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()
    
    private override init() {
        super.init()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Save window state before closing
        WindowManager.shared.saveWindowState()
        return true
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Clear badge when window becomes active
        NotificationManager.shared.clearBadge()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        WindowManager.shared.isFullScreen = true
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        WindowManager.shared.isFullScreen = false
    }
    
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            WindowManager.shared.windowFrame = window.frame
        }
    }
    
    func windowDidMove(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            WindowManager.shared.windowFrame = window.frame
        }
    }
}

// MARK: - SwiftUI Integration
struct WindowAccessor: NSViewRepresentable {
    let onWindowChange: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.onWindowChange(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.onWindowChange(nsView.window)
        }
    }
}

// MARK: - View Modifier
extension View {
    func windowManager() -> some View {
        background(
            WindowAccessor { window in
                if let window = window {
                    WindowManager.shared.configureWindow(window)
                    WindowManager.shared.restoreWindowState()
                }
            }
        )
    }
}