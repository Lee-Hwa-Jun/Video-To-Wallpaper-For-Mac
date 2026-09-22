// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VideoWallpaper",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "VideoWallpaper",
            path: "Sources/VideoWallpaper",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("CoreImage"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UniformTypeIdentifiers"),
            ]
        )
    ]
)
