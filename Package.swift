// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SizeEnforcer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "SizeEnforcerKit",
            path: "Sources/SizeEnforcerKit",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "SizeEnforcer",
            dependencies: ["SizeEnforcerKit"],
            path: "Sources/SizeEnforcer"
        ),
        .testTarget(
            name: "SizeEnforcerKitTests",
            dependencies: ["SizeEnforcerKit"],
            path: "Tests/SizeEnforcerKitTests"
        )
    ]
)
