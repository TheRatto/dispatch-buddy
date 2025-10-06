#!/bin/bash

# NOTAM Testing Script for Briefing Buddy
# This script runs all NOTAM-related tests and provides a summary

echo "🧪 Running NOTAM Tests for Briefing Buddy"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            ;;
    esac
}

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    print_status "FAIL" "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "INFO" "Flutter version: $(flutter --version | head -n 1)"

# Get dependencies
echo ""
print_status "INFO" "Getting dependencies..."
flutter pub get

# Run specific NOTAM tests
echo ""
print_status "INFO" "Running NOTAM Model Tests..."

# Test 1: NOTAM Model Tests
echo "Running api_service_test.dart..."
if flutter test test/api_service_test.dart --reporter=compact; then
    print_status "PASS" "NOTAM Model Tests completed successfully"
else
    print_status "FAIL" "NOTAM Model Tests failed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 2: NOTAM Filtering Tests
echo "Running notam_filtering_test.dart..."
if flutter test test/notam_filtering_test.dart --reporter=compact; then
    print_status "PASS" "NOTAM Filtering Tests completed successfully"
else
    print_status "FAIL" "NOTAM Filtering Tests failed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 3: Run all existing tests to ensure we didn't break anything
echo ""
print_status "INFO" "Running all existing tests to ensure compatibility..."
if flutter test --reporter=compact; then
    print_status "PASS" "All tests passed - no regressions detected"
else
    print_status "FAIL" "Some tests failed - possible regression"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Summary
echo ""
echo "=========================================="
echo "📊 Test Summary"
echo "=========================================="

if [ "$FAILED_TESTS" -eq 0 ]; then
    print_status "PASS" "All NOTAM tests completed successfully!"
    echo ""
    print_status "INFO" "NOTAM functionality is working correctly:"
    echo "  • Multi-strategy pagination"
    echo "  • Duplicate NOTAM detection"
    echo "  • FAA API parameter handling"
    echo "  • NOTAM model serialization"
    echo "  • Time-based filtering"
    echo "  • Airport code normalization"
    echo "  • Critical NOTAM detection"
else
    print_status "FAIL" "$FAILED_TESTS test suite(s) failed"
    echo ""
    print_status "WARN" "Please review the failed tests above"
fi

echo ""
print_status "INFO" "Test coverage includes:"
echo "  • NOTAM model creation and validation"
echo "  • FAA JSON parsing and error handling"
echo "  • NOTAM type classification"
echo "  • Serialization/deserialization"
echo "  • Critical NOTAM detection"
echo "  • Date validation and permanent NOTAMs"

echo ""
print_status "INFO" "To run individual test files:"
echo "  flutter test test/api_service_test.dart"
echo "  flutter test test/notam_filtering_test.dart"

echo ""
print_status "INFO" "To run with verbose output:"
echo "  flutter test --reporter=expanded"

exit $FAILED_TESTS 