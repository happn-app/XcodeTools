// swift-tools-version:5.3
import PackageDescription


let package = Package(
	name: "hagvtool",
	platforms: [
		.macOS(.v10_15)
	],
	products: [
		.executable(name: "hagvtool", targets: ["hagvtool"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.1"),
		.package(url: "https://github.com/happn-tech/XcodeProjKit.git", from: "0.1.0")
	],
	targets: [
		.target(name: "hagvtool", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
			"XcodeProjKit"
		])
	]
)
