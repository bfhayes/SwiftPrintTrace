import Foundation
import SwiftPrintTrace

@available(macOS 10.15, *)
@main
struct PrintTraceExample {
    static func main() async {
        print("🔧 SwiftPrintTrace CLI Example")
        print("=============================")
        
        let args = CommandLine.arguments
        guard args.count >= 2 else {
            print("Usage: swift run SwiftPrintTraceExample <image_path> [output.dxf]")
            print("Example: swift run SwiftPrintTraceExample image.jpg output.dxf")
            return
        }
        
        let imagePath = args[1]
        let outputPath = args.count >= 3 ? args[2] : nil
        
        // Validate input
        guard PrintTrace.isValidImageFile(at: imagePath) else {
            print("❌ Invalid or missing image file: \(imagePath)")
            return
        }
        
        print("📷 Processing image: \(imagePath)")
        print("🔧 PrintTrace version: \(PrintTrace.version)")
        
        // Estimate processing time
        if let estimatedTime = PrintTrace.estimateProcessingTime(for: imagePath) {
            print("⏱️  Estimated processing time: \(String(format: "%.1f", estimatedTime))s")
        }
        
        let printTrace = PrintTrace()
        
        do {
            // Process image to contour
            print("\n🚀 Starting image processing...")
            let result = try await printTrace.processImage(
                at: imagePath,
                parameters: .default
            )
            
            print("✅ Processing completed!")
            print("📊 Results:")
            print("   • Processing time: \(String(format: "%.2f", result.processingTime))s")
            print("   • Contour points: \(result.contour.pointCount)")
            print("   • Area: \(String(format: "%.1f", result.contour.area)) mm²")
            print("   • Perimeter: \(String(format: "%.1f", result.contour.perimeter)) mm")
            print("   • Bounding box: \(String(format: "%.1f×%.1f", result.contour.boundingRect.width, result.contour.boundingRect.height)) mm")
            
            // Export to DXF if requested
            if let outputPath = outputPath {
                print("\n📄 Exporting to DXF: \(outputPath)")
                try await printTrace.processImageToDXF(
                    imagePath: imagePath,
                    outputPath: outputPath,
                    parameters: .default
                )
                
                let fileSize = try FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? Int64 ?? 0
                print("✅ DXF exported successfully!")
                print("   • File size: \(fileSize) bytes")
                print("   • Path: \(outputPath)")
            }
            
        } catch {
            print("❌ Processing failed: \(error)")
            if let printTraceError = error as? PrintTraceError {
                if let suggestion = printTraceError.recoverySuggestion {
                    print("💡 Suggestion: \(suggestion)")
                }
            }
        }
        
        print("\n🎉 Example completed!")
    }
}