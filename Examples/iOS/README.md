# iOS Example App

This directory contains example code for integrating SwiftPrintTrace into iOS applications.

## Setup

1. Create a new iOS app in Xcode
2. Add SwiftPrintTrace as a package dependency
3. Build the XCFramework using the provided script
4. Copy the example code below into your app

## Basic Integration Example

```swift
// ContentView.swift
import SwiftUI
import SwiftPrintTrace
import PhotosUI

struct ContentView: View {
    @StateObject private var processor = ImageProcessor()
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                PhotosPicker("Select Photo to Process", selection: $selectedPhoto)
                    .buttonStyle(.borderedProminent)
                    .onChange(of: selectedPhoto) { _ in
                        Task {
                            await processor.loadPhoto(selectedPhoto)
                        }
                    }
                
                if processor.isProcessing {
                    ProgressView("Processing...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if let result = processor.result {
                    VStack {
                        Text("Processing Complete!")
                            .font(.headline)
                        
                        Text("Contour Points: \(result.contour.pointCount)")
                        Text("Area: \(result.contour.area, specifier: "%.1f") mm²")
                        Text("Processing Time: \(result.processingTime, specifier: "%.2f")s")
                        
                        Button("Export DXF") {
                            Task {
                                await processor.exportDXF()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("PrintTrace iOS")
        }
    }
}

// ImageProcessor.swift
import SwiftPrintTrace
import PhotosUI
import UIKit

@MainActor
class ImageProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var result: ProcessingResult?
    @Published var currentImage: UIImage?
    
    private let printTrace = PrintTrace()
    
    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }
            
            currentImage = image
            await processImage(image)
            
        } catch {
            print("Failed to load photo: \(error)")
        }
    }
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await printTrace.processImage(image)
            self.result = result
        } catch {
            print("Processing failed: \(error)")
        }
    }
    
    func exportDXF() async {
        guard let image = currentImage else { return }
        
        do {
            let url = try await printTrace.exportDXFToDocuments(
                image: image,
                fileName: "traced_\(Date().timeIntervalSince1970).dxf"
            )
            
            // Share the DXF file
            let activityController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityController, animated: true)
            }
            
        } catch {
            print("Export failed: \(error)")
        }
    }
}
```

## Advanced Features Example

```swift
// AdvancedProcessingView.swift
import SwiftUI
import SwiftPrintTrace

struct AdvancedProcessingView: View {
    @StateObject private var processor = AdvancedProcessor()
    @State private var parameters = ProcessingParameters.default
    
    var body: some View {
        NavigationView {
            Form {
                Section("Processing Parameters") {
                    ParameterControlsView(parameters: $parameters)
                }
                
                Section("Pipeline Stages") {
                    PipelineStageView(processor: processor, parameters: parameters)
                }
                
                Section("Results") {
                    if let result = processor.result {
                        ResultsView(result: result)
                    }
                }
            }
            .navigationTitle("Advanced Processing")
        }
    }
}

struct ParameterControlsView: View {
    @Binding var parameters: ProcessingParameters
    private let ranges = PrintTrace.getParameterRanges()
    
    var body: some View {
        VStack {
            HStack {
                Text("Threshold Offset")
                Spacer()
                Text("\(parameters.thresholdOffset, specifier: "%.0f")")
            }
            Slider(
                value: $parameters.thresholdOffset,
                in: ranges.thresholdOffsetRange,
                step: 1.0
            )
            
            Toggle("Disable Morphology", isOn: $parameters.disableMorphology)
            Toggle("Merge Contours", isOn: $parameters.mergeNearbyContours)
            
            if parameters.mergeNearbyContours {
                HStack {
                    Text("Merge Distance")
                    Spacer()
                    Text("\(parameters.contourMergeDistanceMM, specifier: "%.1f") mm")
                }
                Slider(
                    value: $parameters.contourMergeDistanceMM,
                    in: ranges.contourMergeDistanceRange,
                    step: 0.5
                )
            }
        }
    }
}
```

For complete examples, see the full iOS project files in this directory.