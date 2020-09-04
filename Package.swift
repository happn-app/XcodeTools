// swift-tools-version:5.3
import PackageDescription


let package = Package(
	name: "hagvtool",
	platforms: [
		.macOS(.v10_14)
	],
	products: [
		.library(name: "libhagvtool", targets: ["libhagvtool"]),
		.executable(name: "hagvtool", targets: ["hagvtool"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.1")
	],
	targets: [
		.target(name: "libhagvtool", dependencies: [], resources: [Resource.process("PBXModel.xcdatamodeld")]),
		.target(name: "hagvtool", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
			"libhagvtool"
		])
	]
)
