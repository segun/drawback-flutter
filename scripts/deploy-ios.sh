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
IPA_PATH="$BUILD_DIR/ipa/drawback_flutter.ipa"
ARCHIVE_PATH="$BUILD_DIR/archive/Runner.xcarchive"

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
cd ios && pod install && cd ..
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

# Step 7: Build IPA
print_step "Building release IPA..."
flutter build ipa \
    --dart-define=BACKEND_URL="$BACKEND_URL" \
    --release \
    --export-options-plist=ios/ExportOptions.plist

if [ -f "$IPA_PATH" ]; then
    print_success "IPA built successfully"
    IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
    echo "  IPA location: $IPA_PATH"
    echo "  IPA size: $IPA_SIZE"
else
    print_error "IPA build failed"
    exit 1
fi
echo ""

# Step 8: Display next steps
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
