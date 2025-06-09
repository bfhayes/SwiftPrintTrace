#!/usr/bin/env swift

import Foundation
import SwiftPrintTrace

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
@MainActor
class TestRunner {
    
    func run() async {
        print("🧪 SwiftPrintTrace Test Runner")
        print("==============================")
        
        // Test 1: Version info
        print("\n1️⃣ Testing version info...")
        let version = PrintTrace.version
        print("   ✅ PrintTrace version: \(version)")
        
        // Test 2: Parameter validation
        print("\n2️⃣ Testing parameter validation...")
        do {
            try PrintTrace.validateParameters(.default)
            print("   ✅ Default parameters are valid")
            
            try PrintTrace.validateParameters(.highPrecision)
            print("   ✅ High precision parameters are valid")
            
            try PrintTrace.validateParameters(.fastProcessing)
            print("   ✅ Fast processing parameters are valid")
            
        } catch {
            print("   ❌ Parameter validation failed: \(error)")
            return
        }
        
        // Test 3: File validation
        print("\n3️⃣ Testing file validation...")
        let testImagePath = "Tests/SwiftPrintTraceTests/TestImages/IMG_0707.jpeg"
        
        if PrintTrace.isValidImageFile(at: testImagePath) {
            print("   ✅ Test image is valid")
        } else {
            print("   ❌ Test image is invalid or not found")
            print("   ℹ️  Make sure IMG_0707.jpeg exists in Tests/SwiftPrintTraceTests/TestImages/")
            return
        }
        
        // Test 4: Estimated processing time
        print("\n4️⃣ Testing processing time estimation...")
        if let estimatedTime = PrintTrace.estimateProcessingTime(for: testImagePath) {
            print("   ✅ Estimated processing time: \(String(format: "%.2f", estimatedTime))s")
        } else {
            print("   ℹ️  No processing time estimate available")
        }
        
        // Test 5: Actual image processing
        print("\n5️⃣ Testing real image processing...")
        let printTrace = PrintTrace()
        
        // Track progress
        var progressCount = 0
        let progressCancellable = printTrace.$progress.sink { progress in
            if let progress = progress {
                progressCount += 1
                print("   📊 Progress: \(Int(progress.progress * 100))% - \(progress.stage)")
            }
        }
        
        do {
            print("   🚀 Starting image processing...")
            let result = try await printTrace.processImage(
                at: testImagePath,
                parameters: .default
            )
            
            print("   ✅ Processing completed successfully!")
            print("   📈 Results:")
            print("      • Processing time: \(String(format: "%.2f", result.processingTime))s")
            print("      • Contour points: \(result.contour.pointCount)")
            print("      • Area: \(String(format: "%.1f", result.contour.area)) mm²")
            print("      • Perimeter: \(String(format: "%.1f", result.contour.perimeter)) mm")
            print("      • Progress updates received: \(progressCount)")
            
            // Test 6: DXF output
            print("\n6️⃣ Testing DXF output...")
            let tempDir = NSTemporaryDirectory()
            let dxfPath = tempDir + "test_output.dxf"
            
            try await printTrace.processImageToDXF(
                imagePath: testImagePath,
                outputPath: dxfPath,
                parameters: .default
            )
            
            if FileManager.default.fileExists(atPath: dxfPath) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: dxfPath)[.size] as? Int64 ?? 0
                print("   ✅ DXF file created successfully")
                print("   📄 File size: \(fileSize) bytes")
                print("   📁 Path: \(dxfPath)")
            } else {
                print("   ❌ DXF file was not created")
            }
            
        } catch {
            print("   ❌ Processing failed: \(error)")
            if let printTraceError = error as? PrintTraceError {
                print("   💡 Suggestion: \(printTraceError.recoverySuggestion ?? "None")")
            }
        }
        
        progressCancellable.cancel()
        
        print("\n🎉 Test run completed!")
    }
}

// Run the tests
if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
    Task { @MainActor in
        let runner = TestRunner()
        await runner.run()
        exit(0)
    }
    
    RunLoop.main.run()
} else {
    print("❌ This test requires macOS 10.15+ or iOS 13.0+")
    exit(1)
}