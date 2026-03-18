#!/bin/bash

# Simple Assets Preparation Checklist
# Run this to verify your App Store assets are ready

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}App Store Assets Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Check app icons
echo "Checking app icons..."
ICON_DIR="$FLUTTER_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ICON_1024="$ICON_DIR/Icon-App-1024x1024@1x.png"

if [ -f "$ICON_1024" ]; then
    if command -v sips &> /dev/null; then
        WIDTH=$(sips -g pixelWidth "$ICON_1024" | awk '/pixelWidth:/ {print $2}')
        HEIGHT=$(sips -g pixelHeight "$ICON_1024" | awk '/pixelHeight:/ {print $2}')
        
        if [ "$WIDTH" = "1024" ] && [ "$HEIGHT" = "1024" ]; then
            echo -e "  ${GREEN}✓${NC} App icon (1024x1024) exists"

            HAS_ALPHA=$(sips -g hasAlpha "$ICON_1024" | awk '/hasAlpha:/ {print $2}')
            if [ "$HAS_ALPHA" = "yes" ]; then
                echo -e "  ${RED}✗${NC} App icon contains an alpha channel (App Store icons must be opaque)"
                ERRORS=$((ERRORS + 1))
            fi
            
            # Check if it's likely the default Flutter icon
            SIZE=$(stat -f%z "$ICON_1024" 2>/dev/null || stat -c%s "$ICON_1024" 2>/dev/null)
            if [ "$SIZE" -lt 10000 ]; then
                echo -e "  ${YELLOW}⚠${NC} App icon file is very small (${SIZE} bytes) - might be placeholder"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            echo -e "  ${RED}✗${NC} App icon wrong size: ${WIDTH}x${HEIGHT} (need 1024x1024)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} App icon exists (can't verify dimensions without sips)"
    fi
else
    echo -e "  ${RED}✗${NC} App icon missing: $ICON_1024"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check screenshots
echo "Checking screenshots..."
SCREENSHOTS_DIR="$FLUTTER_DIR/screenshots"

check_screenshots() {
    local dir=$1
    local name=$2
    local expected_width=$3
    local expected_height=$4
    
    if [ -d "$SCREENSHOTS_DIR/$dir" ]; then
        COUNT=$(find "$SCREENSHOTS_DIR/$dir" -name "*.png" -type f | wc -l | tr -d ' ')
        
        if [ "$COUNT" -ge 3 ] && [ "$COUNT" -le 10 ]; then
            echo -e "  ${GREEN}✓${NC} $name: $COUNT screenshots"
        elif [ "$COUNT" -gt 0 ]; then
            echo -e "  ${YELLOW}⚠${NC} $name: $COUNT screenshots (need 3-10)"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "  ${RED}✗${NC} $name: No screenshots found"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Verify dimensions of first screenshot if sips available
        if [ "$COUNT" -gt 0 ] && command -v sips &> /dev/null; then
            FIRST=$(find "$SCREENSHOTS_DIR/$dir" -name "*.png" -type f | head -1)
            WIDTH=$(sips -g pixelWidth "$FIRST" | awk '/pixelWidth:/ {print $2}')
            HEIGHT=$(sips -g pixelHeight "$FIRST" | awk '/pixelHeight:/ {print $2}')
            
            if [ "$WIDTH" != "$expected_width" ] || [ "$HEIGHT" != "$expected_height" ]; then
                echo -e "    ${YELLOW}⚠${NC} Screenshot dimension: ${WIDTH}x${HEIGHT} (expected ${expected_width}x${expected_height})"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    else
        echo -e "  ${RED}✗${NC} $name: Folder not found"
        ERRORS=$((ERRORS + 1))
    fi
}

if [ -d "$SCREENSHOTS_DIR" ]; then
    check_screenshots "6.9-inch" "iPhone 6.9\" (16 Pro Max)" 1320 2868
    check_screenshots "6.7-inch" "iPhone 6.7\" (14 Pro Max)" 1290 2796
    check_screenshots "6.5-inch" "iPhone 6.5\" (11 Pro Max)" 1242 2688
else
    echo -e "  ${RED}✗${NC} Screenshots folder not found: $SCREENSHOTS_DIR"
    echo -e "  ${YELLOW}→${NC} Run: ./scripts/setup-screenshots.sh"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All assets ready for App Store submission!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Open Xcode and verify icons: open ios/Runner.xcworkspace"
    echo "  2. Review screenshots in folders"
    echo "  3. Build for App Store: make archive-ios"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Assets mostly ready with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Review warnings above and fix if needed."
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "To fix:"
    echo ""
    
    if [ ! -f "$ICON_1024" ] || [ ! -s "$ICON_1024" ]; then
        echo "App Icon:"
        echo "  1. Create square icon (1024x1024) from your logo"
        echo "  2. Save as: assets/images/app_icon_1024.png"
        echo "  3. Run: ./scripts/generate-app-icons.sh assets/images/app_icon_1024.png"
        echo ""
    fi
    
    if [ ! -d "$SCREENSHOTS_DIR" ] || [ $ERRORS -gt 0 ]; then
        echo "Screenshots:"
        echo "  1. Run: ./scripts/setup-screenshots.sh"
        echo "  2. Take screenshots for each device size (3-10 per size)"
        echo "  3. See: docs/ASSETS_GUIDE.md for instructions"
        echo ""
    fi
    
    echo "Full guide: cat docs/ASSETS_GUIDE.md"
    echo "Quick ref: cat ASSETS_QUICKREF.txt"
    echo ""
    exit 1
fi
