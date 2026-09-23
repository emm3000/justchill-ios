// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "CoreDomain",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "CoreDomain", targets: ["CoreDomain"]),
    ],
    targets: [
        .target(name: "CoreDomain", swiftSettings: swiftSettings),
        .testTarget(name: "CoreDomainTests", dependencies: ["CoreDomain"], swiftSettings: swiftSettings),
    ]
)
