// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AccessControls",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AccessControlsCore",
            targets: ["AccessControlsCore"]
        ),
        .executable(
            name: "AccessControls",
            targets: ["AccessControlsApp"]
        ),
        .executable(
            name: "AccessControlsCoreChecks",
            targets: ["AccessControlsCoreChecks"]
        )
    ],
    targets: [
        .target(name: "AccessControlsCore"),
        .executableTarget(
            name: "AccessControlsApp",
            dependencies: ["AccessControlsCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "AccessControlsCoreChecks",
            dependencies: ["AccessControlsCore"],
            path: "Tools/CoreChecks"
        )
    ]
)
