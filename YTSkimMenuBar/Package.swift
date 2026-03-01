// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "YTSkimMenuBar",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .executable(
      name: "YTSkimMenuBar",
      targets: ["YTSkimMenuBar"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.3.0"),
    .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0")
  ],
  targets: [
    .executableTarget(
      name: "YTSkimMenuBar",
      dependencies: [
        .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
        .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern")
      ],
      resources: [
        .copy("Resources")
      ]
    )
  ]
)
