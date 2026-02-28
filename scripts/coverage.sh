#!/bin/bash

# DrawkcaB Flutter Coverage Report Generator
# 
# Usage:
#   ./scripts/coverage.sh                    # Generate coverage report
#   ./scripts/coverage.sh --view             # Generate and open HTML report
#   ./scripts/coverage.sh --check-threshold  # Check against minimum coverage
#   ./scripts/coverage.sh --clean            # Clean coverage files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COVERAGE_DIR="$PROJECT_ROOT/coverage"
COVERAGE_HTML_DIR="$COVERAGE_DIR/html"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
show_usage() {
    cat << EOF
Usage: ./scripts/coverage.sh [OPTION]

Options:
  (no args)      Generate LCOV coverage report
  --view         Generate and open HTML coverage report in browser
  --check        Check coverage against minimum threshold (80%)
  --clean        Remove all coverage files
  --threshold N  Check against custom threshold (e.g., 75)
  --help         Show this help message

Examples:
  ./scripts/coverage.sh                    # Generate report
  ./scripts/coverage.sh --view             # Generate and open in browser
  ./scripts/coverage.sh --check --threshold 85
EOF
}

generate_coverage() {
    echo -e "${YELLOW}Generating coverage report...${NC}"
    cd "$PROJECT_ROOT"
    
    # Run tests with coverage
    flutter test --coverage --no-test-assets 2>&1 | grep -E "(test|coverage|passed|failed)" || true
    
    if [ -f "$COVERAGE_DIR/lcov.info" ]; then
        echo -e "${GREEN}✓ Coverage report generated at coverage/lcov.info${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to generate coverage report${NC}"
        return 1
    fi
}

generate_html_report() {
    echo -e "${YELLOW}Generating HTML coverage report...${NC}"
    
    if ! command -v genhtml &> /dev/null; then
        echo -e "${YELLOW}Installing lcov...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install lcov
        else
            echo -e "${RED}Please install lcov: sudo apt-get install lcov${NC}"
            return 1
        fi
    fi
    
    rm -rf "$COVERAGE_HTML_DIR"
    mkdir -p "$COVERAGE_HTML_DIR"
    
    genhtml -o "$COVERAGE_HTML_DIR" "$COVERAGE_DIR/lcov.info" 2>&1 | grep -E "(genhtml|index.html)" || true
    
    if [ -f "$COVERAGE_HTML_DIR/index.html" ]; then
        echo -e "${GREEN}✓ HTML report generated at coverage/html/index.html${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to generate HTML report${NC}"
        return 1
    fi
}

open_html_report() {
    if [ -f "$COVERAGE_HTML_DIR/index.html" ]; then
        echo -e "${YELLOW}Opening coverage report in browser...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$COVERAGE_HTML_DIR/index.html"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open "$COVERAGE_HTML_DIR/index.html"
        else
            echo -e "${YELLOW}Please open: $COVERAGE_HTML_DIR/index.html${NC}"
        fi
    else
        echo -e "${RED}HTML report not found. Run with --view to generate it.${NC}"
        return 1
    fi
}

check_coverage_threshold() {
    local threshold=${1:-80}
    
    if [ ! -f "$COVERAGE_DIR/lcov.info" ]; then
        echo -e "${RED}✗ Coverage report not found. Run without arguments first.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Checking coverage against ${threshold}% threshold...${NC}"
    
    # Extract coverage percentage from lcov.info (format: LF:3, LH:1, etc)
    local lines=$(grep "^LF:" "$COVERAGE_DIR/lcov.info" | awk -F: '{sum+=$2} END {print sum}')
    local covered=$(grep "^LH:" "$COVERAGE_DIR/lcov.info" | awk -F: '{sum+=$2} END {print sum}')
    
    if [ -z "$lines" ] || [ "$lines" -eq 0 ] || [ -z "$covered" ]; then
        echo -e "${RED}✗ Could not parse coverage data${NC}"
        return 1
    fi
    
    local percentage=$((covered * 100 / lines))
    
    echo "Coverage: ${percentage}% (threshold: ${threshold}%)"
    
    if [ "$percentage" -ge "$threshold" ]; then
        echo -e "${GREEN}✓ Coverage meets threshold!${NC}"
        return 0
    else
        echo -e "${RED}✗ Coverage below threshold! (${percentage}% < ${threshold}%)${NC}"
        return 1
    fi
}

clean_coverage() {
    echo -e "${YELLOW}Cleaning coverage files...${NC}"
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"
    echo -e "${GREEN}✓ Coverage files cleaned${NC}"
}

# Main script
if [ $# -eq 0 ]; then
    # Default: generate coverage
    generate_coverage
elif [ "$1" == "--help" ]; then
    show_usage
elif [ "$1" == "--view" ]; then
    generate_coverage && generate_html_report && open_html_report
elif [ "$1" == "--check" ]; then
    threshold=${3:-80}
    if [ "$2" == "--threshold" ]; then
        threshold=$3
    fi
    generate_coverage && check_coverage_threshold "$threshold"
elif [ "$1" == "--threshold" ]; then
    check_coverage_threshold "$2"
elif [ "$1" == "--clean" ]; then
    clean_coverage
else
    show_usage
    exit 1
fi
