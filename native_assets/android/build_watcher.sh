#!/bin/bash

# Build Native Watcher APK
# Output: build/libs/native_watcher.apk

set -e  # Exit on error

echo "🔨 Building Native Watcher APK..."
echo ""

# Change to android directory
cd "$(dirname "$0")"

# Check if gradlew exists
if [ ! -f "./gradlew" ]; then
    echo "❌ Error: gradlew not found!"
    echo "Run: gradle wrapper --gradle-version 8.5"
    exit 1
fi

# Make gradlew executable
chmod +x ./gradlew

# Clean previous build (optional)
echo "🧹 Cleaning previous build..."
./gradlew clean

# Build the APK
echo ""
echo "🔨 Building APK with test-driven configuration support..."
./gradlew buildWatcherApk

# Check if APK was created
if [ -f "build/libs/native_watcher.apk" ]; then
    echo ""
    echo "✅ SUCCESS! Native Watcher APK built successfully!"
    echo ""
    echo "📦 Location: build/libs/native_watcher.apk"
    echo "📊 Size: $(du -h build/libs/native_watcher.apk | cut -f1)"
    echo ""
    echo "🎯 Features included:"
    echo "   ✅ Test-driven configuration (allow/deny/ignore)"
    echo "   ✅ Permission handling"
    echo "   ✅ Location precision selection"
    echo "   ✅ Google Sign-In picker dismissal"
    echo "   ✅ ANR dialog handling"
    echo ""
    echo "🚀 Ready to use in your tests!"
else
    echo ""
    echo "❌ Error: APK not found at build/libs/native_watcher.apk"
    exit 1
fi
