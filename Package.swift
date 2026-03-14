// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CommBoard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CommBoard",
            targets: ["CommBoard"]
        ),
        .executable(
            name: "CommBoardApp",
            targets: ["CommBoardApp"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/groue/GRDB.swift.git",
            from: "6.0.0"
        ),
        .package(
            url: "https://github.com/jpsim/Yams.git",
            from: "5.0.0"
        )
    ],
    targets: [
        .target(
            name: "CommBoard",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                "Yams"
            ],
            path: "Sources/CommBoard"
        ),
        .executableTarget(
            name: "CommBoardApp",
            dependencies: [
                "CommBoard"
            ],
            path: "Sources/CommBoardApp"
        ),
        .testTarget(
            name: "CommBoardTests",
            dependencies: [
                "CommBoard",
                .product(name: "GRDB", package: "GRDB.swift"),
                "Yams"
            ],
            path: "Tests/CommBoardTests"
        ),
        .testTarget(
            name: "CommBoardUITests",
            dependencies: [
                "CommBoard",
                .product(name: "GRDB", package: "GRDB.swift"),
                "Yams"
            ],
            path: "Tests/CommBoardUITests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
