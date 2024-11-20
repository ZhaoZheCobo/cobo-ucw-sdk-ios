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
            url: "https://cobo-tss-node.s3.amazonaws.com/sdk/v0.10.0/cobo-tss-sdk-v2-ios-v0.10.0.zip",
            checksum: "1f42f73ba4baede315b459ecc91ff4ff204f4c33edbf026747aa81d98cabe041"
        ),
    ]
)
