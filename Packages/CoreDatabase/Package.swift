// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "CoreDatabase",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "CoreDatabase", targets: ["CoreDatabase"]),
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(url: "https://github.com/groue/GRDB.swift", exact: "7.11.1"),
    ],
    targets: [
        .target(
            name: "CoreDatabase",
            dependencies: [
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CoreDatabaseTests",
            dependencies: [
                "CoreDatabase",
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Tests",
            resources: [.copy("Fixtures")],
            swiftSettings: swiftSettings
        ),
    ]
)
