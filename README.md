# SwiftPrintTrace

A Swift Package Manager library providing native Swift bindings for the [PrintTrace](https://github.com/bfhayes/PrintTrace) C++ image processing library. Transform images of physical objects into precise CAD-compatible DXF vector files with advanced pipeline control and real-time visualization.

## 🌟 Features

### Core Functionality
- **Async/Await API**: Native Swift concurrency with structured cancellation
- **SwiftUI Integration**: `@Published` properties and `@MainActor` safety
- **CAD-Optimized Processing**: High-precision contour extraction and DXF export
- **Comprehensive Error Handling**: Localized error messages with recovery suggestions

### Advanced Pipeline Control ✨
- **Stage-by-Stage Processing**: Process to any of 8 intermediate pipeline stages
- **Real-time Visualization**: Get image data at each processing step for UI display
- **Parameter Ranges API**: Dynamic parameter bounds for proper UI slider configuration
- **Multi-Contour Detection**: Preserve complex objects with multiple parts

### Platform Support
- **macOS 10.15+**: ✅ Full desktop functionality with file system access
- **Linux**: ✅ Command-line processing and automation  
- **iOS 13.0+**: 🚧 Infrastructure ready, requires PrintTrace C++ library iOS support
- **watchOS/tvOS**: 🚧 Infrastructure ready, requires PrintTrace C++ library iOS support

> **Note**: iOS support requires the underlying PrintTrace C++ library to be compiled for iOS architectures. The Swift package includes complete iOS infrastructure and APIs, but depends on PrintTrace C++ gaining iOS support.

## 🚀 Quick Start

### macOS/Linux Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftPrintTrace", from: "1.0.0")
]
```

Install the PrintTrace C++ library:
```bash
# Install PrintTrace library system-wide
make install-lib  # from PrintTrace repository
```

### iOS Installation

iOS requires additional setup for the XCFramework:

```bash
# Clone and run the iOS setup script
git clone https://github.com/your-org/SwiftPrintTrace
cd SwiftPrintTrace
Scripts/setup-ios.sh
```

## 📖 Usage Examples

### Basic Image Processing

```swift
import SwiftPrintTrace

let printTrace = PrintTrace()

// Process image to contour
let result = try await printTrace.processImage(at: "photo.jpg")
print("Extracted \(result.contour.pointCount) contour points")
print("Object area: \(result.contour.area) mm²")

// Export to DXF
try await printTrace.processImageToDXF(
    imagePath: "photo.jpg", 
    outputPath: "object.dxf"
)
```

### iOS UIImage Processing

```swift
import SwiftPrintTrace
import UIKit

let printTrace = PrintTrace()
let image = UIImage(named: "object_photo")!

// Process UIImage directly
let result = try await printTrace.processImage(image)

// Export to app's Documents directory
let dxfURL = try await printTrace.exportDXFToDocuments(
    image: image,
    fileName: "traced_object.dxf"
)
```

### Real-time Pipeline Visualization

```swift
// Process to specific pipeline stage for UI visualization
let stageResult = try await printTrace.processImageToStage(
    at: imagePath,
    toStage: .lightboxCropped  // or .normalized, .objectDetected, etc.
)

// Display intermediate image in UI
if let imageData = stageResult.imageData {
    // Convert to UIImage/NSImage for display
    let intermediateImage = convertToImage(imageData)
}

// Get final contour if available
if let contour = stageResult.contour {
    print("Stage \(stageResult.stage): \(contour.pointCount) points")
}
```

### SwiftUI Integration with Progress

```swift
struct ProcessingView: View {
    @StateObject private var printTrace = PrintTrace()
    @State private var imagePath = ""
    
    var body: some View {
        VStack {
            if printTrace.isProcessing {
                if let progress = printTrace.progress {
                    ProgressView(progress.stage, value: progress.progress, total: 1.0)
                }
            }
            
            Button("Process Image") {
                Task {
                    try await printTrace.processImage(at: imagePath)
                }
            }
            .disabled(printTrace.isProcessing)
        }
    }
}
```

### Parameter Tuning with UI Controls

```swift
// Get parameter ranges for UI sliders
let ranges = PrintTrace.getParameterRanges()

var params = ProcessingParameters.default

// Fine-tune threshold detection
params.thresholdOffset = 25.0  // -50 to +50
params.useAdaptiveThreshold = true

