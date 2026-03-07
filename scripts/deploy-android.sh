#!/bin/bash

# DrawkcaB Android Deployment Script
# This script automates the process of building and preparing the Android app for Google Play Store submission

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_URL="${BACKEND_URL:-https://drawback.chat/api}"
BUILD_DIR="$FLUTTER_DIR/build/app/outputs"
AAB_PATH="$BUILD_DIR/bundle/release/app-release.aab"
KEYSTORE_PROPS="$FLUTTER_DIR/android/key.properties"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DrawkcaB Android Deployment${NC}"
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

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check Java
if ! command -v java &> /dev/null; then
    print_error "Java is not installed or not in PATH"
    print_error "Please install JDK 17 or later"
    exit 1
fi

# Verify Java version
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    print_warning "Java version $JAVA_VERSION detected. JDK 17+ recommended"
fi

# Check signing configuration
if [ ! -f "$KEYSTORE_PROPS" ]; then
    print_warning "key.properties not found at: $KEYSTORE_PROPS"
    print_warning "Build will use debug signing (NOT suitable for Play Store)"
    print_warning "See docs/ANDROID_DEPLOYMENT.md for keystore setup instructions"
else
    print_success "Signing configuration found"
    
    # Verify keystore file exists
    KEYSTORE_FILE=$(grep "storeFile=" "$KEYSTORE_PROPS" | cut -d= -f2)
    if [ -n "$KEYSTORE_FILE" ] && [ ! -f "$KEYSTORE_FILE" ]; then
        # Try relative path from android directory
        KEYSTORE_FILE_REL="$FLUTTER_DIR/android/$KEYSTORE_FILE"
        if [ ! -f "$KEYSTORE_FILE_REL" ]; then
            print_error "Keystore file not found: $KEYSTORE_FILE"
            print_error "Check storeFile path in key.properties"
            exit 1
        fi
    fi
fi

print_success "Prerequisites OK"
echo ""

# Step 2: Display version info
print_step "Version information..."
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION" | cut -d+ -f1)
BUILD_NUMBER=$(echo "$VERSION" | cut -d+ -f2)
echo "  App version: $VERSION_NAME"
echo "  Build number: $BUILD_NUMBER"
echo "  Backend URL: $BACKEND_URL"
echo "  Package: chat.drawback.flutter"
echo ""

# Step 3: Clean previous build
print_step "Cleaning previous build artifacts..."
rm -rf build/app/outputs
flutter clean
print_success "Clean complete"
echo ""

# Step 4: Get dependencies
print_step "Getting dependencies..."
flutter pub get
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

# Step 7: Build App Bundle
print_step "Building release App Bundle (AAB)..."
flutter build appbundle \
    --dart-define=BACKEND_URL="$BACKEND_URL" \
    --release

if [ -f "$AAB_PATH" ]; then
    print_success "App Bundle built successfully"
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo "  AAB location: $AAB_PATH"
    echo "  AAB size: $AAB_SIZE"
    
    # Check if it was signed with release key
    if [ -f "$KEYSTORE_PROPS" ]; then
        print_success "Bundle signed with release keystore"
    else
        print_warning "Bundle signed with debug key - NOT suitable for Play Store"
    fi
else
    print_error "App Bundle build failed"
    exit 1
fi
echo ""

# Step 8: Display next steps
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Test the App Bundle locally (optional):"
echo "   # Install bundletool if not already installed"
echo "   brew install bundletool"
echo ""
echo "   # Generate APK set from bundle"
echo "   bundletool build-apks --bundle=\"$AAB_PATH\" \\"
echo "     --output=build/app.apks \\"
echo "     --ks=~/upload-keystore.jks \\"
echo "     --ks-key-alias=upload"
echo ""
echo "   # Install on connected device"
echo "   bundletool install-apks --apks=build/app.apks"
echo ""
echo "2. Upload to Google Play Console:"
echo "   https://play.google.com/console"
echo ""
echo "   For internal testing track:"
echo "     1. Go to Release → Testing → Internal testing"
echo "     2. Click 'Create new release'"
echo "     3. Upload: $AAB_PATH"
echo "     4. Fill in release notes"
echo "     5. Review and rollout"
echo ""
echo "   For production:"
echo "     1. Go to Release → Production"
echo "     2. Click 'Create new release'"
echo "     3. Upload: $AAB_PATH"
echo "     4. Fill in release notes"
echo "     5. Review and start rollout"
echo ""
echo "3. Monitor release:"
echo "   - Check Android vitals for crashes"
echo "   - Monitor user reviews"
echo "   - Watch install metrics"
echo ""

if [ ! -f "$KEYSTORE_PROPS" ]; then
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}⚠ WARNING: RELEASE SIGNING NOT CONFIGURED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "This build was signed with DEBUG keys and CANNOT be uploaded to Play Store!"
    echo ""
    echo "To configure release signing:"
    echo "1. Create a keystore:"
    echo "   keytool -genkey -v -keystore ~/upload-keystore.jks \\"
    echo "     -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
    echo ""
    echo "2. Create android/key.properties:"
    echo "   storePassword=YOUR_PASSWORD"
    echo "   keyPassword=YOUR_PASSWORD"
    echo "   keyAlias=upload"
    echo "   storeFile=/Users/YOUR_USERNAME/upload-keystore.jks"
    echo ""
    echo "3. Re-run this script"
    echo ""
    echo "See docs/ANDROID_DEPLOYMENT.md for detailed instructions."
    echo ""
    exit 1
fi

echo -e "${GREEN}Build complete! 🎉${NC}"
echo ""
echo "App Bundle ready for Play Store upload:"
echo "  $AAB_PATH"
