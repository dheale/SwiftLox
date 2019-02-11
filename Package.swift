// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Lox",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/objecthub/swift-commandlinekit", from: "0.0.0"),
    ],
    targets: [
        .target(
            name: "Lox",
            dependencies: ["LoxInterpreter", "CommandLineKit"]),
	.target(name: "LoxInterpreter"),
        .testTarget(name: "LoxInterpreterTests", dependencies: ["LoxInterpreter"]),
        .testTarget(
            name: "LoxTests",
            dependencies: ["Lox"]),
    ]
)
