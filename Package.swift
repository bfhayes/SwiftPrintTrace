// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "SwiftPrintTrace",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftPrintTrace",
            targets: ["SwiftPrintTrace"]
        )
    ],
    targets: [
        // System library target for macOS/Linux
        .systemLibrary(
            name: "CPrintTrace",
            pkgConfig: "printtrace",
            providers: [
                .brew(["printtrace"]),
                .apt(["libprinttrace-dev"]),
                .yum(["printtrace-devel"])
            ]
        ),
        
        // Binary framework target for iOS (uncomment when XCFramework is available)
        // .binaryTarget(
        //     name: "PrintTraceFramework",
        //     path: "Frameworks/PrintTrace.xcframework"
        // ),
        
        // Swift wrapper
        .target(
            name: "SwiftPrintTrace",
            dependencies: [
                .target(name: "CPrintTrace")
                // TODO: Add iOS framework dependency when XCFramework is built:
                // .target(name: "PrintTraceFramework", condition: .when(platforms: [.iOS, .tvOS, .watchOS]))
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: [
                // macOS/Linux linking
                .linkedLibrary("printtrace", .when(platforms: [.macOS, .linux])),
                .unsafeFlags([
                    "-L/usr/local/lib", 
                    "-L/opt/homebrew/opt/opencv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/opencv/lib"
                ], .when(platforms: [.macOS, .linux]))
            ]
        ),
        
        // Tests
        .testTarget(
            name: "SwiftPrintTraceTests",
            dependencies: ["SwiftPrintTrace"],
            resources: [
                .copy("TestImages/")
            ],
            linkerSettings: [
                .linkedLibrary("printtrace", .when(platforms: [.macOS, .linux])),
                .unsafeFlags([
                    "-L/usr/local/lib", 
                    "-L/opt/homebrew/opt/opencv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/opencv/lib"
                ], .when(platforms: [.macOS, .linux]))
            ]
        ),
        
        // Example executable (macOS/Linux only)
        .executableTarget(
            name: "SwiftPrintTraceExample",
            dependencies: ["SwiftPrintTrace"],
            path: "Examples/CLI",
            linkerSettings: [
                .linkedLibrary("printtrace", .when(platforms: [.macOS, .linux])),
                .unsafeFlags([
                    "-L/usr/local/lib", 
                    "-L/opt/homebrew/opt/opencv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/opencv/lib"
                ], .when(platforms: [.macOS, .linux]))
            ]
        )
    ]
)
