#!/bin/bash

# Screenshot Helper for App Store Submission
# Creates folder structure and provides instructions for taking screenshots

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS_DIR="$FLUTTER_DIR/screenshots"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}App Store Screenshots Helper${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create screenshot folders
echo "Setting up screenshot folders..."
mkdir -p "$SCREENSHOTS_DIR/6.9-inch"
mkdir -p "$SCREENSHOTS_DIR/6.7-inch"
mkdir -p "$SCREENSHOTS_DIR/6.5-inch"
mkdir -p "$SCREENSHOTS_DIR/12.9-inch-ipad"

echo -e "${GREEN}✓ Created folder structure:${NC}"
echo "  $SCREENSHOTS_DIR/"
echo "  ├── 6.9-inch/     (iPhone 16 Pro Max - 1320 x 2868)"
echo "  ├── 6.7-inch/     (iPhone 14 Pro Max - 1290 x 2796)"
echo "  ├── 6.5-inch/     (iPhone 11 Pro Max - 1242 x 2688)"
echo "  └── 12.9-inch-ipad/ (iPad Pro 12.9\" - 2048 x 2732)"
echo ""

# Create README in screenshots folder
cat > "$SCREENSHOTS_DIR/README.md" << 'EOF'
# App Store Screenshots

This folder contains screenshots for App Store submission.

## Required Sizes

- **6.9-inch**: iPhone 16 Pro Max (1320 x 2868 pixels)
- **6.7-inch**: iPhone 14/15 Pro Max (1290 x 2796 pixels) 
- **6.5-inch**: iPhone 11 Pro Max / XS Max (1242 x 2688 pixels)
- **12.9-inch-ipad**: iPad Pro 12.9" (2048 x 2732 pixels) - if supporting iPad

## Naming Convention

Name your screenshots descriptively:

```
01-welcome.png
02-registration.png
03-user-search.png
04-chat-request.png
05-features.png
```

## Screenshot Checklist

- [ ] 3-10 screenshots per device size
- [ ] Status bar shows 9:41 AM, full battery, full signal
- [ ] No personal information visible
- [ ] Features clearly demonstrated
- [ ] Real content (no Lorem Ipsum or placeholders)
- [ ] First screenshot is most compelling

## Taking Screenshots

See `docs/ASSETS_GUIDE.md` for detailed instructions.
EOF

echo -e "${GREEN}✓ Created README.md in screenshots folder${NC}"
echo ""

# Display instructions
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}How to Take Screenshots${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Method 1: iOS Simulator (Recommended)${NC}"
echo ""
echo "1. List available simulators:"
echo "   xcrun simctl list devices"
echo ""
echo "2. Launch specific simulator (examples):"
echo "   # iPhone 16 Pro Max (6.9\")"
echo "   open -a Simulator --args -CurrentDeviceUDID <iPhone-16-Pro-Max-UDID>"
echo ""
echo "   # iPhone 14 Pro Max (6.7\")"
echo "   open -a Simulator --args -CurrentDeviceUDID <iPhone-14-Pro-Max-UDID>"
echo ""
echo "3. Run your app:"
echo "   flutter run -d <simulator-id> --dart-define=BACKEND_URL=https://drawback.chat/api"
echo ""
echo "4. Take screenshots:"
echo "   - Press Cmd+S while simulator is active"
echo "   - Screenshots save to ~/Desktop"
echo ""
echo "5. Move screenshots to appropriate folder:"
echo "   mv ~/Desktop/Screenshot*.png screenshots/6.9-inch/"
echo "   # Rename files: 01-welcome.png, 02-registration.png, etc."
echo ""

echo -e "${YELLOW}Method 2: Physical Device${NC}"
echo ""
echo "1. Run app on device:"
echo "   flutter run -d <device-id> --dart-define=BACKEND_URL=https://drawback.chat/api"
echo ""
echo "2. Take screenshots:"
echo "   - Press Volume Up + Power Button"
echo ""
echo "3. Transfer to Mac:"
echo "   - AirDrop screenshots to Mac"
echo "   - Or connect device and import via Photos app"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Quick Reference${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Screenshot Requirements:"
echo "  • 6.9\": 1320 x 2868 px (iPhone 16 Pro Max)"
echo "  • 6.7\": 1290 x 2796 px (iPhone 14 Pro Max)"
echo "  • 6.5\": 1242 x 2688 px (iPhone 11 Pro Max)"
echo "  • iPad: 2048 x 2732 px (iPad Pro 12.9\")"
echo ""

echo "Suggested Screenshot Flow:"
echo "  1. Welcome/Login screen"
echo "  2. Registration flow"
echo "  3. User search/discovery"
echo "  4. Chat request interface"
echo "  5. Feature preview/overview"
echo ""

echo "View detailed guide:"
echo "  cat docs/ASSETS_GUIDE.md"
echo ""

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Launch simulator for each device size"
echo "  2. Run app and navigate through flows"
echo "  3. Take 3-10 screenshots per device size"
echo "  4. Organize in the created folders"
echo ""
