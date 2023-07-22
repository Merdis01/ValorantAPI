// swift-tools-version:5.6

import PackageDescription

let package = Package(
	name: "ValorantAPI",
	platforms: [
		.macOS("12"),
		.iOS("15"),
	],
	products: [
		.library(
			name: "ValorantAPI",
			targets: ["ValorantAPI"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/juliand665/HandyOperators.git", from: "2.1.0"),
		.package(url: "https://github.com/juliand665/ArrayBuilder.git", from: "1.1.0"),
		.package(url: "https://github.com/juliand665/Protoquest.git", branch: "main"),
		.package(url: "https://github.com/juliand665/ErgonomicCodable.git", branch: "main"),
		.package(url: "https://github.com/apple/swift-collections.git", from: "1.0.3"),
	],
	targets: [
		.target(
			name: "ValorantAPI",
			dependencies: [
				"HandyOperators",
				"ArrayBuilder",
				"Protoquest",
				"ErgonomicCodable",
				.product(name: "Collections", package: "swift-collections"),
			]
		),
		.testTarget(
			name: "ValorantAPITests",
			dependencies: ["ValorantAPI"],
			resources: [
				.copy("examples"),
			]
		),
	]
)
