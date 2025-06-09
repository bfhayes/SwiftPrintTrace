import Foundation

public enum PrintTraceError: Error, LocalizedError {
    case invalidInput(String)
    case fileNotFound(String)
    case imageLoadFailed(String)
    case imageTooSmall(String)
    case noContours(String)
    case noBoundary(String)
    case noObject(String)
    case dxfWriteFailed(String)
    case invalidParameters(String)
    case processingFailed(String)
    case cancelled
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .fileNotFound(let details):
            return "File not found: \(details)"
        case .imageLoadFailed(let details):
            return "Failed to load image: \(details)"
        case .imageTooSmall(let details):
            return "Image too small: \(details)"
        case .noContours(let details):
            return "No contours found: \(details)"
        case .noBoundary(let details):
            return "No boundary detected: \(details)"
        case .noObject(let details):
            return "No object found: \(details)"
        case .dxfWriteFailed(let details):
            return "DXF write failed: \(details)"
        case .invalidParameters(let details):
            return "Invalid parameters: \(details)"
        case .processingFailed(let details):
            return "Processing failed: \(details)"
        case .cancelled:
            return "Operation was cancelled"
        case .unknown(let details):
            return "Unknown error: \(details)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .imageLoadFailed:
            return "Check that the image file is valid and not corrupted. Supported formats: JPEG, PNG, TIFF, BMP."
        case .imageTooSmall:
            return "Use an image with at least 100x100 pixels resolution."
        case .noContours:
            return "Ensure the image has good contrast between the object and background."
        case .noBoundary:
            return "Make sure the image shows a clear rectangular boundary (lightbox or document edges)."
        case .noObject:
            return "Check image quality and ensure there's a clear object on the background."
        case .invalidParameters:
            return "Review parameter values and ensure they're within valid ranges."
        default:
            return nil
        }
    }
}
