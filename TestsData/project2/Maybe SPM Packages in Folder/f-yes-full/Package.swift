// swift-tools-version:5.5
import PackageDescription



let package = Package(
	name: "FAmazingLib",
	products: [
		.library(name: "FAmazingLib", targets: ["FAmazingLib"])
	],
	targets: [
		.target(name: "FAmazingLib")
	]
)
