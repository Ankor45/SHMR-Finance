// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SplashAnimation",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SplashAnimation",
            targets: ["SplashAnimation"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/airbnb/lottie-ios.git",
            from: "4.6.0"
        )
    ],
    targets: [
        .target(
            name: "SplashAnimation",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
