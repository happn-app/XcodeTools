// swift-tools-version:5.3
import PackageDescription


let package = Package(
	name: "XcodeTools",
	platforms: [
		.macOS(.v10_15)
	],
	products: [
		.library(name: "XcodeProjKit", targets: ["XcodeProjKit"]),
		.executable(name: "xct-versions", targets: ["xct-versions"]),
		
		/* Obsolete; kept for backwards-compatibility. Will be removed. */
		.executable(name: "hagvtool", targets: ["hagvtool"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.4.0")
	],
	targets: [
		.target(name: "XcodeProjKit", dependencies: [], resources: [Resource.process("PBXModel.xcdatamodeld")]),
		.testTarget(name: "XcodeProjKitTests", dependencies: ["XcodeProjKit"]),
		
		/* A launcher for xcode tools binaries (xct-*) */
		.target(name: "xct", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser")
		]),
		
		.target(name: "xct-versions", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
			"XcodeProjKit"
		]),
		
		/* Obsolete; kept for backwards-compatibility. Will be removed. */
		.target(name: "hagvtool", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
			"XcodeProjKit"
		])
	]
)
