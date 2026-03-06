#!/bin/bash

# App Icon Generator for iOS
# Generates all required app icon sizes from a single source image

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_DIR="$FLUTTER_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DrawkcaB iOS App Icon Generator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if source image provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No source image provided${NC}"
    echo ""
    echo "Usage: $0 <source-image.png>"
    echo ""
    echo "Example:"
    echo "  $0 assets/images/app_icon_1024.png"
    echo ""
    echo "Requirements:"
    echo "  - Source image must be square (1:1 aspect ratio)"
    echo "  - Recommended: 1024x1024 or larger"
    echo "  - PNG format without transparency"
    echo ""
    exit 1
fi

SOURCE_IMAGE="$1"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo -e "${RED}Error: Source image not found: $SOURCE_IMAGE${NC}"
    exit 1
fi

# Determine which tool to use (prefer sips on macOS as it's built-in)
if command -v sips &> /dev/null; then
    RESIZE_TOOL="sips"
    echo -e "${GREEN}✓ Using sips (macOS built-in)${NC}"
elif command -v convert &> /dev/null; then
    RESIZE_TOOL="imagemagick"
    echo -e "${GREEN}✓ Using ImageMagick${NC}"
else
    echo -e "${RED}Error: No image resize tool found${NC}"
    echo ""
    echo "Please install ImageMagick:"
    echo "  brew install imagemagick"
    echo ""
    exit 1
fi

# Function to resize image
resize_image() {
    local size=$1
    local output=$2
    
    if [ "$RESIZE_TOOL" = "sips" ]; then
        sips -z "$size" "$size" "$SOURCE_IMAGE" --out "$output" &> /dev/null
    else
        convert "$SOURCE_IMAGE" -resize "${size}x${size}" "$output"
    fi
}

# Check source image dimensions
echo "Checking source image..."
if [ "$RESIZE_TOOL" = "sips" ]; then
    WIDTH=$(sips -g pixelWidth "$SOURCE_IMAGE" | awk '/pixelWidth:/ {print $2}')
    HEIGHT=$(sips -g pixelHeight "$SOURCE_IMAGE" | awk '/pixelHeight:/ {print $2}')
else
    DIMS=$(identify -format "%w %h" "$SOURCE_IMAGE")
    WIDTH=$(echo $DIMS | awk '{print $1}')
    HEIGHT=$(echo $DIMS | awk '{print $2}')
fi

echo "  Source: $SOURCE_IMAGE"
echo "  Size: ${WIDTH}x${HEIGHT}"

# Check if square
if [ "$WIDTH" != "$HEIGHT" ]; then
    echo -e "${RED}✗ Error: Source image is not square (${WIDTH}x${HEIGHT})${NC}"
    echo ""
    echo "App icons must be square. Please:"
    echo "  1. Create a square version of your logo (e.g., 1024x1024)"
    echo "  2. Add a background color if needed"
    echo "  3. Center your logo on the background"
    echo ""
    echo "See docs/ASSETS_GUIDE.md for detailed instructions."
    exit 1
fi

# Check minimum size
if [ "$WIDTH" -lt 1024 ]; then
    echo -e "${YELLOW}⚠ Warning: Source image is smaller than 1024x1024${NC}"
    echo -e "${YELLOW}  Recommended: Use at least 1024x1024 for best quality${NC}"
    echo ""
fi

echo -e "${GREEN}✓ Source image is valid${NC}"
echo ""

# Create backup of existing icons
echo "Creating backup of existing icons..."
BACKUP_DIR="$ASSETS_DIR.backup.$(date +%Y%m%d_%H%M%S)"
cp -r "$ASSETS_DIR" "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup created: $BACKUP_DIR${NC}"
echo ""

# Generate all required icon sizes
echo "Generating icon sizes..."

# Icon sizes required for iOS - filename:size pairs
# Using a simple array of pairs to avoid bash version issues
ICON_LIST=(
    "Icon-App-20x20@1x.png:20"
    "Icon-App-20x20@2x.png:40"
    "Icon-App-20x20@3x.png:60"
    "Icon-App-29x29@1x.png:29"
    "Icon-App-29x29@2x.png:58"
    "Icon-App-29x29@3x.png:87"
    "Icon-App-40x40@1x.png:40"
    "Icon-App-40x40@2x.png:80"
    "Icon-App-40x40@3x.png:120"
    "Icon-App-60x60@2x.png:120"
    "Icon-App-60x60@3x.png:180"
    "Icon-App-76x76@1x.png:76"
    "Icon-App-76x76@2x.png:152"
    "Icon-App-83.5x83.5@2x.png:167"
    "Icon-App-1024x1024@1x.png:1024"
)

TOTAL=${#ICON_LIST[@]}
COUNT=0

for entry in "${ICON_LIST[@]}"; do
    filename="${entry%%:*}"
    size="${entry##*:}"
    output="$ASSETS_DIR/$filename"
    
    COUNT=$((COUNT + 1))
    printf "  [%2d/%2d] Generating %s (%dx%d)... " "$COUNT" "$TOTAL" "$filename" "$size" "$size"
    
    resize_image "$size" "$output"
    
    echo -e "${GREEN}✓${NC}"
done

echo ""
echo -e "${GREEN}✓ All icons generated successfully${NC}"
echo ""

# Verify output
echo "Verifying generated icons..."
VERIFIED=0
FAILED=0

for entry in "${ICON_LIST[@]}"; do
    filename="${entry%%:*}"
    expected_size="${entry##*:}"
    filepath="$ASSETS_DIR/$filename"
    
    if [ ! -f "$filepath" ]; then
        echo -e "${RED}✗ Missing: $filename${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    if [ "$RESIZE_TOOL" = "sips" ]; then
        actual_width=$(sips -g pixelWidth "$filepath" | awk '/pixelWidth:/ {print $2}')
    else
        actual_width=$(identify -format "%w" "$filepath")
    fi
    
    if [ "$actual_width" = "$expected_size" ]; then
        VERIFIED=$((VERIFIED + 1))
    else
        echo -e "${RED}✗ Wrong size: $filename (expected ${expected_size}x${expected_size}, got ${actual_width}x${actual_width})${NC}"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All $VERIFIED icons verified${NC}"
else
    echo -e "${YELLOW}⚠ $VERIFIED verified, $FAILED failed${NC}"
fi
echo ""

# Display next steps
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Open your project in Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Verify icons in Xcode:"
echo "   - Navigate to Runner → Assets.xcassets → AppIcon"
echo "   - All icon sizes should appear with your new icon"
echo ""
echo "3. Test on device or simulator:"
echo "   flutter run -d <device>"
echo ""
echo "4. For App Store Connect:"
echo "   - Use Icon-App-1024x1024@1x.png"
echo "   - Upload to App Store Connect → App Information → App Icon"
echo "   - Must be exactly 1024x1024, PNG, no transparency"
echo ""
echo -e "${GREEN}Icon generation complete! 🎉${NC}"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
