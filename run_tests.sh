#!/bin/bash

# Test runner for Briefing Buddy Flutter app
# Runs all tests and generates coverage report

echo "🧪 Running Briefing Buddy Flutter Tests..."

# Run TAF date parsing tests specifically (critical for preventing regression)
echo "📅 Testing TAF date parsing (critical for preventing regression)..."
flutter test test/taf_date_parsing_test.dart --coverage

# Run all other tests
echo "🔍 Running all tests..."
flutter test --coverage

# Generate coverage report
echo "📊 Generating coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "✅ Tests completed!"
echo "📁 Coverage report available at: coverage/html/index.html"

# Check if any tests failed
if [ $? -eq 0 ]; then
    echo "🎉 All tests passed!"
else
    echo "❌ Some tests failed!"
    exit 1
fi 