#!/bin/bash

echo "🧪 Testing RTAI Response System..."

cd /Users/michaelfolk/Developer/Serena/SerenaMaster

# First, let's test if the basic message flow works by creating a simple test
cat > test_message_flow.swift << 'EOF'
import Foundation
import os.log

// Test script to verify RTAI responses work
print("🧪 Starting RTAI response test...")

// Test the basic response patterns that should work
let testMessages = [
    "Hello",
    "What can you do?",
    "How are you?",
    "Tell me about RTAI",
    "What time is it?"
]

print("📝 Test messages: \(testMessages)")
print("✅ If you see this, the Swift script is running correctly")
print("🎯 This confirms the basic Swift execution environment works")
EOF

# Try to run the test script
echo "🔧 Attempting to run basic Swift test..."
swift test_message_flow.swift

if [ $? -eq 0 ]; then
    echo "✅ Swift execution works"
else
    echo "❌ Swift execution failed"
fi

# Now let's try running the app with more verbose output
echo ""
echo "🚀 Testing app startup with verbose logging..."
echo "📋 We'll try to capture ANY output from the app..."

# Run the app and capture all output
./build_with_rtai.sh 2>&1

echo ""
echo "🧪 Starting app in test mode..."
timeout 10s ./.build/arm64-apple-macosx/debug/SerenaNet 2>&1 &
APP_PID=$!

echo "🎯 App started with PID: $APP_PID"
echo "⏰ Waiting 5 seconds for app to initialize..."
sleep 5

if ps -p $APP_PID > /dev/null; then
    echo "✅ App is running successfully"
    echo "🎯 You should now see the Serena GUI window"
    echo "💡 Try typing a message in the GUI"
    
    # Wait a bit more then kill
    sleep 5
    kill $APP_PID 2>/dev/null
    echo "🔄 Test app terminated"
else
    echo "❌ App crashed or failed to start"
fi

echo ""
echo "🎯 Test complete. If you saw the GUI, try typing messages."
echo "💡 If responses still don't work, the issue might be:"
echo "   1. Message input not reaching the handler"
echo "   2. ChatManager not connected properly"
echo "   3. RTAI system not responding"