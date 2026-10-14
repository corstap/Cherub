// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CherubAnalysis",
    products: [.library(name: "CherubAnalysis", targets: ["CherubAnalysis"])],
    targets: [
        .target(
            name: "CherubAnalysis", path: "Cherub",
            exclude: [
                "Assets.xcassets", "CherubApp.swift", "CherubStore.swift", "Components.swift",
                "CycleView.swift", "CycleWheelView.swift", "LogView.swift", "MoonView.swift",
                "PatternsView.swift", "RootView.swift", "SettingsView.swift", "Theme.swift", "TodayView.swift"
            ],
            sources: ["Models.swift", "MoonCalculator.swift", "PatternAnalysis.swift"]
        ),
        .testTarget(name: "CherubAnalysisTests", dependencies: ["CherubAnalysis"], path: "Tests/PatternAnalysisTests")
    ]
)
