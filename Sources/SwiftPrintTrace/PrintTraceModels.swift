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
    
    // Object detection parameters
    public var useAdaptiveThreshold: Bool = false
    public var manualThreshold: Double = 0.0 // 0 = auto
    public var thresholdOffset: Double = 0.0 // -50 to +50
    
    // Morphological processing parameters
    public var disableMorphology: Bool = false
    public var morphKernelSize: Int32 = 5 // 3-15
    
    // Multi-contour detection parameters
    public var mergeNearbyContours: Bool = true
    public var contourMergeDistanceMM: Double = 5.0 // 1-20
    
    public init() {}
    
    // Preset configurations
    public static let `default` = ProcessingParameters()
    
    public static var preserveDetail: ProcessingParameters {
        var params = ProcessingParameters()
        params.disableMorphology = true
        params.mergeNearbyContours = false
        return params
    }
    
    public static var multiContour: ProcessingParameters {
        var params = ProcessingParameters()
        params.contourMergeDistanceMM = 10.0
        params.mergeNearbyContours = true
        return params
    }
    
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

// MARK: - Parameter Range Information

public struct ParameterRanges: Sendable {
    public let warpSizeRange: ClosedRange<Int32>
    public let realWorldSizeRange: ClosedRange<Double>
    public let cannyLowerRange: ClosedRange<Double>
    public let cannyUpperRange: ClosedRange<Double>
    public let cannyApertureRange: ClosedRange<Int32>
    public let claheClipLimitRange: ClosedRange<Double>
    public let claheTileSizeRange: ClosedRange<Int32>
    public let minContourAreaRange: ClosedRange<Double>
    public let minSolidityRange: ClosedRange<Double>
    public let maxAspectRatioRange: ClosedRange<Double>
    public let polygonEpsilonFactorRange: ClosedRange<Double>
    public let cornerWinSizeRange: ClosedRange<Int32>
    public let minPerimeterRange: ClosedRange<Double>
    public let dilationAmountRange: ClosedRange<Double>
    public let smoothingAmountRange: ClosedRange<Double>
    public let manualThresholdRange: ClosedRange<Double>
    public let thresholdOffsetRange: ClosedRange<Double>
    public let morphKernelSizeRange: ClosedRange<Int32>
    public let contourMergeDistanceRange: ClosedRange<Double>
    
    internal init(
        warpSizeRange: ClosedRange<Int32>,
        realWorldSizeRange: ClosedRange<Double>,
        cannyLowerRange: ClosedRange<Double>,
        cannyUpperRange: ClosedRange<Double>,
        cannyApertureRange: ClosedRange<Int32>,
        claheClipLimitRange: ClosedRange<Double>,
        claheTileSizeRange: ClosedRange<Int32>,
        minContourAreaRange: ClosedRange<Double>,
        minSolidityRange: ClosedRange<Double>,
        maxAspectRatioRange: ClosedRange<Double>,
        polygonEpsilonFactorRange: ClosedRange<Double>,
        cornerWinSizeRange: ClosedRange<Int32>,
        minPerimeterRange: ClosedRange<Double>,
        dilationAmountRange: ClosedRange<Double>,
        smoothingAmountRange: ClosedRange<Double>,
        manualThresholdRange: ClosedRange<Double>,
        thresholdOffsetRange: ClosedRange<Double>,
        morphKernelSizeRange: ClosedRange<Int32>,
        contourMergeDistanceRange: ClosedRange<Double>
    ) {
        self.warpSizeRange = warpSizeRange
        self.realWorldSizeRange = realWorldSizeRange
        self.cannyLowerRange = cannyLowerRange
        self.cannyUpperRange = cannyUpperRange
        self.cannyApertureRange = cannyApertureRange
        self.claheClipLimitRange = claheClipLimitRange
        self.claheTileSizeRange = claheTileSizeRange
        self.minContourAreaRange = minContourAreaRange
        self.minSolidityRange = minSolidityRange
        self.maxAspectRatioRange = maxAspectRatioRange
        self.polygonEpsilonFactorRange = polygonEpsilonFactorRange
        self.cornerWinSizeRange = cornerWinSizeRange
        self.minPerimeterRange = minPerimeterRange
        self.dilationAmountRange = dilationAmountRange
        self.smoothingAmountRange = smoothingAmountRange
        self.manualThresholdRange = manualThresholdRange
        self.thresholdOffsetRange = thresholdOffsetRange
        self.morphKernelSizeRange = morphKernelSizeRange
        self.contourMergeDistanceRange = contourMergeDistanceRange
    }
}

// MARK: - Pipeline Stage

public enum PipelineStage: Int32, CaseIterable, Sendable {
    case loaded = 0
    case lightboxCropped = 1
    case normalized = 2
    case boundaryDetected = 3
    case objectDetected = 4
    case smoothed = 5
    case dilated = 6
    case final = 7
    
    public var description: String {
        switch self {
        case .loaded: return "Image Loaded"
        case .lightboxCropped: return "Lightbox Cropped"
        case .normalized: return "Normalized"
        case .boundaryDetected: return "Boundary Detected"
        case .objectDetected: return "Object Detected"
        case .smoothed: return "Smoothed"
        case .dilated: return "Dilated"
        case .final: return "Final Result"
        }
    }
}

// MARK: - Stage Processing Result

public struct StageProcessingResult: Sendable {
    public let stage: PipelineStage
    public let imageData: Data?
    public let contour: ProcessedContour?
    public let processingTime: TimeInterval
    public let parameters: ProcessingParameters
    
    public init(
        stage: PipelineStage,
        imageData: Data?,
        contour: ProcessedContour?,
        processingTime: TimeInterval,
        parameters: ProcessingParameters
    ) {
        self.stage = stage
        self.imageData = imageData
        self.contour = contour
        self.processingTime = processingTime
        self.parameters = parameters
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
