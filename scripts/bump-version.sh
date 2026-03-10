#!/bin/bash

# DrawkcaB Version Bump Script
# Automatically increments version in pubspec.yaml and optionally commits changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC="$FLUTTER_DIR/pubspec.yaml"

# Default values
BUMP_TYPE=""
COMMIT=false

# Function to print help
print_help() {
    cat << EOF
${BLUE}DrawkcaB Version Bump Script${NC}

${GREEN}Usage:${NC}
  $0 [BUMP_TYPE] [OPTIONS]

${GREEN}BUMP_TYPE:${NC}
  major     Bump major version (0.1.0+1 → 1.0.0+1)
  minor     Bump minor version (0.1.0+1 → 0.2.0+1)
  patch     Bump patch version (0.1.0+1 → 0.1.1+1)
  build     Increment build number only (0.1.0+1 → 0.1.0+2)

${GREEN}OPTIONS:${NC}
  --commit  Create git commit with bumped version
  --help    Show this help message

${GREEN}Examples:${NC}
  $0 minor                    # Bump minor, show changes
  $0 patch --commit           # Bump patch and commit
  $0 build                    # Increment build number only

${YELLOW}Note:${NC}
  - Version format: major.minor.patch+buildNumber
  - Build number always increments with version bumps
  - Use 'build' type to increment build number without version change

EOF
}

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

# Parse arguments
if [[ $# -eq 0 ]]; then
    print_error "No bump type specified"
    echo ""
    print_help
    exit 1
fi

# Handle --help flag first
if [[ "$1" == "--help" ]]; then
    print_help
    exit 0
fi

BUMP_TYPE="$1"

# Validate bump type early
case "$BUMP_TYPE" in
    major|minor|patch|build)
        ;;
    *)
        print_error "Invalid bump type: $BUMP_TYPE"
        print_help
        exit 1
        ;;
esac

# Check for options
for arg in "${@:2}"; do
    case "$arg" in
        --commit)
            COMMIT=true
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            print_help
            exit 1
            ;;
    esac
done

# Check if pubspec.yaml exists
if [[ ! -f "$PUBSPEC" ]]; then
    print_error "pubspec.yaml not found at $PUBSPEC"
    exit 1
fi

print_step "Reading current version from pubspec.yaml..."

# Extract current version (format: version: X.Y.Z+N)
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC" | awk '{print $2}')

if [[ -z "$CURRENT_VERSION" ]]; then
    print_error "Could not parse version from pubspec.yaml"
    exit 1
fi

print_success "Current version: $CURRENT_VERSION"

# Split version and build number
VERSION_PART="${CURRENT_VERSION%+*}"  # 0.1.0
BUILD_NUMBER="${CURRENT_VERSION#*+}"  # 1

# Split version into major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_PART"

# Bump version based on type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        print_step "Bumping major version..."
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        print_step "Bumping minor version..."
        ;;
    patch)
        PATCH=$((PATCH + 1))
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        print_step "Bumping patch version..."
        ;;
    build)
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        print_step "Incrementing build number..."
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"
print_success "New version: $NEW_VERSION"

# Update pubspec.yaml
print_step "Updating pubspec.yaml..."
sed -i '' "s/^version:.*$/version: $NEW_VERSION/" "$PUBSPEC"

# Verify update
UPDATED_VERSION=$(grep "^version:" "$PUBSPEC" | awk '{print $2}')
if [[ "$UPDATED_VERSION" == "$NEW_VERSION" ]]; then
    print_success "Version updated in pubspec.yaml"
else
    print_error "Failed to update version in pubspec.yaml"
    exit 1
fi

# Show diff
echo ""
print_step "Version change:"
echo -e "  ${YELLOW}$CURRENT_VERSION${NC} → ${GREEN}$NEW_VERSION${NC}"

# Commit if requested
if [[ "$COMMIT" == true ]]; then
    if ! git -C "$FLUTTER_DIR" rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "Not a git repository, skipping commit"
    else
        print_step "Committing changes..."
        git -C "$FLUTTER_DIR" add pubspec.yaml
        git -C "$FLUTTER_DIR" commit -m "Bump version to $NEW_VERSION" --no-verify
        print_success "Committed version bump"
    fi
fi

echo ""
print_success "Version bump complete!"
echo ""
echo "Next steps:"
echo "  1. Review the version change in pubspec.yaml"
echo "  2. Run: make archive-android  (or make archive-ios for iOS)"
echo "  3. Upload the bundle to Play Console/App Store"
echo ""
