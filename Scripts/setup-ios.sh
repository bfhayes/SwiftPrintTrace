#!/bin/bash
set -e

# iOS Setup Script for SwiftPrintTrace
# This script helps set up the complete iOS development environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 SwiftPrintTrace iOS Setup${NC}"
echo "This script will help you set up SwiftPrintTrace for iOS development."
echo

# Check requirements
echo -e "${YELLOW}📋 Checking requirements...${NC}"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode not found. Please install Xcode from the App Store.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Xcode found${NC}"

# Check CMake
if ! command -v cmake &> /dev/null; then
    echo -e "${YELLOW}⚠️  CMake not found. Installing via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install cmake
    else
        echo -e "${RED}❌ Please install CMake manually: https://cmake.org/download/${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ CMake found${NC}"

# Check for PrintTrace source
PRINTTRACE_DIR="${PRINTTRACE_SOURCE_DIR:-$PROJECT_DIR/../PrintTrace}"
if [ ! -d "$PRINTTRACE_DIR" ]; then
    echo -e "${YELLOW}📦 PrintTrace source not found. Cloning...${NC}"
    cd "$(dirname "$PROJECT_DIR")"
    git clone https://github.com/bfhayes/PrintTrace.git
    cd PrintTrace
    git submodule update --init --recursive
    PRINTTRACE_DIR="$(pwd)"
    echo -e "${GREEN}✅ PrintTrace source cloned to $PRINTTRACE_DIR${NC}"
else
    echo -e "${GREEN}✅ PrintTrace source found at $PRINTTRACE_DIR${NC}"
fi

# Check for OpenCV (required for building)
echo -e "${YELLOW}🔍 Checking OpenCV...${NC}"
if ! pkg-config --exists opencv4; then
    echo -e "${YELLOW}⚠️  OpenCV not found. This is required for building PrintTrace.${NC}"
    echo "Please install OpenCV using one of these methods:"
    echo "  • Homebrew: brew install opencv"
    echo "  • Build from source: https://opencv.org/releases/"
    echo
    read -p "Do you want to install OpenCV via Homebrew now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v brew &> /dev/null; then
            brew install opencv
        else
            echo -e "${RED}❌ Homebrew not found. Please install manually.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  Skipping OpenCV installation. You'll need to install it manually.${NC}"
    fi
else
    echo -e "${GREEN}✅ OpenCV found${NC}"
fi

# Build XCFramework
echo
echo -e "${YELLOW}🏗️  Building XCFramework...${NC}"
export PRINTTRACE_SOURCE_DIR="$PRINTTRACE_DIR"
"$SCRIPT_DIR/build-xcframework.sh"

# Update Package.swift to enable iOS framework
echo -e "${YELLOW}📝 Updating Package.swift for iOS support...${NC}"
cd "$PROJECT_DIR"

# Uncomment the XCFramework target
sed -i.bak 's|^        // \.binaryTarget($|        .binaryTarget(|' Package.swift
sed -i.bak 's|^        //     name: "PrintTraceFramework",$|            name: "PrintTraceFramework",|' Package.swift
sed -i.bak 's|^        //     path: "Frameworks/PrintTrace.xcframework"$|            path: "Frameworks/PrintTrace.xcframework"|' Package.swift
sed -i.bak 's|^        // ),$|        ),|' Package.swift

# Update dependencies
sed -i.bak 's|\.target(name: "CPrintTrace")$|.target(name: "CPrintTrace", condition: .when(platforms: [.macOS, .linux])),|' Package.swift
sed -i.bak 's|^                // TODO: Add iOS framework dependency when XCFramework is built:$||' Package.swift
sed -i.bak 's|^                // \.target(name: "PrintTraceFramework", condition: \.when(platforms: \[\.iOS, \.tvOS, \.watchOS\]))$|                .target(name: "PrintTraceFramework", condition: .when(platforms: [.iOS, .tvOS, .watchOS]))|' Package.swift

# Remove backup file
rm -f Package.swift.bak

echo -e "${GREEN}✅ Package.swift updated for iOS support${NC}"

# Test the build
echo -e "${YELLOW}🧪 Testing build...${NC}"
if swift build; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed. Please check the error messages above.${NC}"
    exit 1
fi

# Success message
echo
echo -e "${GREEN}🎉 iOS setup complete!${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Add SwiftPrintTrace to your iOS project as a Swift package dependency"
echo "2. Import SwiftPrintTrace in your iOS app"
echo "3. Check out the examples in Examples/iOS/"
echo "4. Read the iOS integration guide: iOS_INTEGRATION.md"
echo
echo -e "${BLUE}Key features now available:${NC}"
echo "• Direct UIImage processing"
echo "• Pipeline stage visualization"
echo "• DXF export to Documents directory"
echo "• Parameter ranges for UI controls"
echo "• SwiftUI integration examples"
echo
echo -e "${YELLOW}⚠️  Remember:${NC}"
echo "• iOS apps run in a sandbox - file access is limited"
echo "• Large images may take longer to process on mobile devices"
echo "• Use background processing for better user experience"