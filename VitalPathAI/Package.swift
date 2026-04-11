// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VitalPathAI",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17)
    ],
    products: [
        .library(
            name: "VitalPathAI",
            targets: ["VitalPathAI"]
        ),
    ],
    targets: [
        .target(
            name: "VitalPathAI",
            path: "VitalPathAI/Sources"
        ),
    ]
)
