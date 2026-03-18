#!/bin/bash

# DrawkcaB iOS Deployment Script
# This script automates the process of building and preparing the iOS app for App Store submission

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_URL="https://drawback.chat/api"
BUILD_DIR="$FLUTTER_DIR/build/ios"
ARCHIVE_PATH="$BUILD_DIR/archive/Runner.xcarchive"
XCODE_ARCHIVES_ROOT="$HOME/Library/Developer/Xcode/Archives"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DrawkcaB iOS Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${GREEN}► $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Change to flutter directory
cd "$FLUTTER_DIR"

# Step 1: Check prerequisites
print_step "Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

if ! command -v pod &> /dev/null; then
    print_warning "CocoaPods is not installed. Run: sudo gem install cocoapods"
fi

print_success "Prerequisites OK"
echo ""

# Step 2: Display version info
print_step "Version information..."
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
echo "  App version: $VERSION"
echo "  Backend URL: $BACKEND_URL"
echo ""

# Step 3: Clean previous build
print_step "Cleaning previous build artifacts..."
rm -rf build/ios
flutter clean
print_success "Clean complete"
echo ""

# Step 4: Get dependencies
print_step "Getting dependencies..."
flutter pub get
(cd ios && pod install)
print_success "Dependencies installed"
echo ""

# Step 5: Run tests
print_step "Running tests..."
if flutter test; then
    print_success "All tests passed"
else
    print_error "Tests failed. Please fix them before deploying."
    exit 1
fi
echo ""

# Step 6: Run analyzer
print_step "Running Flutter analyzer..."
if flutter analyze; then
    print_success "Analysis passed"
else
    print_warning "Analysis found issues. Review them before deploying."
fi
echo ""

# Step 7: Generate launch images
print_step "Generating launch images..."
sips -z 512 512 assets/images/app_icon_1024.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png >/dev/null
sips -z 1024 1024 assets/images/app_icon_1024.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png >/dev/null
sips -z 1536 1536 assets/images/app_icon_1024.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png >/dev/null
file \
    ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png \
    ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png \
    ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png
print_success "Launch images generated"
echo ""

# Step 8: Build IPA
print_step "Building release IPA..."
# Force rsync server-side process to resolve to /usr/bin/rsync.
# This avoids mixed rsync binaries during Xcode IPA packaging.
RSYNC_WRAPPER_DIR=$(mktemp -d)
trap 'rm -rf "$RSYNC_WRAPPER_DIR"' EXIT
cat > "$RSYNC_WRAPPER_DIR/rsync" <<'EOF'
#!/bin/sh
exec /usr/bin/rsync "$@"
EOF
chmod +x "$RSYNC_WRAPPER_DIR/rsync"

PATH="$RSYNC_WRAPPER_DIR:$PATH" flutter build ipa \
    --dart-define=BACKEND_URL="$BACKEND_URL" \
    --release \
    --export-options-plist=ios/ExportOptions.plist

# Step 9: Ensure objective_c.framework dSYM exists in archive
print_step "Ensuring objective_c.framework dSYM..."
OBJECTIVE_C_BINARY="$ARCHIVE_PATH/Products/Applications/Runner.app/Frameworks/objective_c.framework/objective_c"
OBJECTIVE_C_DSYM_DIR="$ARCHIVE_PATH/dSYMs/objective_c.framework.dSYM"
OBJECTIVE_C_DSYM_DWARF="$OBJECTIVE_C_DSYM_DIR/Contents/Resources/DWARF/objective_c"

if [ -f "$OBJECTIVE_C_BINARY" ]; then
    if [ ! -f "$OBJECTIVE_C_DSYM_DWARF" ]; then
        dsymutil "$OBJECTIVE_C_BINARY" -o "$OBJECTIVE_C_DSYM_DIR"
    fi

    if [ -f "$OBJECTIVE_C_DSYM_DWARF" ]; then
        FRAMEWORK_UUID=$(dwarfdump --uuid "$OBJECTIVE_C_BINARY" | awk 'NR==1 {print $2}')
        DSYM_UUID=$(dwarfdump --uuid "$OBJECTIVE_C_DSYM_DWARF" | awk 'NR==1 {print $2}')

        if [ -n "$FRAMEWORK_UUID" ] && [ "$FRAMEWORK_UUID" = "$DSYM_UUID" ]; then
            print_success "objective_c.framework dSYM present (UUID: $DSYM_UUID)"
        else
            print_warning "objective_c.framework dSYM UUID mismatch (framework: $FRAMEWORK_UUID, dSYM: $DSYM_UUID)"
        fi
    else
        print_warning "objective_c.framework dSYM could not be generated"
    fi
else
    print_warning "objective_c.framework not found in archive"
fi
echo ""

IPA_PATH=$(find "$BUILD_DIR/ipa" -maxdepth 1 -type f -name "*.ipa" | head -n 1)

if [ -n "$IPA_PATH" ] && [ -f "$IPA_PATH" ]; then
    print_success "IPA built successfully"
    IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
    echo "  IPA location: $IPA_PATH"
    echo "  IPA size: $IPA_SIZE"
else
    print_error "IPA build failed"
    exit 1
fi
echo ""

# Step 10: Copy archive to Xcode Archives with timestamped filename
print_step "Copying archive to Xcode Archives..."
if [ -d "$ARCHIVE_PATH" ]; then
    ARCHIVE_DATE_DIR=$(date '+%Y/%m/%d')
    ARCHIVE_TIMESTAMP=$(date '+%d-%m-%Y, %H.%M')
    DEST_ARCHIVE_DIR="$XCODE_ARCHIVES_ROOT/$ARCHIVE_DATE_DIR"
    DEST_ARCHIVE_PATH="$DEST_ARCHIVE_DIR/Runner $ARCHIVE_TIMESTAMP.xcarchive"

    mkdir -p "$DEST_ARCHIVE_DIR"
    rm -rf "$DEST_ARCHIVE_PATH"
    ditto "$ARCHIVE_PATH" "$DEST_ARCHIVE_PATH"

    print_success "Archive copied"
    echo "  Archive location: $DEST_ARCHIVE_PATH"
else
    print_error "Archive not found at $ARCHIVE_PATH"
    exit 1
fi
echo ""

# Step 11: Display next steps
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Validate the IPA (optional but recommended):"
echo "   xcrun altool --validate-app -f \"$IPA_PATH\" -t ios \\"
echo "     --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
echo ""
echo "2. Upload to App Store Connect:"
echo ""
echo "   Option A - Xcode (recommended for first upload):"
echo "     1. Open ios/Runner.xcworkspace in Xcode"
echo "     2. Product → Archive"
echo "     3. Window → Organizer → Distribute App"
echo ""
echo "   Option B - Command line:"
echo "     xcrun altool --upload-app -f \"$IPA_PATH\" -t ios \\"
echo "       --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
echo ""
echo "   Option C - Transporter app:"
echo "     Open the IPA in Transporter and click Deliver"
echo ""
echo "3. Configure in App Store Connect:"
echo "   - Add screenshots"
echo "   - Fill in app description"
echo "   - Set privacy details"
echo "   - Submit for review"
echo ""
echo -e "${GREEN}Build complete! 🎉${NC}"
