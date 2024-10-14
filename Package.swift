// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UCWSDK",
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
            url: "https://github.com/ZhaoZheCobo/cobo-ucw-sdk-ios2/releases/download/v0.1.0/cobo-tss-sdk-v2-ios.zip", 
            checksum: "6e95589d04e5a94f7cfc49de5d6da71b4ee067613848de6934e8a2f977afee90"
        ),
    ]
)
