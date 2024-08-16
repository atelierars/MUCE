// swift-tools-version: 5.9
// Open Sound Control 1.0
// Reference: https://opensoundcontrol.stanford.edu/spec-1_0.html
import PackageDescription
let package = Package(
    name: "MUCE",
    platforms: [
		.iOS(.v17),
		.tvOS(.v17),
		.macOS(.v14),
		.macCatalyst(.v17)
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
		.package(url: "https://github.com/atelierars/MUSE", branch: "develop")
    ],
    targets: [
        .target(
            name: "OSC",
            dependencies: [
                .target(name: "Nearby"),
				.target(name: "Socket"),
            ],
            path: "OSC/Sources"
        ),
		.target(
			name: "Chrono",
			dependencies: [
				.target(name: "Socket"),
				.target(name: "CMTime+"),
				.product(name: "RationalNumbers", package: "MUSE")
			],
			path: "Chrono/Sources"
		),
		.target(
			name: "CMTime+",
			path: "CMTime+/Sources",
			publicHeadersPath: "."
		),
		.target(
			name: "Nearby",
			dependencies: [.target(name: "Async+")],
			path: "Nearby/Sources"
		),
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
