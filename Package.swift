// swift-tools-version:5.3
import PackageDescription


let package = Package(
	name: "XcodeProjKit",
	platforms: [
		.macOS(.v10_15)
	],
	products: [
		.library(name: "XcodeProjKit", targets: ["XcodeProjKit"]),
	],
	targets: [
		.target(name: "XcodeProjKit", dependencies: [], resources: [Resource.process("PBXModel.xcdatamodeld")]),
		.testTarget(name: "XcodeProjKitTests", dependencies: ["XcodeProjKit"])
	]
)