// Preserve fine detail
params.disableMorphology = true  // Disable cleaning for peripheral detail

// Multi-contour detection
params.mergeNearbyContours = true
params.contourMergeDistanceMM = 10.0  // Merge contours within 10mm

// Process with custom parameters
let result = try await printTrace.processImage(at: imagePath, parameters: params)
```

### Advanced Processing Control

```swift
// Use preset parameter configurations
let detailParams = ProcessingParameters.preserveDetail  // Max detail retention
let multiParams = ProcessingParameters.multiContour     // Multi-part objects
let fastParams = ProcessingParameters.fastProcessing    // Speed over precision

// Process through all pipeline stages
for stage in PipelineStage.allCases {
    let result = try await printTrace.processImageToStage(
        at: imagePath, 
        toStage: stage
    )
    print("Stage \(stage.description): \(result.imageData?.count ?? 0) bytes")
}
```

## 🛠️ Advanced Features

### Pipeline Stages

SwiftPrintTrace provides access to 8 intermediate processing stages:

1. **Loaded**: Original grayscale image
2. **Lightbox Cropped**: Perspective-corrected to lightbox boundary  
3. **Normalized**: CLAHE lighting normalization applied
4. **Boundary Detected**: Lightbox boundary identified
5. **Object Detected**: Object contour extracted from warped image
6. **Smoothed**: Optional smoothing applied
7. **Dilated**: Optional dilation applied  
8. **Final**: Validated final contour

### Parameter Ranges API

Get proper parameter bounds for UI controls:

```swift
let ranges = PrintTrace.getParameterRanges()

// Create sliders with correct bounds
Slider(value: $params.thresholdOffset, in: ranges.thresholdOffsetRange)
Slider(value: $params.contourMergeDistanceMM, in: ranges.contourMergeDistanceRange)
```

### Error Handling

```swift
do {
    let result = try await printTrace.processImage(at: imagePath)
} catch PrintTraceError.fileNotFound(let message) {
    // Handle missing file
} catch PrintTraceError.noContours(let message) {
    // Handle detection failure  
} catch PrintTraceError.imageLoadFailed(let message) {
    // Handle corrupted image
}
```

## 📱 iOS-Specific Features

SwiftPrintTrace provides extensive iOS integration:

- **Direct UIImage Processing**: No need to save images to disk
- **App Sandbox Support**: Automatic handling of iOS file restrictions
- **Documents Directory Export**: DXF files saved to shareable location
- **Photo Library Integration**: Works with PhotosPicker and UIImagePickerController
- **SwiftUI Optimized**: Native SwiftUI data types and bindings

See [iOS_INTEGRATION.md](iOS_INTEGRATION.md) for complete iOS documentation.

## 🏗️ Architecture

SwiftPrintTrace is built with a clean, layered architecture:

- **Swift Layer**: Async/await APIs, SwiftUI integration, error handling
- **C Binding Layer**: Module maps and header bridging for seamless interop  
- **C++ Core**: PrintTrace library with OpenCV-powered image processing
- **Platform Layer**: Conditional compilation for macOS/iOS/Linux differences

### Dependencies

- **PrintTrace C++ Library**: Core image processing engine
- **OpenCV 4.0+**: Computer vision and image processing
- **libdxfrw**: DXF file format support (included in PrintTrace)

## 🧪 Testing

```bash
# Run all tests
swift test

# Test specific functionality
swift test --filter testParameterRanges
swift test --filter testPipelineStageProcessing

# Test with real images
swift test --filter testRealImageProcessing
```

## 📚 Documentation

- [iOS Integration Guide](iOS_INTEGRATION.md) - Complete iOS setup and usage
- [API Reference](Sources/SwiftPrintTrace/) - Detailed API documentation
- [Examples](Examples/) - Working code examples for all platforms
- [Testing Guide](TESTING.md) - Testing setup and procedures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality  
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Projects

- [PrintTrace C++ Library](https://github.com/bfhayes/PrintTrace) - Core image processing engine
- [OpenCV](https://opencv.org) - Computer vision library
- [libdxfrw](https://github.com/codelibs/libdxfrw) - DXF file format support

---

**SwiftPrintTrace** - Transform physical objects into precise digital CAD files with the power of Swift and computer vision. Perfect for 3D printing preparation, reverse engineering, and digital fabrication workflows.