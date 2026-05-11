// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PegGame",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "PegGameKit", targets: ["PegGameKit"]),
        .library(name: "PegGameUI", targets: ["PegGameUI"]),
    ],
    targets: [
        .target(
            name: "PegGameKit",
            path: "Sources/PegGameKit"
        ),
        .target(
            name: "PegGameUI",
            dependencies: ["PegGameKit"],
            path: "Sources/PegGameUI",
            // The build-tool plugin compiles Sources/PegGameUI/Shaders/*.metal
            // into a default.metallib that ends up in this target's resource
            // bundle. Excluding the raw .metal files keeps SPM from also
            // treating them as un-handled resources.
            exclude: ["Shaders"],
            plugins: [
                .plugin(name: "CompileMetalShaders"),
            ]
        ),
        .plugin(
            name: "CompileMetalShaders",
            capability: .buildTool(),
            path: "Plugins/CompileMetalShaders"
        ),
        .testTarget(
            name: "PegGameKitTests",
            dependencies: ["PegGameKit"],
            path: "Tests/PegGameKitTests"
        ),
    ]
)
