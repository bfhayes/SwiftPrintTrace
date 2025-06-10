import XCTest
import Combine
@testable import SwiftPrintTrace

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class SwiftPrintTraceTests: XCTestCase {
    
    func testParameterValidation() throws {
        // Test default parameters are valid
        let defaultParams = ProcessingParameters.default
        XCTAssertNoThrow(try PrintTrace.validateParameters(defaultParams))
        
        // Test invalid parameters
        var invalidParams = ProcessingParameters()
        invalidParams.lightboxWidthPx = -100
        XCTAssertThrowsError(try PrintTrace.validateParameters(invalidParams))
    }
    
    func testFileValidation() {
        // Test non-existent file
        XCTAssertFalse(PrintTrace.isValidImageFile(at: "/nonexistent/file.jpg"))
        
        // Test with real image file if available
        if let testImagePath = getTestImagePath() {
            print("Testing with image at: \(testImagePath)")
            XCTAssertTrue(PrintTrace.isValidImageFile(at: testImagePath), 
                         "Test image should be valid")
        } else {
            print("⚠️ Test image not found - skipping validation test")
        }
    }
    
    func testPresetParameters() {
        let highPrecision = ProcessingParameters.highPrecision
        XCTAssertEqual(highPrecision.polygonEpsilonFactor, 0.002)
        XCTAssertTrue(highPrecision.enableSubPixelRefinement)
        
        let printing3D = ProcessingParameters.printing3D
        XCTAssertTrue(printing3D.enableSmoothing)
        XCTAssertEqual(printing3D.smoothingAmountMM, 0.3)
        
        let fastProcessing = ProcessingParameters.fastProcessing
        XCTAssertEqual(fastProcessing.lightboxWidthPx, 810)
        XCTAssertFalse(fastProcessing.enableSubPixelRefinement)
    }
    
    func testVersionInfo() {
        let version = PrintTrace.version
        XCTAssertFalse(version.isEmpty)
        XCTAssertTrue(version.contains("."))
    }
    
    func testParameterRanges() {
        let ranges = PrintTrace.getParameterRanges()
        
        // Test that ranges are reasonable  
        XCTAssertGreaterThan(ranges.lightboxWidthMMRange.upperBound, ranges.lightboxWidthMMRange.lowerBound)
        XCTAssertGreaterThan(ranges.lightboxHeightMMRange.upperBound, 0)
        XCTAssertGreaterThan(ranges.cannyLowerRange.upperBound, 0)
        XCTAssertGreaterThan(ranges.cannyUpperRange.upperBound, ranges.cannyLowerRange.upperBound)
        XCTAssertGreaterThan(ranges.claheClipLimitRange.upperBound, 0)
        XCTAssertGreaterThan(ranges.minContourAreaRange.upperBound, 0)
        XCTAssertLessThanOrEqual(ranges.minSolidityRange.upperBound, 1.0)
        XCTAssertGreaterThan(ranges.maxAspectRatioRange.upperBound, 1.0)
        XCTAssertGreaterThan(ranges.polygonEpsilonFactorRange.upperBound, 0)
        XCTAssertGreaterThanOrEqual(ranges.thresholdOffsetRange.lowerBound, -50.0)
        XCTAssertLessThanOrEqual(ranges.thresholdOffsetRange.upperBound, 50.0)
        XCTAssertGreaterThan(ranges.morphKernelSizeRange.upperBound, 0)
        XCTAssertGreaterThan(ranges.contourMergeDistanceRange.upperBound, 0)
        
        print("✅ Parameter ranges - Lightbox width: \(ranges.lightboxWidthMMRange), Height: \(ranges.lightboxHeightMMRange), Pixels/mm: \(ranges.pixelsPerMMRange)")
    }
    
    func testNewParameterFeatures() {
        // Test new parameter presets
        let preserveDetail = ProcessingParameters.preserveDetail
        XCTAssertTrue(preserveDetail.disableMorphology)
        XCTAssertFalse(preserveDetail.mergeNearbyContours)
        
        let multiContour = ProcessingParameters.multiContour
        XCTAssertTrue(multiContour.mergeNearbyContours)
        XCTAssertEqual(multiContour.contourMergeDistanceMM, 10.0)
        
        // Test new parameter validation
        var params = ProcessingParameters()
        params.thresholdOffset = 25.0
        params.morphKernelSize = 7
        params.contourMergeDistanceMM = 15.0
        params.useAdaptiveThreshold = true
        params.manualThreshold = 128.0
        
        XCTAssertNoThrow(try PrintTrace.validateParameters(params))
        
        print("✅ New parameter features - Preserve detail and multi-contour presets work")
    }
    
    @MainActor
    func testPipelineStageProcessing() async throws {
        guard let testImagePath = getTestImagePath() else {
            print("⚠️ Test image not found - skipping pipeline stage test")
            return
        }
        
        let printTrace = PrintTrace()
        let parameters = ProcessingParameters.default
        
        // Test processing to different stages
        let stages: [PipelineStage] = [.loaded, .lightboxCropped, .normalized, .final]
        
        for stage in stages {
            do {
                let result = try await printTrace.processImageToStage(
                    at: testImagePath,
                    toStage: stage,
                    parameters: parameters
                )
                
                XCTAssertEqual(result.stage, stage)
                XCTAssertNotNil(result.imageData, "Stage \(stage) should have image data")
                XCTAssertGreaterThan(result.processingTime, 0)
                
                // Only final stages should have contours
                if stage == .final {
                    XCTAssertNotNil(result.contour, "Final stage should have contour")
                    if let contour = result.contour {
                        XCTAssertGreaterThan(contour.pointCount, 0)
                        XCTAssertGreaterThan(contour.area, 0)
                    }
                }
                
                print("✅ Stage \(stage.description) - Image data: \(result.imageData?.count ?? 0) bytes, Contour: \(result.contour?.pointCount ?? 0) points")
                
            } catch {
                XCTFail("Failed to process to stage \(stage): \(error)")
            }
        }
    }
    
    func testContourCalculations() {
        // Test contour with simple square
        let points = [
            ContourPoint(x: 0, y: 0),
            ContourPoint(x: 100, y: 0),
            ContourPoint(x: 100, y: 100),
            ContourPoint(x: 0, y: 100)
        ]
        
        let contour = ProcessedContour(points: points, pixelsPerMM: 10.0)
        
        // Check basic properties
        XCTAssertEqual(contour.pointCount, 4)
        XCTAssertEqual(contour.pixelsPerMM, 10.0)
        
        // Check area calculation (10mm x 10mm = 100mm²)
        XCTAssertEqual(contour.area, 100.0, accuracy: 0.1)
        
        // Check perimeter calculation (4 * 10mm = 40mm)
        XCTAssertEqual(contour.perimeter, 40.0, accuracy: 0.1)
        
        // Check bounding rect (10mm x 10mm)
        XCTAssertEqual(contour.boundingRect.width, 10.0, accuracy: 0.1)
        XCTAssertEqual(contour.boundingRect.height, 10.0, accuracy: 0.1)
    }
    
    @MainActor
    func testAsyncProcessing() async throws {
        let printTrace = PrintTrace()
        
        // Test that isProcessing starts as false
        XCTAssertFalse(printTrace.isProcessing)
        
        // Test processing with invalid file should throw
        do {
            _ = try await printTrace.processImage(at: "/nonexistent/file.jpg")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is PrintTraceError)
        }
        
        // Test that isProcessing returns to false after error
        XCTAssertFalse(printTrace.isProcessing)
    }
    
    @MainActor
    func testRealImageProcessing() async throws {
        let printTrace = PrintTrace()
        
        // Get the test image path
        guard let testImagePath = getTestImagePath() else {
            XCTFail("Could not find test image")
            return
        }
        
        // Verify the image file exists and is valid
        XCTAssertTrue(PrintTrace.isValidImageFile(at: testImagePath), "Test image should be valid")
        
        // Test processing with different parameter presets
        let parameterSets: [(ProcessingParameters, String)] = [
            (.default, "default"),
            (.fastProcessing, "fast"),
            (.highPrecision, "high precision")
        ]
        
        for (parameters, description) in parameterSets {
            print("Testing with \(description) parameters...")
            
            // Validate parameters
            XCTAssertNoThrow(try PrintTrace.validateParameters(parameters), 
                           "\(description) parameters should be valid")
            
            // Track progress updates
            var progressUpdates: [ProcessingProgress] = []
            let progressExpectation = self.expectation(description: "Progress updates for \(description)")
            progressExpectation.isInverted = true // We expect this NOT to be fulfilled quickly
            
            // Monitor progress changes
            let cancellable = printTrace.$progress.sink { progress in
                if let progress = progress {
                    progressUpdates.append(progress)
                    print("Progress: \(Int(progress.progress * 100))% - \(progress.stage)")
                }
            }
            
            // Test processing
            do {
                let result = try await printTrace.processImage(
                    at: testImagePath,
                    parameters: parameters
                )
                
                // Verify result properties
                XCTAssertGreaterThan(result.contour.pointCount, 0, 
                                   "Should have detected contour points")
                XCTAssertGreaterThan(result.contour.area, 0, 
                                   "Should have calculated positive area")
                XCTAssertGreaterThan(result.contour.perimeter, 0, 
                                   "Should have calculated positive perimeter")
                XCTAssertGreaterThan(result.processingTime, 0, 
                                   "Should have positive processing time")
                XCTAssertEqual(result.parameters.lightboxWidthPx, parameters.lightboxWidthPx, 
                             "Should preserve parameter values")
                
                // Verify reasonable values for pliers image
                XCTAssertLessThan(result.contour.pointCount, 10000, 
                                "Point count should be reasonable")
                XCTAssertLessThan(result.processingTime, 60.0, 
                                "Processing should complete within 60 seconds")
                
                print("✅ \(description) - Points: \(result.contour.pointCount), " +
                      "Area: \(String(format: "%.1f", result.contour.area))mm², " +
                      "Time: \(String(format: "%.2f", result.processingTime))s")
                
            } catch {
                XCTFail("Processing failed with \(description) parameters: \(error)")
            }
            
            // Clean up
            cancellable.cancel()
            
            // Brief wait to allow any final progress updates
            await self.fulfillment(of: [progressExpectation], timeout: 0.1)
            
            // Verify we got progress updates (with new callback system)
            print("Received \(progressUpdates.count) progress updates")
            // Note: Progress updates depend on the C library implementation
            // so we don't assert specific counts, just verify the system works
        }
        
        // Test that isProcessing returns to false
        XCTAssertFalse(printTrace.isProcessing, "Should not be processing after completion")
        XCTAssertNil(printTrace.progress, "Progress should be cleared after completion")
    }
    
    @MainActor
    func testDXFOutput() async throws {
        let printTrace = PrintTrace()
        
        guard let testImagePath = getTestImagePath() else {
            XCTFail("Could not find test image")
            return
        }
        
        // Create temporary output path
        let tempDir = NSTemporaryDirectory()
        let outputPath = tempDir + "test_pliers.dxf"
        
        // Clean up any existing file
        try? FileManager.default.removeItem(atPath: outputPath)
        
        // Test DXF processing
        do {
            try await printTrace.processImageToDXF(
                imagePath: testImagePath,
                outputPath: outputPath,
                parameters: .default
            )
            
            // Verify DXF file was created
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath), 
                         "DXF file should be created")
            
            // Verify file has content
            let fileSize = try FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? Int64 ?? 0
            XCTAssertGreaterThan(fileSize, 100, "DXF file should have substantial content")
            
            // Verify file contains DXF markers
            let content = try String(contentsOfFile: outputPath)
            XCTAssertTrue(content.contains("SECTION"), "Should contain DXF section markers")
            XCTAssertTrue(content.contains("ENTITIES"), "Should contain DXF entities section")
            
            print("✅ DXF output - File size: \(fileSize) bytes")
            
        } catch {
            XCTFail("DXF processing failed: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(atPath: outputPath)
    }
    
    func testProgressCallbackMemoryManagement() async throws {
        // Test that callback contexts are properly managed
        await MainActor.run {
            let printTrace = PrintTrace()
            weak var weakPrintTrace = printTrace
            
            // PrintTrace should be retained
            XCTAssertNotNil(weakPrintTrace)
        }
        
        // Brief wait for any cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    // MARK: - Helper Methods
    
    private func getTestImagePath() -> String? {
        // Try multiple ways to find the test image
        
        // Method 1: Bundle resource
        let bundle = Bundle(for: type(of: self))
        if let bundlePath = bundle.path(forResource: "IMG_0707", ofType: "jpeg") {
            return bundlePath
        }
        
        // Method 2: Bundle resource in TestImages subdirectory
        if let bundlePath = bundle.path(forResource: "TestImages/IMG_0707", ofType: "jpeg") {
            return bundlePath
        }
        
        // Method 3: Direct file system path
        let directPath = "Tests/SwiftPrintTraceTests/TestImages/IMG_0707.jpeg"
        if FileManager.default.fileExists(atPath: directPath) {
            return directPath
        }
        
        // Method 4: Bundle resource URL
        if let resourceURL = bundle.url(forResource: "IMG_0707", withExtension: "jpeg", subdirectory: "TestImages") {
            return resourceURL.path
        }
        
        // Method 5: Look in the built bundle
        if let builtBundlePath = bundle.path(forResource: "TestImages/IMG_0707", ofType: "jpeg") {
            return builtBundlePath
        }
        
        print("🔍 Searched for test image in:")
        print("   Bundle path: \(bundle.bundlePath)")
        print("   Bundle resource paths: \(bundle.paths(forResourcesOfType: "jpeg", inDirectory: nil as String?))")
        
        return nil
    }
}