// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "CoreUI",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "CoreUI", targets: ["CoreUI"]),
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [.product(name: "CoreDomain", package: "CoreDomain")],
            swiftSettings: swiftSettings
        ),
    ]
)
