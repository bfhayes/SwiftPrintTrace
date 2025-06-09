import Foundation
import CoreGraphics

// MARK: - Processing Parameters

public struct ProcessingParameters: Sendable {
    // Core parameters
    public var warpSize: Int32 = 3240
    public var realWorldSizeMM: Double = 162.0
    
    // Edge detection (CAD-optimized)
    public var cannyLower: Double = 50.0
    public var cannyUpper: Double = 150.0
    public var cannyAperture: Int32 = 3
    
    // Lighting normalization
    public var claheClipLimit: Double = 2.0
    public var claheTileSize: Int32 = 8
    
    // Contour filtering
    public var minContourArea: Double = 500.0
    public var minSolidity: Double = 0.3
    public var maxAspectRatio: Double = 20.0
    
    // Polygon approximation (high precision for CAD)
    public var polygonEpsilonFactor: Double = 0.005
    
    // Sub-pixel refinement
    public var enableSubPixelRefinement: Bool = true
    public var cornerWinSize: Int32 = 5
    
    // Validation
    public var validateClosedContour: Bool = true
    public var minPerimeter: Double = 100.0
    
    // 3D printing specific
    public var dilationAmountMM: Double = 0.0
    public var enableSmoothing: Bool = false
    public var smoothingAmountMM: Double = 0.2
    
    // Debug output
    public var enableDebugOutput: Bool = false
    
    public init() {}
    
    // Preset configurations
    public static let `default` = ProcessingParameters()
    
    public static var highPrecision: ProcessingParameters {
        var params = ProcessingParameters()
        params.polygonEpsilonFactor = 0.002
        params.enableSubPixelRefinement = true
        return params
    }
    
    public static var printing3D: ProcessingParameters {
        var params = ProcessingParameters()
        params.enableSmoothing = true
        params.smoothingAmountMM = 0.3
        params.dilationAmountMM = 0.1
        return params
    }
    
    public static var fastProcessing: ProcessingParameters {
        var params = ProcessingParameters()
        params.warpSize = 1620
        params.polygonEpsilonFactor = 0.01
        params.enableSubPixelRefinement = false
        return params
    }
}

// MARK: - Processing Progress

public struct ProcessingProgress: Sendable {
    public let progress: Double // 0.0 to 1.0
    public let stage: String
    public let estimatedTimeRemaining: TimeInterval?
    
    public init(progress: Double, stage: String, estimatedTimeRemaining: TimeInterval? = nil) {
        self.progress = progress
        self.stage = stage
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

// MARK: - Contour Data

public struct ContourPoint: Sendable {
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct ProcessedContour: Sendable {
    public let points: [ContourPoint]
    public let pixelsPerMM: Double
    public let boundingRect: CGRect
    public let area: Double // in square millimeters
    public let perimeter: Double // in millimeters
    
    public var pointCount: Int { points.count }
    
    internal init(points: [ContourPoint], pixelsPerMM: Double) {
        self.points = points
        self.pixelsPerMM = pixelsPerMM
        
        guard !points.isEmpty else {
            self.boundingRect = CGRect(x: 0, y: 0, width: 0, height: 0)
            self.area = 0
            self.perimeter = 0
            return
        }
        
        // Calculate bounding rectangle
        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!
        
        self.boundingRect = CGRect(
            origin: CGPoint(x: minX / pixelsPerMM, y: minY / pixelsPerMM),
            size: CGSize(width: (maxX - minX) / pixelsPerMM, height: (maxY - minY) / pixelsPerMM)
        )
        
        // Calculate area using shoelace formula (converted to mm²)
        var area = 0.0
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            area += points[i].x * points[j].y
            area -= points[j].x * points[i].y
        }
        self.area = abs(area) / (2.0 * pixelsPerMM * pixelsPerMM)
        
        // Calculate perimeter in millimeters
        var perimeter = 0.0
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            let dx = points[j].x - points[i].x
            let dy = points[j].y - points[i].y
            perimeter += sqrt(dx * dx + dy * dy)
        }
        self.perimeter = perimeter / pixelsPerMM
    }
}

// MARK: - Processing Result

public struct ProcessingResult: Sendable {
    public let contour: ProcessedContour
    public let processingTime: TimeInterval
    public let parameters: ProcessingParameters
    
    public init(contour: ProcessedContour, processingTime: TimeInterval, parameters: ProcessingParameters) {
        self.contour = contour
        self.processingTime = processingTime
        self.parameters = parameters
    }
}
