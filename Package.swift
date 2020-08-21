// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "swift-uri",
    products: [
        .library(name: "SwiftURI", targets: ["SwiftURI"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "SwiftURI", dependencies: []),
        .testTarget(name: "SwiftURITests", dependencies: [
            "SwiftURI",
        ]),
    ]
)
