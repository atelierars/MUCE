// swift-tools-version: 6.0
// Open Sound Control 1.0
// Reference: https://opensoundcontrol.stanford.edu/spec-1_0.html
import PackageDescription
let package = Package(
	name: "MUCE",
	platforms: [
		.macOS(.v15),
		.macCatalyst(.v18),
		.iOS(.v18),
		.tvOS(.v18)
	],
	products: [
		.library(
			name: "OSC",
			targets: ["OSC"]
		),
		.library(
			name: "Chrono",
			targets: ["Chrono"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/atelierars/MUSE", branch: "release")
	],
	targets: [
		.executableTarget(
			name: "OSC-Snippets",
			dependencies: [.target(name: "OSC")],
			path: "OSC/Snippets",
			swiftSettings: [
				.unsafeFlags(["-enable-bare-slash-regex"])
			]
		),
		.target(
			name: "OSC",
			dependencies: [
//                .target(name: "Nearby"),
				.target(name: "Socket"),
				.product(name: "Foundations", package: "MUSE")
			],
			path: "OSC/Sources"
		),
		.target(
			name: "Chrono",
			dependencies: [
				.target(name: "Socket"),
				.product(name: "Foundations", package: "MUSE")
			],
			path: "Chrono/Sources"
		),
		.target(
			name: "CMTime+",
			path: "CMTime+/Sources",
			publicHeadersPath: "."
		),
//		.target(
//			name: "Nearby",
//			dependencies: [.target(name: "Async+")],
//			path: "Nearby/Sources"
//		),
		.target(
			name: "Socket",
			dependencies: [.target(name: "Async+")],
			path: "Socket/Sources"
		),
		.target(
			name: "Async+",
			path: "Async+/Sources"
		),
		.testTarget(
			name: "OSCTests",
			dependencies: [
				.target(name: "OSC")
			],
			path: "OSC/Tests",
			swiftSettings: [
				.unsafeFlags(["-enable-bare-slash-regex"])
			]
		),
		.testTarget(
			name: "ChronoTests",
			dependencies: [.target(name: "Chrono")],
			path: "Chrono/Tests"
		),
		.testTarget(
			name: "SocketTests",
			dependencies: [.target(name: "Socket")],
			path: "Socket/Tests"
		),
		.testTarget(
			name: "Async+Tests",
			dependencies: [.target(name: "Async+")],
			path: "Async+/Tests"
		),
	]
)
