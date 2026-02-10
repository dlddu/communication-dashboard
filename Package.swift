// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CommunicationDashboard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CommunicationDashboard",
            targets: ["CommunicationDashboard"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "CommunicationDashboard",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/CommunicationDashboard"
        ),
        .testTarget(
            name: "CommunicationDashboardTests",
            dependencies: [
                "CommunicationDashboard",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Tests/CommunicationDashboardTests"
        )
    ]
)
