#!/bin/bash

echo "🔧 Fixing PrintTrace library paths for Xcode integration..."

# Check if library exists
if [ ! -f "/usr/local/lib/libprinttrace.1.dylib" ]; then
    echo "❌ PrintTrace library not found at /usr/local/lib/libprinttrace.1.dylib"
    echo "   Please install PrintTrace first: make install-lib"
    exit 1
fi

echo "📋 Current library install name:"
otool -D /usr/local/lib/libprinttrace.1.dylib

echo ""
echo "🔧 Fixing install name to absolute path..."
sudo install_name_tool -id /usr/local/lib/libprinttrace.1.dylib /usr/local/lib/libprinttrace.1.dylib

echo ""
echo "✅ Updated library install name:"
otool -D /usr/local/lib/libprinttrace.1.dylib

echo ""
echo "🎉 Library paths fixed! Your Xcode app should now work without additional configuration."
echo ""
echo "If you still have issues, try these solutions:"
echo "1. Clean and rebuild your Xcode project (⌘+Shift+K, then ⌘+B)"
echo "2. Delete DerivedData folder"
echo "3. Add /usr/local/lib to your app's Runpath Search Paths in Build Settings"