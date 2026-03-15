// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CommBoard",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CommBoard", targets: ["CommBoard"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "CommBoard",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/CommBoard"
        ),
        .testTarget(
            name: "CommBoardTests",
            dependencies: [
                "CommBoard",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Tests/CommBoardTests"
        )
    ]
)
