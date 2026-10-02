// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Caffeinate",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "CaffeinateKit", targets: ["CaffeinateKit"]),
        .executable(name: "Caffeinate", targets: ["Caffeinate"]),
        .executable(name: "CaffeinateTestRunner", targets: ["CaffeinateTestRunner"])
    ],
    targets: [
        .target(
            name: "CaffeinateKit",
            dependencies: [],
            path: "Sources/CaffeinateKit"
        ),
        .executableTarget(
            name: "Caffeinate",
            dependencies: ["CaffeinateKit"],
            path: "Sources/Caffeinate"
        ),
        .executableTarget(
            name: "CaffeinateTestRunner",
            dependencies: ["CaffeinateKit"],
            path: "Sources/CaffeinateTestRunner"
        )
    ]
)
