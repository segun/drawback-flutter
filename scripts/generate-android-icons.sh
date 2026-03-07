#!/bin/bash

# Android Icon Generator
# Generates all required Android app icon sizes from a single source image

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
ANDROID_RES_DIR="$FLUTTER_DIR/android/app/src/main/res"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DrawkcaB Android Icon Generator${NC}"
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
    echo "  - Recommended: 512x512 or larger"
    echo "  - PNG format (transparency OK for adaptive icons)"
    echo ""
    echo "Note: For best results with Android adaptive icons,"
    echo "create separate foreground and background layers manually."
    echo "This script generates standard launcher icons."
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
echo ""

# Check if square
if [ "$WIDTH" != "$HEIGHT" ]; then
    echo -e "${RED}✗ Error: Source image is not square (${WIDTH}x${HEIGHT})${NC}"
    echo ""
    echo "App icons must be square. Please:"
    echo "  1. Create a square version of your logo (e.g., 512x512)"
    echo "  2. Add a background color if needed"
    echo "  3. Center your logo on the background"
    echo ""
    exit 1
fi

# Check minimum size
if [ "$WIDTH" -lt 192 ]; then
    echo -e "${YELLOW}⚠ Warning: Source image is small (${WIDTH}px)${NC}"
    echo "  Recommended: 512x512 or larger for best quality"
    echo ""
fi

# Create output directories if they don't exist
echo "Creating output directories..."
mkdir -p "$ANDROID_RES_DIR/mipmap-mdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-hdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-xhdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-xxhdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-xxxhdpi"
echo ""

# Function to get icon size for density (compatible with bash 3.2+)
get_icon_size() {
    case "$1" in
        mdpi) echo 48 ;;
        hdpi) echo 72 ;;
        xhdpi) echo 96 ;;
        xxhdpi) echo 144 ;;
        xxxhdpi) echo 192 ;;
    esac
}

echo "Generating Android launcher icons..."
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    size=$(get_icon_size "$density")
    output="$ANDROID_RES_DIR/mipmap-$density/ic_launcher.png"
    
    echo -n "  $density (${size}x${size})... "
    resize_image "$size" "$output"
    echo -e "${GREEN}✓${NC}"
done
echo ""

# Also generate Play Store icon (512x512)
PLAYSTORE_DIR="$FLUTTER_DIR/assets/playstore"
mkdir -p "$PLAYSTORE_DIR"
PLAYSTORE_ICON="$PLAYSTORE_DIR/icon_512.png"

echo "Generating Play Store icon..."
echo -n "  512x512... "
resize_image 512 "$PLAYSTORE_ICON"
echo -e "${GREEN}✓${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Success! Icons generated${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Generated icons:"
echo "  • mipmap-mdpi/ic_launcher.png (48x48)"
echo "  • mipmap-hdpi/ic_launcher.png (72x72)"
echo "  • mipmap-xhdpi/ic_launcher.png (96x96)"
echo "  • mipmap-xxhdpi/ic_launcher.png (144x144)"
echo "  • mipmap-xxxhdpi/ic_launcher.png (192x192)"
echo "  • assets/playstore/icon_512.png (512x512)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. The standard launcher icons have been generated and installed."
echo ""
echo "2. For modern Android adaptive icons (recommended), you should:"
echo "   a. Create a foreground layer (432x432) with transparency"
echo "   b. Create a background layer (432x432) with solid color"
echo "   c. Keep important content in the center 264px safe zone"
echo ""
echo "3. Upload icon_512.png to Play Console:"
echo "   - Location: $PLAYSTORE_ICON"
echo "   - Use in: Play Console → Store listing → App icon"
echo ""
echo "4. Test the icons:"
echo "   flutter run -d <android-device>"
echo "   Check the app drawer icon on your device"
echo ""
echo -e "${YELLOW}Note: For production apps, consider creating proper adaptive icons${NC}"
echo -e "${YELLOW}with separate foreground and background layers for best results.${NC}"
echo ""
echo "See docs/ASSETS_GUIDE.md for more information on adaptive icons."
