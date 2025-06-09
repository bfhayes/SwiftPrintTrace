import SwiftPrintTrace
import SwiftUI

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
struct ProgressExample: View {
    @StateObject private var printTrace = PrintTrace()
    @State private var imagePath = "/path/to/your/image.jpg"
    @State private var result: ProcessingResult?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PrintTrace Progress Example")
                .font(.title)
                .bold()
            
            // Image path input
            TextField("Image Path", text: $imagePath)
                .textFieldStyle(.roundedBorder)
            
            // Process button
            Button("Process Image") {
                processImage()
            }
            .disabled(printTrace.isProcessing)
            .buttonStyle(.borderedProminent)
            
            // Progress display
            if let progress = printTrace.progress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Stage: \(progress.stage)")
                        Spacer()
                        Text("\(Int(progress.progress * 100))%")
                    }
                    .font(.caption)
                    
                    ProgressView(value: progress.progress)
                        .progressViewStyle(.linear)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Results display
            if let result = result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Processing Complete!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    HStack {
                        Text("Processing Time:")
                        Spacer()
                        Text("\(result.processingTime, specifier: "%.2f")s")
                    }
                    
                    HStack {
                        Text("Contour Points:")
                        Spacer()
                        Text("\(result.contour.pointCount)")
                    }
                    
                    HStack {
                        Text("Area:")
                        Spacer()
                        Text("\(result.contour.area, specifier: "%.1f") mm²")
                    }
                    
                    HStack {
                        Text("Perimeter:")
                        Spacer()
                        Text("\(result.contour.perimeter, specifier: "%.1f") mm")
                    }
                }
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Error display
            if let error = printTrace.lastError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error")
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
            
            Spacer()
        }
        .padding()
    }
    
    private func processImage() {
        Task {
            do {
                // This will now show progress updates in real-time!
                let processingResult = try await printTrace.processImage(
                    at: imagePath,
                    parameters: .highPrecision
                )
                
                await MainActor.run {
                    self.result = processingResult
                }
            } catch {
                // Error is automatically published via @Published lastError
                print("Processing failed: \(error)")
            }
        }
    }
}

// MARK: - Preview

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
struct ProgressExample_Previews: PreviewProvider {
    static var previews: some View {
        ProgressExample()
    }
}