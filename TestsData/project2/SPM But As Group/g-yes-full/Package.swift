// swift-tools-version:5.5
import PackageDescription



let package = Package(
	name: "GAmazingLib",
	products: [
		.library(name: "GAmazingLib", targets: ["GAmazingLib"])
	],
	targets: [
		.target(name: "GAmazingLib")
	]
)
