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
            url: "", 
            checksum: ""
        ),
    ]
)
