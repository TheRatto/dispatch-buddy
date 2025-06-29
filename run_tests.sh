#!/bin/bash

echo "🧪 Running DecoderService Tests..."
echo "=================================="

# Run the decoder service tests
flutter test test/decoder_service_test.dart

# Check if tests passed
if [ $? -eq 0 ]; then
    echo "✅ Core tests passed!"
else
    echo "❌ Core tests failed!"
    exit 1
fi

echo ""
echo "🧪 Running Concurrent Weather Tests..."
echo "====================================="

# Run the concurrent weather tests
flutter test test/concurrent_weather_test.dart

# Check if tests passed
if [ $? -eq 0 ]; then
    echo "✅ Concurrent weather tests passed!"
else
    echo "❌ Concurrent weather tests failed!"
    exit 1
fi

echo ""
echo "🧪 Running Period Detector Tests..."
echo "=================================="

# Run the period detector tests
flutter test test/period_detector_test.dart

# Check if tests passed
if [ $? -eq 0 ]; then
    echo "✅ Period detector tests passed!"
else
    echo "❌ Period detector tests failed!"
    exit 1
fi

echo ""
echo "🎉 All tests passed!"
echo ""
echo "📊 Test Summary:"
echo "================="
echo "- DecoderService core functionality"
echo "- TAF period detection"
echo "- Weather parsing"
echo "- Text formatting"
echo "- Concurrent weather handling"
echo "- Period detection logic"
echo "- Weather code detection"
echo "- Changed elements detection" 