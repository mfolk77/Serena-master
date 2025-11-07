import SwiftUI
import SerenaCore
import AppKit

@main
struct SerenaNetApp: App {
    @StateObject private var chatManager = ChatManager()
    @StateObject private var configManager = ConfigManager()
    
    init() {
        print("🚀 SerenaNet Starting (WINDOW CAPTURE VERSION)...")
        
        // Configure window behavior
        setupWindowBehavior()
        
        Task { @MainActor in
            PerformanceMonitor.shared.startMonitoring()
        }
        
        print("✅ SerenaNet initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatManager)
                .environmentObject(configManager)
                .onAppear {
                    print("✅ SerenaNet UI loaded - setting up window capture")
                    setupProperWindowFocus()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
    
    private func setupWindowBehavior() {
        // Ensure windows can become key and accept input
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
        }
    }
    
    private func setupProperWindowFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🎯 Setting up proper window focus for input capture...")
            
            // Activate app
            NSApp.activate(ignoringOtherApps: true)
            
            // Get window and ensure it can capture input
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                
                // CRITICAL: Set window to accept key events
                window.makeFirstResponder(window.contentView)
                
                // Ensure window level is appropriate
                window.level = .normal
                
                print("✅ Window setup for input capture complete")
                print("   - Window is key: \(window.isKeyWindow)")
                print("   - Can become key: \(window.canBecomeKey)")
                print("   - First responder: \(window.firstResponder?.description ?? "none")")
            } else {
                print("⚠️ No window found for setup")
            }
        }
    }
}
