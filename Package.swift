// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "PerDayCore",
  platforms: [.macOS("27.0")],
  products: [.library(name: "PerDayCore", targets: ["PerDayCore"])],
  targets: [
    .target(
      name: "PerDayCore", path: "PerDay/Features",
      exclude: [
        "Blocks/Views", "Calendar/Views", "Home/Views", "Shared",
        "Voice/VoiceRecorder.swift", "Voice/VoiceBlockView.swift",
        "Voice/VoiceManualBlockView.swift",
      ],
      swiftSettings: [.defaultIsolation(MainActor.self)]
    ),
    .testTarget(
      name: "PerDayCoreTests", dependencies: ["PerDayCore"],
      swiftSettings: [.defaultIsolation(MainActor.self)]),
  ],
  swiftLanguageModes: [.v5]
)
