// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UCWSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "UCWSDK",
            targets: ["UCWSDK"]),
    ],
    
    targets: [
        .target(
            name: "UCWSDK",
            dependencies: [
                .target(name: "TSSSDK")
            ]
        ),
        .binaryTarget(name: "TSSSDK", 
            url: "https://cobo-tss-node.s3.amazonaws.com/sdk/v0.11.9/cobo-tss-sdk-v2-ios-v0.11.9.zip",
            checksum: "f1749d44f84b412c0f441e0df2d00ba4bfe969cb4265e484a5fb0c3284c76937"
        ),
    ]
)
