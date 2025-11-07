#!/bin/bash

echo "🚀 Testing Serena MVP with RTAI Integration..."
echo ""
echo "📋 Test Plan:"
echo "   1. Launch Serena with RTAI backend"
echo "   2. Verify text input focus works"
echo "   3. Test RTAI responses"
echo "   4. Confirm UI functionality"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if [ ! -f "./Libraries/libfolktech_rtai.dylib" ]; then
    echo "❌ RTAI library not found - run setup first"
    exit 1
fi

if [ ! -f "./.build/debug/SerenaNet" ]; then
    echo "❌ SerenaNet not built - run ./build_with_rtai.sh first"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

echo "🎯 IMPORTANT: Testing Instructions"
echo ""
echo "When Serena opens:"
echo "   1. Look for a blinking cursor in the text input field"
echo "   2. Try typing immediately - text should appear"
echo "   3. If no cursor/typing doesn't work:"
echo "      • Click directly in the text input field"
echo "      • Press Cmd+L to force focus"
echo "      • Press Cmd+Shift+R to reset window focus"
echo ""
echo "🧪 Test Messages to Try:"
echo "   • 'Hello' - Should get fast RTAI reflex response"
echo "   • 'What can you do?' - Should explain capabilities"
echo "   • 'What time is it?' - Should show current time"
echo "   • Complex questions - Should escalate to LLM"
echo ""

read -p "Press Enter to launch Serena (Ctrl+C to cancel)..."
echo ""

echo "🚀 Launching Serena with RTAI..."
echo "📝 Watch the console output for focus debug messages"
echo "📱 Serena window should open shortly..."
echo ""

# Set library path and launch
export DYLD_LIBRARY_PATH="$(pwd)/Libraries:$DYLD_LIBRARY_PATH"

# Launch Serena
./.build/debug/SerenaNet

echo ""
echo "🎊 Serena MVP test session completed!"
echo ""
echo "📊 If everything worked correctly, you should have:"
echo "   ✅ Text input working immediately"
echo "   ✅ RTAI responses (fast reflexes)"
echo "   ✅ LLM escalation for complex queries"
echo "   ✅ Smooth UI interactions"
echo ""
echo "🔮 Your AI assistant is ready for real-world use!"