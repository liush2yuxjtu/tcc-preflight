// swift-tools-version:5.7
import PackageDescription
let package = Package(
  name: "TCCPreflightHelper",
  platforms: [.macOS(.v11)],
  targets: [.executableTarget(name: "TCCPreflightHelper", path: "Sources/TCCPreflightHelper")]
)
