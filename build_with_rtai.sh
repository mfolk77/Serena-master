#!/bin/bash

# Build Serena with RTAI integration
echo "🚀 Building Serena with RTAI integration..."

# Set library path for RTAI
export DYLD_LIBRARY_PATH="$(pwd)/Libraries:$DYLD_LIBRARY_PATH"

# Build the Swift package
swift build

if [ $? -eq 0 ]; then
    echo "✅ Serena build successful"
else
    echo "❌ Serena build failed"
    exit 1
fi
