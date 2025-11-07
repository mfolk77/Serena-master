#!/bin/bash

echo "🔧 SerenaNet Diagnostic Launch"
echo "=============================="

# Temporarily rename the main app file
if [ -f "Sources/SerenaNet/SerenaNetApp.swift" ]; then
    mv Sources/SerenaNet/SerenaNetApp.swift Sources/SerenaNet/SerenaNetApp_Original.swift
    echo "📝 Backed up original app file"
fi

# Rename diagnostic version to main
if [ -f "Sources/SerenaNet/SerenaNetApp_Diagnostic.swift" ]; then
    cp Sources/SerenaNet/SerenaNetApp_Diagnostic.swift Sources/SerenaNet/SerenaNetApp.swift
    echo "📝 Using diagnostic version"
fi

echo ""
echo "🔨 Building diagnostic version..."
swift build

if [ $? -eq 0 ]; then
    echo ""
    echo "🚀 Launching SerenaNet Diagnostic..."
    echo "   (This should open a window with a simple chat interface)"
    echo ""
    
    # Launch the diagnostic version
    ./.build/debug/SerenaNet
    
    echo ""
    echo "📋 Diagnostic complete"
else
    echo "❌ Build failed"
fi

# Restore original app file
if [ -f "Sources/SerenaNet/SerenaNetApp_Original.swift" ]; then
    mv Sources/SerenaNet/SerenaNetApp_Original.swift Sources/SerenaNet/SerenaNetApp.swift
    echo "📝 Restored original app file"
fi

echo ""
echo "✅ Diagnostic session ended"