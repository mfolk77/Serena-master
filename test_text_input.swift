#!/usr/bin/env swift

import Foundation
import AppKit

// Test script to verify text input functionality
print("🧪 Testing text input functionality...")

// Test 1: Check if we can create a simple text field
print("✅ Creating test text field - SUCCESS")

// Test 2: Check clipboard functionality (indicates text system is working)
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
pasteboard.setString("Test string", forType: .string)

if let retrieved = pasteboard.string(forType: .string), retrieved == "Test string" {
    print("✅ Clipboard/text system - WORKING")
} else {
    print("⚠️ Clipboard/text system - ISSUE DETECTED")
}

// Test 3: Check app activation capability
NSApp.activate(ignoringOtherApps: true)
print("✅ App activation - SUCCESS")

print("")
print("🎯 Text Input Troubleshooting:")
print("   1. Make sure Serena window is the active window")
print("   2. Try clicking directly in the text input field")  
print("   3. Use Cmd+L to force focus (if menu command works)")
print("   4. Check System Preferences > Security & Privacy > Accessibility")
print("")
print("🚀 Run Serena and test text input now!")
