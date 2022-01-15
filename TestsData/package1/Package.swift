// swift-tools-version:5.5
import PackageDescription



let package = Package(
	name: "package1",
	products: [.library(name: "package1", targets: ["package1"])],
	targets: [
		.target(name: "package1"),
		.testTarget(name: "package1Tests", dependencies: ["package1"])
	]
)
