#!/bin/bash

# Run Serena with RTAI integration
echo "🚀 Running Serena with RTAI integration..."

# Set library path for RTAI
export DYLD_LIBRARY_PATH="$(pwd)/Libraries:$DYLD_LIBRARY_PATH"

# Run Serena
swift run SerenaNet

