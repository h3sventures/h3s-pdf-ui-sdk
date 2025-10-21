// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "H3SPDFUILIB",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "h3s_pdf_ui_sdk",
            targets: ["h3s_pdf_ui_sdk"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .binaryTarget(
            name: "h3s_pdf_ui_sdk",
            url: "https://github.com/h3sventures/h3s-pdf-ui-sdk/releases/download/v0.1.0/h3s_pdf_ui_sdk.xcframework.zip",
            checksum: "803a9ce29a3be8570bc1d38a1bae0d6fe1bd51f69f7da6a89ceab617bd0de11c"
        ),
    ]
)
