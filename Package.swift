// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BiAffectSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BiAffectSDK",
            targets: ["BiAffectSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "JsonModel",
                 url: "https://github.com/BiAffectBridge/JsonModel-Swift.git",
                 from: "2.5.0"),
        .package(name: "AssessmentModel",
                 url: "https://github.com/BiAffectBridge/AssessmentModel-Swift.git",
                 from: "1.2.1"),
        .package(name: "MobilePassiveData",
                 url: "https://github.com/BiAffectBridge/MobilePassiveData-Swift.git",
                 from: "1.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BiAffectSDK",
            dependencies: [
                .product(name: "JsonModel", package: "JsonModel"),
                .product(name: "AssessmentModel", package: "AssessmentModel"),
                .product(name: "AssessmentModelUI", package: "AssessmentModel"),
                .product(name: "MobilePassiveData", package: "MobilePassiveData"),
                .product(name: "MotionSensor", package: "MobilePassiveData"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BiAffectSDKTests",
            dependencies: ["BiAffectSDK"]),
    ]
)



