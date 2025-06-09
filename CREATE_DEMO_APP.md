# Creating a SwiftPrintTrace Demo App

## Quick Setup

### 1. Create new iOS/macOS app in Xcode
```bash
# Create new directory
mkdir SwiftPrintTraceDemo
cd SwiftPrintTraceDemo

# Open Xcode and create new App project
# Choose SwiftUI, name: "SwiftPrintTraceDemo"
```

### 2. Add SwiftPrintTrace as dependency

In Xcode:
- File → Add Package Dependencies
- Enter local path: `file:///path/to/SwiftPrintTrace`
- Or GitHub URL when published

### 3. Replace ContentView.swift

```swift
import SwiftUI
import SwiftPrintTrace

struct ContentView: View {
    @StateObject private var printTrace = PrintTrace()
    @State private var selectedImageURL: URL?
    @State private var result: ProcessingResult?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Text("PrintTrace Demo")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("CAD-Optimized Image Processing")
                        .font(.subtitle)
                        .foregroundColor(.secondary)
                }
                
                // Image selection
                Button("Select Image") {
                    showingImagePicker = true
                }
                .buttonStyle(.borderedProminent)
                
                if let url = selectedImageURL {
                    Text("Selected: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Processing controls
                HStack {
                    ForEach([
                        ("Fast", ProcessingParameters.fastProcessing),
                        ("Default", ProcessingParameters.default),
                        ("Precision", ProcessingParameters.highPrecision)
                    ], id: \.0) { name, params in
                        Button(name) {
                            processImage(with: params)
                        }
                        .disabled(selectedImageURL == nil || printTrace.isProcessing)
                        .buttonStyle(.bordered)
                    }
                }
                
                // Progress
                if let progress = printTrace.progress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(progress.stage)
                            Spacer()
                            Text("\(Int(progress.progress * 100))%")
                        }
                        .font(.caption)
                        
                        ProgressView(value: progress.progress)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                
                // Results
                if let result = result {
                    ResultView(result: result)
                }
                
                // Error
                if let error = printTrace.lastError {
                    ErrorView(error: error)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("PrintTrace")
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                selectedImageURL = urls.first
            case .failure(let error):
                print("File selection failed: \(error)")
            }
        }
    }
    
    private func processImage(with parameters: ProcessingParameters) {
        guard let url = selectedImageURL else { return }
        
        Task {
            do {
                let processingResult = try await printTrace.processImage(
                    at: url.path,
                    parameters: parameters
                )
                
                await MainActor.run {
                    self.result = processingResult
                }
            } catch {
                print("Processing failed: \(error)")
            }
        }
    }
}

struct ResultView: View {
    let result: ProcessingResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Results", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Time:")
                    Text("\(result.processingTime, specifier: "%.2f")s")
                }
                GridRow {
                    Text("Points:")
                    Text("\(result.contour.pointCount)")
                }
                GridRow {
                    Text("Area:")
                    Text("\(result.contour.area, specifier: "%.1f") mm²")
                }
                GridRow {
                    Text("Perimeter:")
                    Text("\(result.contour.perimeter, specifier: "%.1f") mm")
                }
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ErrorView: View {
    let error: PrintTraceError
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .font(.body)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
```

### 4. Test Integration

This gives you:
- ✅ Real file picker integration  
- ✅ Live progress updates
- ✅ Multiple parameter testing
- ✅ Error handling UI
- ✅ Results visualization
- ✅ Native iOS/macOS experience

### 5. Advanced Features to Add

```swift
// Add these features incrementally:

// 1. Image preview
AsyncImage(url: selectedImageURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
} placeholder: {
    RoundedRectangle(cornerRadius: 8)
        .fill(Color.gray.opacity(0.3))
}
.frame(height: 200)

// 2. Contour visualization overlay
// 3. DXF export button
// 4. Parameter adjustment sliders
// 5. Processing history
// 6. Share sheet for results
```

This approach gives you the best of both worlds - a real app for testing while keeping your package focused and clean.