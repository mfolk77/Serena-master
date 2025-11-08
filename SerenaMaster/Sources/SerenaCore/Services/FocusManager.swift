import SwiftUI
import AppKit

@MainActor
class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var shouldFocusInput = false
    
    private init() {}
    
    func requestInputFocus() {
        print("🎯 FocusManager: Requesting input focus")
        
        // Ensure we're on main thread and app is active
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            // Get the key window
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
                print("⚠️ FocusManager: No window found")
                return
            }
            
            // Make window key and bring to front
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            
            // Clear current first responder
            window.makeFirstResponder(nil)
            
            // Set focus flag
            self.shouldFocusInput = true
            
            // Post focus notification
            NotificationCenter.default.post(name: .focusMessageInput, object: nil)
            
            print("✅ FocusManager: Focus request completed")
        }
    }
    
    func clearFocusRequest() {
        shouldFocusInput = false
    }
}
