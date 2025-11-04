import SwiftUI
import AppKit

// MARK: - Text Input Focus Fix

extension View {
    /// Custom modifier to ensure text field becomes first responder
    func ensureFocused() -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Force the window to become key and focused
                if let window = NSApp.keyWindow ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    window.makeFirstResponder(nil) // Clear any existing responder
                    
                    // Find the text field and make it first responder
                    if let textField = window.contentView?.findTextField() {
                        window.makeFirstResponder(textField)
                    }
                }
            }
        }
    }
}

extension NSView {
    func findTextField() -> NSTextField? {
        if let textField = self as? NSTextField {
            return textField
        }
        
        for subview in subviews {
            if let found = subview.findTextField() {
                return found
            }
        }
        
        return nil
    }
}

// MARK: - Window Focus Helper

class WindowFocusHelper {
    static func ensureWindowFocused() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(nil)
                
                // Post notification for input focus
                NotificationCenter.default.post(name: .focusMessageInput, object: nil)
            }
        }
    }
}
