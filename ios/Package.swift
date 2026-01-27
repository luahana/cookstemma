// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cookstemma",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Cookstemma",
            targets: ["Cookstemma"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "Cookstemma",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ],
            path: ".",
            exclude: ["Tests", "UITests"],
            sources: ["App", "Data", "Domain", "Presentation"]
        ),
        .testTarget(
            name: "CookstemmaTests",
            dependencies: ["Cookstemma"],
            path: "Tests"
        ),
    ]
)
