#!/bin/bash
set -e

# Build script for creating PrintTrace XCFramework for iOS
# This script builds the PrintTrace C++ library for all iOS architectures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
FRAMEWORKS_DIR="$PROJECT_DIR/Frameworks"

echo "🏗️  Building PrintTrace XCFramework for iOS..."

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$FRAMEWORKS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we have the PrintTrace source
PRINTTRACE_DIR="${PRINTTRACE_SOURCE_DIR:-../PrintTrace}"
if [ ! -d "$PRINTTRACE_DIR" ]; then
    echo -e "${RED}❌ PrintTrace source directory not found at $PRINTTRACE_DIR${NC}"
    echo "Please set PRINTTRACE_SOURCE_DIR environment variable or place PrintTrace source in ../PrintTrace"
    exit 1
fi

echo -e "${GREEN}✅ Found PrintTrace source at $PRINTTRACE_DIR${NC}"

# Build for iOS Simulator (x86_64 and arm64)
echo -e "${YELLOW}📱 Building for iOS Simulator...${NC}"
cd "$BUILD_DIR"
mkdir -p ios-simulator
cd ios-simulator

cmake "$PRINTTRACE_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$PRINTTRACE_DIR/cmake/ios.toolchain.cmake" \
    -DPLATFORM=SIMULATOR64 \
    -DDEPLOYMENT_TARGET=13.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=install

make -j$(sysctl -n hw.ncpu)
make install

# Build for iOS Device (arm64)
echo -e "${YELLOW}📱 Building for iOS Device...${NC}"
cd "$BUILD_DIR"
mkdir -p ios-device
cd ios-device

cmake "$PRINTTRACE_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$PRINTTRACE_DIR/cmake/ios.toolchain.cmake" \
    -DPLATFORM=OS64 \
    -DDEPLOYMENT_TARGET=13.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=install

make -j$(sysctl -n hw.ncpu)
make install

# Create framework structure for each platform
echo -e "${YELLOW}📦 Creating framework structures...${NC}"

create_framework() {
    local platform=$1
    local install_dir="$BUILD_DIR/$platform/install"
    local framework_dir="$BUILD_DIR/$platform/PrintTrace.framework"
    
    mkdir -p "$framework_dir/Headers"
    
    # Copy headers
    cp -r "$install_dir/include/"* "$framework_dir/Headers/"
    
    # Copy library (rename to framework name)
    cp "$install_dir/lib/libprinttrace.a" "$framework_dir/PrintTrace"
    
    # Create Info.plist
    cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>PrintTrace</string>
    <key>CFBundleIdentifier</key>
    <string>com.printtrace.framework</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PrintTrace</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF
}

create_framework "ios-simulator"
create_framework "ios-device"

# Create XCFramework
echo -e "${YELLOW}🎁 Creating XCFramework...${NC}"
cd "$BUILD_DIR"

xcodebuild -create-xcframework \
    -framework ios-simulator/PrintTrace.framework \
    -framework ios-device/PrintTrace.framework \
    -output "$FRAMEWORKS_DIR/PrintTrace.xcframework"

echo -e "${GREEN}✅ XCFramework created successfully at $FRAMEWORKS_DIR/PrintTrace.xcframework${NC}"

# Create module map for the framework
mkdir -p "$FRAMEWORKS_DIR/PrintTrace.xcframework/ios-arm64/PrintTrace.framework/Modules"
cat > "$FRAMEWORKS_DIR/PrintTrace.xcframework/ios-arm64/PrintTrace.framework/Modules/module.modulemap" << EOF
framework module PrintTrace {
    header "PrintTraceAPI.h"
    export *
}
EOF

# Copy module map to simulator framework too
mkdir -p "$FRAMEWORKS_DIR/PrintTrace.xcframework/ios-arm64_x86_64-simulator/PrintTrace.framework/Modules"
cp "$FRAMEWORKS_DIR/PrintTrace.xcframework/ios-arm64/PrintTrace.framework/Modules/module.modulemap" \
   "$FRAMEWORKS_DIR/PrintTrace.xcframework/ios-arm64_x86_64-simulator/PrintTrace.framework/Modules/"

echo -e "${GREEN}🎉 PrintTrace XCFramework build complete!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. The XCFramework is ready at $FRAMEWORKS_DIR/PrintTrace.xcframework"
echo "2. You can now use 'swift build' to build the iOS-compatible Swift package"
echo "3. The package will automatically use the XCFramework for iOS targets"