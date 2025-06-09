# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

SwiftPrintTrace is a Swift Package Manager library that provides Swift bindings for the PrintTrace C++ image processing library. It wraps a high-performance C++ backend with native Swift ergonomics for CAD-optimized image to DXF conversion.

### Package Structure
- **CPrintTrace**: System library target that links to the native PrintTrace C library via pkg-config
- **SwiftPrintTrace**: Main Swift wrapper providing async/await APIs and SwiftUI integration
- Uses module.modulemap to expose C APIs to Swift through a clean shim header

### Key Components
- `PrintTrace.swift`: Main API class with `@MainActor` concurrency and `@Published` properties for SwiftUI
- `PrintTraceModels.swift`: Swift data models including ProcessingParameters, ProcessingResult, and ProcessedContour  
- `PrintTraceError.swift`: Comprehensive error handling with localized messages and recovery suggestions
- Async/await APIs with structured concurrency and cancellation support

## Development Commands

### Building
```bash
swift build
```

### Running Tests
```bash
swift test
```

### Building for Release
```bash
swift build -c release
```

### Running Single Test
```bash
swift test --filter <test-name>
```

## Dependencies

This package requires the PrintTrace C++ library to be installed system-wide:
- Install via: `make install-lib` from the PrintTrace repository
- Verify with: `pkg-config --exists printtrace`
- Package uses pkg-config for automatic library discovery

## Key Development Notes

### Platform Requirements
- Requires macOS 10.15+/iOS 13.0+ for async/await and SwiftUI support
- Uses StrictConcurrency experimental feature
- Main API is `@MainActor` with background processing

### Memory Management
- Swift automatically manages C memory via RAII patterns
- C structures are converted to Swift types and cleaned up automatically
- Use `defer` blocks for cleanup in error paths

### Error Handling Pattern
All processing methods throw `PrintTraceError` which maps C error codes to Swift enum cases with localized descriptions and recovery suggestions.

### Concurrency Model
- `PrintTrace` class is `@MainActor` for UI thread safety
- Processing happens on background queues via `Task`
- Progress updates are published to main thread
- Full cancellation support via `Task.cancel()`