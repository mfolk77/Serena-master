// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SerenaNet",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "SerenaNet",
            targets: ["SerenaNet"]
        ),
        .library(
            name: "SerenaCore",
            targets: ["SerenaCore"]
        ),
        .library(
            name: "SerenaUI",
            targets: ["SerenaUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
    ],
    targets: [
        // Shared Core Business Logic
        .target(
            name: "SerenaCore",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "Sources/SerenaCore"
        ),
        
        // Shared UI Components
        .target(
            name: "SerenaUI",
            dependencies: [
                "SerenaCore"
            ],
            path: "Sources/SerenaUI"
        ),
        
        // Platform-specific executable
        .executableTarget(
            name: "SerenaNet",
            dependencies: [
                "SerenaCore",
                "SerenaUI"
            ],
            path: "Sources/SerenaNet"
        ),
        
        // Tests
        .testTarget(
            name: "SerenaCoreTests",
            dependencies: ["SerenaCore"],
            path: "Tests/SerenaCoreTests"
        ),
        .testTarget(
            name: "SerenaUITests",
            dependencies: ["SerenaUI"],
            path: "Tests/SerenaUITests"
        ),
        .testTarget(
            name: "SerenaNetTests",
            dependencies: ["SerenaNet"],
            path: "Tests/SerenaNetTests"
        ),
    ]
)
