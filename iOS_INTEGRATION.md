# iOS Integration Guide for SwiftPrintTrace

This guide explains how to integrate SwiftPrintTrace into iOS applications.

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.8+
- **PrintTrace C++ library compiled for iOS** (currently requires custom iOS support)

> **Important**: This guide describes the iOS integration that will be available once the PrintTrace C++ library supports iOS compilation. The Swift package includes complete iOS infrastructure, but the underlying C++ library currently supports macOS/Linux/Windows only.

## Quick Start

### 1. Installation

Add SwiftPrintTrace to your iOS project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftPrintTrace", from: "1.0.0")
]
```

### 2. Build the XCFramework

Before using the package on iOS, you need to build the PrintTrace XCFramework:

```bash
# Clone the PrintTrace C++ library
git clone https://github.com/bfhayes/PrintTrace
cd SwiftPrintTrace

# Set the source directory and build
PRINTTRACE_SOURCE_DIR=../PrintTrace Scripts/build-xcframework.sh
```

This creates `Frameworks/PrintTrace.xcframework` which is required for iOS builds.

### 3. Basic Usage

```swift
import SwiftPrintTrace
import UIKit

class ImageProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var result: ProcessingResult?
    
    private let printTrace = PrintTrace()
    
    func processImage(_ image: UIImage) async {
        do {
            isProcessing = true
            
            // Process UIImage directly
            let result = try await printTrace.processImage(image)
            
            await MainActor.run {
                self.result = result
                self.isProcessing = false
            }
        } catch {
            print("Processing failed: \(error)")
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
}
```

## iOS-Specific Features

### Direct UIImage Processing

Process UIImage objects without saving to disk:

```swift
let image = UIImage(named: "object_photo")!

// Basic processing
let result = try await printTrace.processImage(image)

// Pipeline stage processing for UI visualization
let stageResult = try await printTrace.processImageToStage(
    image, 
    toStage: .lightboxCropped
)
```

### Real-time Pipeline Visualization

Show each processing stage in your UI:

```swift
struct ProcessingView: View {
    @StateObject private var processor = ImageProcessor()
    @State private var currentStage: PipelineStage = .loaded
    @State private var stageImage: UIImage?
    
    var body: some View {
        VStack {
            if let stageImage = stageImage {
                Image(uiImage: stageImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            Picker("Stage", selection: $currentStage) {
                ForEach(PipelineStage.allCases, id: \.self) { stage in
                    Text(stage.description).tag(stage)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: currentStage) { _ in
                Task {
                    await processToStage()
                }
            }
        }
    }
    
    private func processToStage() async {
        guard let image = UIImage(named: "test_image") else { return }
        
        do {
            let result = try await processor.printTrace.processImageToStage(
                image,
                toStage: currentStage
            )
            
            if let imageData = result.imageData {
                await MainActor.run {
                    self.stageImage = processor.printTrace.convertToUIImage(
                        imageData, 
                        width: Int(image.size.width), 
                        height: Int(image.size.height)
                    )
                }
            }
        } catch {
            print("Stage processing failed: \(error)")
        }
    }
}
```

### DXF Export to Documents

Export DXF files to the app's Documents directory:

```swift
// Export from UIImage
let dxfURL = try await printTrace.exportDXFToDocuments(
    image: image,
    fileName: "traced_object.dxf"
)

// Share the DXF file
let activityController = UIActivityViewController(
    activityItems: [dxfURL],
    applicationActivities: nil
)
present(activityController, animated: true)
```

### Parameter Ranges for UI Controls

Create proper UI sliders with parameter ranges:

```swift
struct ParameterControlsView: View {
    @State private var parameters = ProcessingParameters.default
    private let ranges = PrintTrace.getParameterRanges()
    
    var body: some View {
        Form {
            Section("Threshold Control") {
                VStack {
                    Text("Threshold Offset: \(parameters.thresholdOffset, specifier: "%.1f")")
                    Slider(
                        value: $parameters.thresholdOffset,
                        in: ranges.thresholdOffsetRange,
                        step: 1.0
                    )
                }
                
                Toggle("Use Adaptive Threshold", 
                       isOn: $parameters.useAdaptiveThreshold)
                
                if !parameters.useAdaptiveThreshold {
                    VStack {
                        Text("Manual Threshold: \(parameters.manualThreshold, specifier: "%.0f")")
                        Slider(
                            value: $parameters.manualThreshold,
                            in: ranges.manualThresholdRange,
                            step: 1.0
                        )
                    }
                }
            }
            
            Section("Detail Preservation") {
                Toggle("Disable Morphology", 
                       isOn: $parameters.disableMorphology)
                
                if !parameters.disableMorphology {
                    VStack {
                        Text("Morphology Kernel: \(parameters.morphKernelSize)")
                        Slider(
                            value: Binding(
                                get: { Double(parameters.morphKernelSize) },
                                set: { parameters.morphKernelSize = Int32($0) }
                            ),
                            in: Double(ranges.morphKernelSizeRange.lowerBound)...Double(ranges.morphKernelSizeRange.upperBound),
                            step: 2.0 // Kernel sizes are typically odd numbers
                        )
                    }
                }
            }
            
            Section("Multi-Contour Detection") {
                Toggle("Merge Nearby Contours", 
                       isOn: $parameters.mergeNearbyContours)
                
                if parameters.mergeNearbyContours {
                    VStack {
                        Text("Merge Distance: \(parameters.contourMergeDistanceMM, specifier: "%.1f") mm")
                        Slider(
                            value: $parameters.contourMergeDistanceMM,
                            in: ranges.contourMergeDistanceRange,
                            step: 0.5
                        )
                    }
                }
            }
        }
    }
}
```

## File System Considerations

### iOS App Sandbox

iOS apps run in a sandbox with restricted file access. SwiftPrintTrace handles this automatically:

- **Documents Directory**: Use `PrintTrace.documentsDirectory` for user files
- **Temporary Directory**: Use `PrintTrace.temporaryDirectory` for processing
- **Photo Library**: Import images using `UIImagePickerController` or `PhotosPicker`

### Example: Photo Processing App

```swift
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var processedImage: UIImage?
    @StateObject private var printTrace = PrintTrace()
    
    var body: some View {
        VStack {
            PhotosPicker("Select Photo", selection: $selectedPhoto)
                .onChange(of: selectedPhoto) { _ in
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await processPhoto(image)
                        }
                    }
                }
            
            if let processedImage = processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .padding()
    }
    
    private func processPhoto(_ image: UIImage) async {
        do {
            let result = try await printTrace.processImage(image)
            
            // Convert contour back to image for display
            // (Implementation depends on your visualization needs)
            
        } catch {
            print("Processing failed: \(error)")
        }
    }
}
```

## Performance Considerations

### Background Processing

Always process images on background threads:

```swift
func processImage(_ image: UIImage) {
    Task {
        do {
            let result = try await printTrace.processImage(image)
            
            await MainActor.run {
                // Update UI on main thread
                self.result = result
            }
        } catch {
            // Handle error
        }
    }
}
```

### Memory Management

- Large images are automatically compressed before processing
- Temporary files are cleaned up automatically
- Use weak references in callbacks to avoid retain cycles

### Progress Monitoring

Monitor processing progress for better UX:

```swift
class ProcessingViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var currentStage: String = ""
    
    private let printTrace = PrintTrace()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        printTrace.$progress
            .compactMap { $0 }
            .sink { progress in
                self.progress = progress.progress
                self.currentStage = progress.stage
            }
            .store(in: &cancellables)
    }
}
```

## Troubleshooting

### Common Issues

1. **XCFramework not found**: Ensure you've run the build script and the framework exists at `Frameworks/PrintTrace.xcframework`

2. **Build errors on iOS**: Check that you're targeting iOS 13.0+ and using a compatible Xcode version

3. **Memory issues**: Large images may cause memory pressure. Consider resizing images before processing:

```swift
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
```

4. **File access errors**: Ensure you're using the proper iOS directories (`documentsDirectory`, `temporaryDirectory`)

### Debug Logging

Enable debug output for troubleshooting:

```swift
var params = ProcessingParameters.default
params.enableDebugOutput = true
```

## Limitations

- **No file system access**: Can't process arbitrary file paths due to iOS sandbox
- **Processing power**: Complex images may take longer on mobile devices
- **Memory constraints**: iOS has stricter memory limits than macOS
- **Background processing**: Processing stops when app is backgrounded (use background tasks if needed)

## Next Steps

- See the example iOS app in `Examples/iOS/`
- Check out SwiftUI integration examples
- Review the parameter tuning guide for optimal mobile performance