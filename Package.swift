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
            // Metal shaders live alongside the Swift code as canonical source,
            // but SPM doesn't compile them into a metallib. Host apps add the
            // .metal files to their own target so Xcode produces the main
            // bundle's default.metallib (resolved by ShaderLibrary.default).
            exclude: ["Shaders"]
        ),
        .testTarget(
            name: "PegGameKitTests",
            dependencies: ["PegGameKit"],
            path: "Tests/PegGameKitTests"
        ),
    ]
)
