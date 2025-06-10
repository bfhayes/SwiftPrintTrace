# iOS CMake toolchain file
# Based on the popular ios-cmake toolchain

# Standard settings
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_VERSION 13.0)
set(CMAKE_OSX_DEPLOYMENT_TARGET 13.0)

# Determine the platform
if(NOT DEFINED PLATFORM)
    set(PLATFORM "OS64")
endif()

# Set the architectures based on platform
if(PLATFORM STREQUAL "OS64")
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    set(CMAKE_SYSTEM_PROCESSOR "arm64")
    set(PLATFORM_INT "DEVICE")
elseif(PLATFORM STREQUAL "SIMULATOR64")
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
    set(CMAKE_SYSTEM_PROCESSOR "x86_64")
    set(PLATFORM_INT "SIMULATOR")
endif()

# Set the sysroot
execute_process(
    COMMAND xcrun --sdk iphoneos --show-sdk-path
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT_DEVICE
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND xcrun --sdk iphonesimulator --show-sdk-path
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT_SIMULATOR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(PLATFORM_INT STREQUAL "DEVICE")
    set(CMAKE_OSX_SYSROOT ${CMAKE_OSX_SYSROOT_DEVICE})
else()
    set(CMAKE_OSX_SYSROOT ${CMAKE_OSX_SYSROOT_SIMULATOR})
endif()

# Find the toolchain
execute_process(
    COMMAND xcrun --find clang
    OUTPUT_VARIABLE CMAKE_C_COMPILER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND xcrun --find clang++
    OUTPUT_VARIABLE CMAKE_CXX_COMPILER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Set iOS specific compiler flags
set(CMAKE_C_FLAGS_INIT "-fembed-bitcode")
set(CMAKE_CXX_FLAGS_INIT "-fembed-bitcode")

# Standard iOS settings
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Don't search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Disable linking to system libraries
set(CMAKE_MACOSX_BUNDLE YES)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO")

# Disable bitcode for now (can be enabled later if needed)
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")

# Set minimum iOS version
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${CMAKE_SYSTEM_VERSION})