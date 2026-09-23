// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "FeatureTransaction",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "FeatureTransaction", targets: ["FeatureTransaction"]),
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreUI"),
        .package(path: "../CoreTesting"),
    ],
    targets: [
        .target(
            name: "FeatureTransaction",
            dependencies: [
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "CoreUI", package: "CoreUI"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FeatureTransactionTests",
            dependencies: [
                "FeatureTransaction",
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "CoreUI", package: "CoreUI"),
                .product(name: "CoreTesting", package: "CoreTesting"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
