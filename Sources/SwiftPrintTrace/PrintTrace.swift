import Foundation
import CPrintTrace
import Combine

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
@MainActor
public final class PrintTrace: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var progress: ProcessingProgress?
    @Published public private(set) var lastError: PrintTraceError?
    
    // MARK: - Private Properties
    
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init() {}
    
    deinit {
        currentTask?.cancel()
    }
    
    // MARK: - Static Utility Methods
    
    nonisolated public static func validateParameters(_ params: ProcessingParameters) throws {
        var cParams = params.toCStruct()
        let result = print_trace_validate_params(&cParams)
        
        if result != PRINT_TRACE_SUCCESS {
            let message = String(cString: print_trace_get_error_message(result))
            throw convertError(result, message: message)
        }
    }
    
    nonisolated public static func isValidImageFile(at path: String) -> Bool {
        return path.withCString { cPath in
            return print_trace_is_valid_image_file(cPath)
        }
    }
    
    nonisolated public static func estimateProcessingTime(for imagePath: String) -> TimeInterval? {
        let time = imagePath.withCString { cPath in
            return print_trace_estimate_processing_time(cPath)
        }
        return time > 0 ? time : nil
    }
    
    nonisolated public static var version: String {
        return String(cString: print_trace_get_version())
    }
    
    nonisolated public static func getParameterRanges() -> ParameterRanges {
        var cRanges = PrintTraceParamRanges()
        print_trace_get_param_ranges(&cRanges)
        
        return ParameterRanges(
            warpSizeRange: cRanges.warp_size_min...cRanges.warp_size_max,
            realWorldSizeRange: cRanges.real_world_size_mm_min...cRanges.real_world_size_mm_max,
            cannyLowerRange: cRanges.canny_lower_min...cRanges.canny_lower_max,
            cannyUpperRange: cRanges.canny_upper_min...cRanges.canny_upper_max,
            cannyApertureRange: 3...7, // Based on canny_aperture_values array
            claheClipLimitRange: cRanges.clahe_clip_limit_min...cRanges.clahe_clip_limit_max,
            claheTileSizeRange: cRanges.clahe_tile_size_min...cRanges.clahe_tile_size_max,
            minContourAreaRange: cRanges.min_contour_area_min...cRanges.min_contour_area_max,
            minSolidityRange: cRanges.min_solidity_min...cRanges.min_solidity_max,
            maxAspectRatioRange: cRanges.max_aspect_ratio_min...cRanges.max_aspect_ratio_max,
            polygonEpsilonFactorRange: cRanges.polygon_epsilon_factor_min...cRanges.polygon_epsilon_factor_max,
            cornerWinSizeRange: cRanges.corner_win_size_min...cRanges.corner_win_size_max,
            minPerimeterRange: cRanges.min_perimeter_min...cRanges.min_perimeter_max,
            dilationAmountRange: cRanges.dilation_amount_mm_min...cRanges.dilation_amount_mm_max,
            smoothingAmountRange: cRanges.smoothing_amount_mm_min...cRanges.smoothing_amount_mm_max,
            manualThresholdRange: cRanges.manual_threshold_min...cRanges.manual_threshold_max,
            thresholdOffsetRange: cRanges.threshold_offset_min...cRanges.threshold_offset_max,
            morphKernelSizeRange: cRanges.morph_kernel_size_min...cRanges.morph_kernel_size_max,
            contourMergeDistanceRange: cRanges.contour_merge_distance_mm_min...cRanges.contour_merge_distance_mm_max
        )
    }
    
    // MARK: - Main Processing Methods
    
    public func processImage(
        at imagePath: String,
        parameters: ProcessingParameters = .default
    ) async throws -> ProcessingResult {
        
        // Ensure we're not already processing
        guard !isProcessing else {
            throw PrintTraceError.processingFailed("Already processing another image")
        }
        
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
            progress = nil
        }
        
        let startTime = Date()
        
        do {
            let contour = try await processImageToContour(imagePath: imagePath, parameters: parameters)
            let processingTime = Date().timeIntervalSince(startTime)
            
            return ProcessingResult(
                contour: contour,
                processingTime: processingTime,
                parameters: parameters
            )
        } catch {
            lastError = error as? PrintTraceError ?? PrintTraceError.unknown(error.localizedDescription)
            throw error
        }
    }
    
    
    public func processImageToDXF(
        imagePath: String,
        outputPath: String,
        parameters: ProcessingParameters = .default
    ) async throws {
        
        guard !isProcessing else {
            throw PrintTraceError.processingFailed("Already processing another image")
        }
        
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
            progress = nil
        }
        
        try await processImageToDXFInternal(
            imagePath: imagePath,
            outputPath: outputPath,
            parameters: parameters
        )
    }
    
    public func processImageToStage(
        at imagePath: String,
        toStage stage: PipelineStage,
        parameters: ProcessingParameters = .default
    ) async throws -> StageProcessingResult {
        
        guard !isProcessing else {
            throw PrintTraceError.processingFailed("Already processing another image")
        }
        
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
            progress = nil
        }
        
        let startTime = Date()
        
        do {
            let (imageData, contour) = try await processImageToStageInternal(
                imagePath: imagePath,
                stage: stage,
                parameters: parameters
            )
            let processingTime = Date().timeIntervalSince(startTime)
            
            return StageProcessingResult(
                stage: stage,
                imageData: imageData,
                contour: contour,
                processingTime: processingTime,
                parameters: parameters
            )
        } catch {
            lastError = error as? PrintTraceError ?? PrintTraceError.unknown(error.localizedDescription)
            throw error
        }
    }
    
    public func cancel() {
        currentTask?.cancel()
    }
    
    // MARK: - Internal Implementation
    
    private func processImageToContour(
        imagePath: String,
        parameters: ProcessingParameters
    ) async throws -> ProcessedContour {
        
        return try await withCheckedThrowingContinuation { continuation in
            currentTask = Task {
                var cParams = parameters.toCStruct()
                var contour = PrintTraceContour(points: nil, point_count: 0, pixels_per_mm: 0.0)
                
                // Create a context object to pass through callbacks
                let context = CallbackContext(printTrace: self)
                let contextPtr = Unmanaged.passRetained(context).toOpaque()
                
                // Progress callback with user_data
                let progressCallback: PrintTraceProgressCallback = { progress, stage, userData in
                    guard let userData = userData,
                          let stage = stage else { return }
                    
                    let context = Unmanaged<CallbackContext>.fromOpaque(userData).takeUnretainedValue()
                    let stageString = String(cString: stage)
                    
                    Task { @MainActor in
                        context.printTrace?.progress = ProcessingProgress(
                            progress: progress,
                            stage: stageString
                        )
                    }
                }
                
                let errorCallback: PrintTraceErrorCallback = { errorCode, message, userData in
                    // Error details are handled in the main result check
                }
                
                defer {
                    // Clean up the context
                    Unmanaged<CallbackContext>.fromOpaque(contextPtr).release()
                }
                
                let result = imagePath.withCString { cImagePath in
                    return print_trace_process_image_to_contour(
                        cImagePath,
                        &cParams,
                        &contour,
                        progressCallback,
                        errorCallback,
                        contextPtr
                    )
                }
                
                if result == PRINT_TRACE_SUCCESS {
                    do {
                        let swiftContour = try convertContour(contour)
                        print_trace_free_contour(&contour)
                        continuation.resume(returning: swiftContour)
                    } catch {
                        print_trace_free_contour(&contour)
                        continuation.resume(throwing: error)
                    }
                } else {
                    print_trace_free_contour(&contour)
                    let message = String(cString: print_trace_get_error_message(result))
                    let error = convertError(result, message: message)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processImageToDXFInternal(
        imagePath: String,
        outputPath: String,
        parameters: ProcessingParameters
    ) async throws {
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentTask = Task {
                var cParams = parameters.toCStruct()
                
                // Create a context object to pass through callbacks
                let context = CallbackContext(printTrace: self)
                let contextPtr = Unmanaged.passRetained(context).toOpaque()
                
                // Progress callback with user_data
                let progressCallback: PrintTraceProgressCallback = { progress, stage, userData in
                    guard let userData = userData,
                          let stage = stage else { return }
                    
                    let context = Unmanaged<CallbackContext>.fromOpaque(userData).takeUnretainedValue()
                    let stageString = String(cString: stage)
                    
                    Task { @MainActor in
                        context.printTrace?.progress = ProcessingProgress(
                            progress: progress,
                            stage: stageString
                        )
                    }
                }
                
                let errorCallback: PrintTraceErrorCallback = { errorCode, message, userData in
                    // Error details are handled in the main result check
                }
                
                defer {
                    // Clean up the context
                    Unmanaged<CallbackContext>.fromOpaque(contextPtr).release()
                }
                
                let result = imagePath.withCString { cImagePath in
                    return outputPath.withCString { cOutputPath in
                        return print_trace_process_image_to_dxf(
                            cImagePath,
                            cOutputPath,
                            &cParams,
                            progressCallback,
                            errorCallback,
                            contextPtr
                        )
                    }
                }
                
                if result == PRINT_TRACE_SUCCESS {
                    continuation.resume()
                } else {
                    let message = String(cString: print_trace_get_error_message(result))
                    let error = convertError(result, message: message)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processImageToStageInternal(
        imagePath: String,
        stage: PipelineStage,
        parameters: ProcessingParameters
    ) async throws -> (Data?, ProcessedContour?) {
        
        return try await withCheckedThrowingContinuation { continuation in
            currentTask = Task {
                var cParams = parameters.toCStruct()
                var imageData = PrintTraceImageData()
                var contour = PrintTraceContour(points: nil, point_count: 0, pixels_per_mm: 0.0)
                
                let context = CallbackContext(printTrace: self)
                let contextPtr = Unmanaged.passRetained(context).toOpaque()
                
                let progressCallback: PrintTraceProgressCallback = { progress, stage, userData in
                    guard let userData = userData,
                          let stage = stage else { return }
                    
                    let context = Unmanaged<CallbackContext>.fromOpaque(userData).takeUnretainedValue()
                    let stageString = String(cString: stage)
                    
                    Task { @MainActor in
                        context.printTrace?.progress = ProcessingProgress(
                            progress: progress,
                            stage: stageString
                        )
                    }
                }
                
                let errorCallback: PrintTraceErrorCallback = { errorCode, message, userData in
                    // Error details are handled in the main result check
                }
                
                defer {
                    Unmanaged<CallbackContext>.fromOpaque(contextPtr).release()
                    print_trace_free_contour(&contour)
                    print_trace_free_image_data(&imageData)
                }
                
                let result = imagePath.withCString { cImagePath in
                    return print_trace_process_to_stage(
                        cImagePath,
                        &cParams,
                        PrintTraceProcessingStage(UInt32(stage.rawValue)),
                        &imageData,
                        &contour,
                        progressCallback,
                        errorCallback,
                        contextPtr
                    )
                }
                
                if result == PRINT_TRACE_SUCCESS {
                    do {
                        // Convert image data
                        var swiftImageData: Data?
                        if imageData.width > 0 && imageData.height > 0, let dataPtr = imageData.data {
                            let dataSize = Int(imageData.bytes_per_row * imageData.height)
                            swiftImageData = Data(bytes: dataPtr, count: dataSize)
                        }
                        
                        // Convert contour if available
                        var swiftContour: ProcessedContour?
                        if contour.point_count > 0 {
                            swiftContour = try convertContour(contour)
                        }
                        
                        continuation.resume(returning: (swiftImageData, swiftContour))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    let message = String(cString: print_trace_get_error_message(result))
                    let error = convertError(result, message: message)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}

// MARK: - Callback Context

private final class CallbackContext {
    weak var printTrace: PrintTrace?
    
    init(printTrace: PrintTrace) {
        self.printTrace = printTrace
    }
}

// MARK: - Private Extensions

private extension ProcessingParameters {
    func toCStruct() -> PrintTraceParams {
        return PrintTraceParams(
            warp_size: warpSize,
            real_world_size_mm: realWorldSizeMM,
            canny_lower: cannyLower,
            canny_upper: cannyUpper,
            canny_aperture: cannyAperture,
            clahe_clip_limit: claheClipLimit,
            clahe_tile_size: claheTileSize,
            use_adaptive_threshold: useAdaptiveThreshold,
            manual_threshold: manualThreshold,
            threshold_offset: thresholdOffset,
            disable_morphology: disableMorphology,
            morph_kernel_size: morphKernelSize,
            merge_nearby_contours: mergeNearbyContours,
            contour_merge_distance_mm: contourMergeDistanceMM,
            min_contour_area: minContourArea,
            min_solidity: minSolidity,
            max_aspect_ratio: maxAspectRatio,
            polygon_epsilon_factor: polygonEpsilonFactor,
            enable_subpixel_refinement: enableSubPixelRefinement,
            corner_win_size: cornerWinSize,
            validate_closed_contour: validateClosedContour,
            min_perimeter: minPerimeter,
            dilation_amount_mm: dilationAmountMM,
            enable_smoothing: enableSmoothing,
            smoothing_amount_mm: smoothingAmountMM,
            enable_debug_output: enableDebugOutput
        )
    }
}

nonisolated private func convertContour(_ cContour: PrintTraceContour) throws -> ProcessedContour {
    guard cContour.point_count > 0, let points = cContour.points else {
        throw PrintTraceError.noContours("Empty contour returned from processing")
    }
    
    let swiftPoints = (0..<cContour.point_count).map { i in
        ContourPoint(x: points[Int(i)].x, y: points[Int(i)].y)
    }
    
    return ProcessedContour(points: swiftPoints, pixelsPerMM: cContour.pixels_per_mm)
}


nonisolated private func convertError(_ result: PrintTraceResult, message: String) -> PrintTraceError {
    switch result {
    case PRINT_TRACE_ERROR_INVALID_INPUT:
        return .invalidInput(message)
    case PRINT_TRACE_ERROR_FILE_NOT_FOUND:
        return .fileNotFound(message)
    case PRINT_TRACE_ERROR_IMAGE_LOAD_FAILED:
        return .imageLoadFailed(message)
    case PRINT_TRACE_ERROR_IMAGE_TOO_SMALL:
        return .imageTooSmall(message)
    case PRINT_TRACE_ERROR_NO_CONTOURS:
        return .noContours(message)
    case PRINT_TRACE_ERROR_NO_BOUNDARY:
        return .noBoundary(message)
    case PRINT_TRACE_ERROR_NO_OBJECT:
        return .noObject(message)
    case PRINT_TRACE_ERROR_DXF_WRITE_FAILED:
        return .dxfWriteFailed(message)
    case PRINT_TRACE_ERROR_INVALID_PARAMETERS:
        return .invalidParameters(message)
    case PRINT_TRACE_ERROR_PROCESSING_FAILED:
        return .processingFailed(message)
    default:
        return .unknown(message)
    }
}
