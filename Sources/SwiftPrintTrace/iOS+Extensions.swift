import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

// MARK: - iOS-specific Extensions

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension PrintTrace {
    
    /// Process a UIImage directly on iOS
    public func processImage(
        _ image: UIImage,
        parameters: ProcessingParameters = .default
    ) async throws -> ProcessingResult {
        
        // Save UIImage to temporary file
        let tempURL = try saveImageToTemporaryFile(image)
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Process using file path
        return try await processImage(at: tempURL.path, parameters: parameters)
    }
    
    /// Process UIImage to a specific pipeline stage
    public func processImageToStage(
        _ image: UIImage,
        toStage stage: PipelineStage,
        parameters: ProcessingParameters = .default
    ) async throws -> StageProcessingResult {
        
        // Save UIImage to temporary file
        let tempURL = try saveImageToTemporaryFile(image)
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Process using file path
        return try await processImageToStage(at: tempURL.path, toStage: stage, parameters: parameters)
    }
    
    /// Convert processing result to UIImage for display
    public func convertToUIImage(_ imageData: Data, width: Int, height: Int) -> UIImage? {
        guard width > 0, height > 0 else { return nil }
        
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = width * bytesPerPixel
        
        guard imageData.count >= height * bytesPerRow else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: UnsafeMutablePointer(mutating: imageData.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress }),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Private iOS Helpers
    
    private func saveImageToTemporaryFile(_ image: UIImage) throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw PrintTraceError.imageLoadFailed("Failed to convert UIImage to JPEG data")
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        try imageData.write(to: tempURL)
        return tempURL
    }
}

// MARK: - iOS File Access Helpers

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension PrintTrace {
    
    /// Get the app's Documents directory (iOS app sandbox)
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Get a temporary directory for processing
    static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }
    
    /// Export DXF to the app's Documents directory
    func exportDXFToDocuments(
        imagePath: String,
        fileName: String = "traced_object.dxf",
        parameters: ProcessingParameters = .default
    ) async throws -> URL {
        
        let documentsURL = Self.documentsDirectory
        let outputURL = documentsURL.appendingPathComponent(fileName)
        
        try await processImageToDXF(
            imagePath: imagePath,
            outputPath: outputURL.path,
            parameters: parameters
        )
        
        return outputURL
    }
    
    /// Export DXF from UIImage to Documents directory
    func exportDXFToDocuments(
        image: UIImage,
        fileName: String = "traced_object.dxf",
        parameters: ProcessingParameters = .default
    ) async throws -> URL {
        
        // Save UIImage to temporary file
        let tempURL = try saveImageToTemporaryFile(image)
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Export DXF
        return try await exportDXFToDocuments(
            imagePath: tempURL.path,
            fileName: fileName,
            parameters: parameters
        )
    }
}

// MARK: - iOS SwiftUI Integration Helpers

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension StageProcessingResult {
    
    /// Convert the stage's image data to a SwiftUI Image
    var swiftUIImage: Image? {
        guard let imageData = self.imageData else { return nil }
        
        // For iOS, we need to know the image dimensions to convert properly
        // This is a simplified version - you might want to embed dimensions in the result
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return Image(uiImage: uiImage)
    }
}
#endif

#endif // iOS/tvOS/watchOS