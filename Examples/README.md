# SwiftPrintTrace Examples

This directory contains example SwiftUI views demonstrating how to use the SwiftPrintTrace library.

## Progress Example

`ProgressExample.swift` demonstrates:
- Real-time progress updates during image processing
- Async/await processing with proper error handling
- SwiftUI integration with @Published properties
- Display of processing results and metrics

### Key Features Shown

1. **Progress Callbacks**: Watch real-time progress updates as the image is processed
2. **Error Handling**: Comprehensive error display with recovery suggestions  
3. **Results Display**: Show processing time, contour points, area, and perimeter
4. **SwiftUI Integration**: Clean reactive UI using @StateObject and @Published

### Usage

```swift
import SwiftUI
import SwiftPrintTrace

struct ContentView: View {
    var body: some View {
        ProgressExample()
    }
}
```

The progress callbacks now work thanks to the updated PrintTrace C API that includes `user_data` parameters, allowing the Swift wrapper to capture instance context and update UI in real-time.