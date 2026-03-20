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
            url: "https://cobo-tss-node.s3.amazonaws.com/sdk/v0.12.9/cobo-tss-sdk-v2-ios-v0.12.9.zip",
            checksum: "a314455f3139b8bb9220998a42a370e6d6aee3d0f9a530644d18828a0a687252"
        ),
    ]
)
