// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "swift-markdown-ui",
  platforms: [
    .macOS(.v12),
    .iOS("17.0"),
    .tvOS(.v15),
    .macCatalyst(.v15),
    .watchOS(.v8),
  ],
  products: [
    .library(
      name: "MarkdownUI",
      targets: ["MarkdownUI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/gonzalezreal/NetworkImage", from: "6.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
    .package(url: "git@github.com:aivahealth/aiva-sdk-ios.git", branch: "main"),
  ],
  targets: [
    .target(name: "cmark-gfm"),
    .target(
      name: "MarkdownUI",
      dependencies: [
        "cmark-gfm",
        .product(name: "NetworkImage", package: "NetworkImage"),
        .product(name: "AivaSDK", package: "aiva-sdk-ios"),
      ]
    ),
    .testTarget(
      name: "MarkdownUITests",
      dependencies: [
        "MarkdownUI",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      exclude: ["__Snapshots__"]
    ),
  ]
)
