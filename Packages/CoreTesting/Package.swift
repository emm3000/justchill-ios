// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "CoreTesting",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "CoreTesting", targets: ["CoreTesting"]),
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
    ],
    targets: [
        .target(
            name: "CoreTesting",
            dependencies: [.product(name: "CoreDomain", package: "CoreDomain")],
            swiftSettings: swiftSettings
        ),
    ]
)
