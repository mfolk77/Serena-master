#!/bin/bash

# Generate placeholder app icons for SerenaNet
# This script creates simple placeholder icons for development and testing
# Replace with actual designed icons before App Store submission

set -e

ICON_DIR="Sources/SerenaNet/Resources/AppIcon.appiconset"
TEMP_DIR="/tmp/serenanet_icons"

echo "🎨 Generating placeholder app icons for SerenaNet..."

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Check if ImageMagick is available
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagick not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install imagemagick
    else
        echo "❌ Homebrew not found. Please install ImageMagick manually:"
        echo "   brew install imagemagick"
        echo "   or visit: https://imagemagick.org/script/download.php"
        exit 1
    fi
fi

# Create base icon (1024x1024) with SerenaNet branding
convert -size 1024x1024 xc:"#007AFF" \
    -fill white \
    -font "Helvetica-Bold" \
    -pointsize 200 \
    -gravity center \
    -annotate +0-50 "SN" \
    -pointsize 80 \
    -annotate +0+100 "SerenaNet" \
    -pointsize 40 \
    -annotate +0+160 "Local AI Assistant" \
    "$TEMP_DIR/base_icon.png"

# Generate all required sizes
declare -a sizes=("16" "32" "128" "256" "512")

for size in "${sizes[@]}"; do
    echo "  Generating ${size}x${size} icons..."
    
    # 1x version
    convert "$TEMP_DIR/base_icon.png" -resize "${size}x${size}" \
        "$ICON_DIR/icon_${size}x${size}.png"
    
    # 2x version (double resolution)
    double_size=$((size * 2))
    convert "$TEMP_DIR/base_icon.png" -resize "${double_size}x${double_size}" \
        "$ICON_DIR/icon_${size}x${size}@2x.png"
done

# Create 1024x1024 marketing icon
cp "$TEMP_DIR/base_icon.png" "$ICON_DIR/icon_1024x1024.png"

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ Placeholder icons generated successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Replace placeholder icons with professionally designed ones"
echo "   2. Ensure icons follow Apple's design guidelines"
echo "   3. Test icons at all sizes for clarity and recognition"
echo "   4. Consider hiring a designer for production-quality icons"
echo ""
echo "🔗 Apple Icon Guidelines:"
echo "   https://developer.apple.com/design/human-interface-guidelines/app-icons"