# SwiftPrintTrace Testing Guide

## Overview

This document explains how to test the SwiftPrintTrace package, including unit tests and integration tests with real image processing.

## Test Structure

### Unit Tests (`SwiftPrintTraceTests.swift`)

1. **testParameterValidation()** - Tests parameter validation with valid/invalid parameters
2. **testFileValidation()** - Tests image file validation 
3. **testPresetParameters()** - Tests parameter preset configurations
4. **testVersionInfo()** - Tests version information retrieval
5. **testContourCalculations()** - Tests contour geometry calculations
6. **testAsyncProcessing()** - Tests basic async processing behavior
7. **testRealImageProcessing()** - Integration test with real image (requires PrintTrace library)
8. **testDXFOutput()** - Tests DXF file generation (requires PrintTrace library)
9. **testProgressCallbackMemoryManagement()** - Tests callback memory management

### Test Image

The test suite includes `IMG_0707.jpeg` showing pliers on a lightbox background:
- Clear contrast between object and background
- Well-defined rectangular boundary (lightbox)
- Good test case for CAD-optimized processing
- Should produce meaningful contour results

## Running Tests

### Prerequisites

To run the full integration tests, you need:

1. **PrintTrace C++ library installed**:
   ```bash
   # Install the PrintTrace library system-wide
   cd /path/to/PrintTrace
   make install-lib
   
   # Verify installation
   pkg-config --exists printtrace && echo "✅ PrintTrace found"
   ```

2. **Library path configured** (if needed):
   ```bash
   export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"
   ```

### Running Tests

```bash
# Build the package
swift build

# Run all tests (requires PrintTrace library)
swift test

# Run specific test
swift test --filter testFileValidation

# Run unit tests only (these work without the C library)
swift test --filter testPresetParameters
swift test --filter testContourCalculations
```

### Expected Test Results

#### Unit Tests (No C Library Required)
- ✅ Parameter validation and presets
- ✅ Contour calculations with mock data
- ✅ Version info (when library available)

#### Integration Tests (Require C Library)
- ✅ Real image processing with progress callbacks
- ✅ DXF file generation and validation
- ✅ Multiple parameter preset testing
- ✅ Memory management verification

#### Sample Output
```
Testing with default parameters...
Progress: 10% - Loading image
Progress: 30% - Detecting boundary
Progress: 60% - Processing contours
Progress: 90% - Generating output
Progress: 100% - Complete
✅ default - Points: 156, Area: 2847.3mm², Time: 2.34s

Testing with fast parameters...
✅ fast - Points: 98, Area: 2831.1mm², Time: 1.67s

Testing with high precision parameters...
✅ high precision - Points: 203, Area: 2855.8mm², Time: 3.12s
```

## Common Issues

### Library Not Found
```
Library not loaded: @rpath/libprinttrace.1.dylib
```

**Solutions:**
1. Install PrintTrace library: `make install-lib`
2. Check installation: `pkg-config --libs printtrace`
3. Set library path: `export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"`

### Test Image Missing
```
⚠️ Test image not found - skipping validation test
```

**Solution:**
Ensure `IMG_0707.jpeg` exists in `Tests/SwiftPrintTraceTests/TestImages/`

### Progress Callbacks Not Working
If progress callbacks aren't received:
1. Verify the updated PrintTrace C API includes `user_data` parameters
2. Check that callbacks are being called from the C library
3. Ensure the CallbackContext is properly retained

## Manual Testing

For environments where `swift test` doesn't work due to library path issues, you can create manual test scripts:

```swift
// manual_test.swift
import SwiftPrintTrace

let printTrace = PrintTrace()
print("Version: \(PrintTrace.version)")

// Test with your own image
Task {
    let result = try await printTrace.processImage(at: "/path/to/image.jpg")
    print("Processed \(result.contour.pointCount) points")
}
```

Then compile and run:
```bash
swiftc -I .build/debug -L .build/debug -lSwiftPrintTrace manual_test.swift
./manual_test
```

## CI/CD Considerations

For continuous integration:
1. Install PrintTrace library in CI environment
2. Consider mocking the C library for unit tests only
3. Use conditional tests that skip integration tests when library unavailable
4. Test with multiple parameter presets for comprehensive coverage

## Performance Benchmarks

Expected performance for the test image (pliers, ~2.5MB):
- **Fast processing**: ~1.5-2s, ~100 points
- **Default processing**: ~2-3s, ~150 points  
- **High precision**: ~3-4s, ~200 points

Significant deviations may indicate issues with the C library or parameters.