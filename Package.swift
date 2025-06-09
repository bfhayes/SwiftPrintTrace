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
        // System library target
        .systemLibrary(
            name: "CPrintTrace",
            pkgConfig: "printtrace",
            providers: [
                .brew(["printtrace"]),
                .apt(["libprinttrace-dev"]),
                .yum(["printtrace-devel"])
            ]
        ),
        
        // Swift wrapper
        .target(
            name: "SwiftPrintTrace",
            dependencies: ["CPrintTrace"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: [
                .linkedLibrary("printtrace"),
                .unsafeFlags([
                    "-L/usr/local/lib", 
                    "-L/opt/homebrew/opt/opencv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/opencv/lib"
                ])
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
                .linkedLibrary("printtrace"),
                .unsafeFlags([
                    "-L/usr/local/lib", 
                    "-L/opt/homebrew/opt/opencv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/opencv/lib"
                ])
            ]
        ),
        
        // Example executable (optional)
        .executableTarget(
            name: "SwiftPrintTraceExample",
            dependencies: ["SwiftPrintTrace"],
            path: "Examples/CLI",
            linkerSettings: [
                .linkedLibrary("printtrace"),
                .unsafeFlags([
                    "-L/usr/local/lib", 
                    "-L/opt/homebrew/opt/opencv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/opencv/lib"
                ])
            ]
        )
    ]
)
