#!/usr/bin/env swift

// Simple diagnostic to check AI engine initialization
// This should be run within the app context, but let's try to understand the flow

import Foundation

print("Checking AI engine status...")
print("Expected flow:")
print("1. ChatManager.init() creates MixtralEngine")
print("2. Task calls initializeAIEngine()")
print("3. aiEngine.initialize() is called")
print("4. MixtralEngine should print debug messages")
print("")
print("If no debug messages appear, the initialization task may not be running")
print("or errors are being silently caught.")
print("")
print("Next step: Add explicit logging to ChatManager initialization")
