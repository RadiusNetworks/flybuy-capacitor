// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FlybuyCapacitor",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "FlybuyCapacitor",
            targets: ["FlybuyCapacitorPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/RadiusNetworks/flybuy-ios.git", from: "2.12.5"),
    ],
    targets: [
        .target(
            name: "FlybuyCapacitorPluginObjC",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
            ],
            path: "ios/Plugin",
            sources: ["FlybuyPlugin.m", "FlybuyPickupPlugin.m", "FlybuyNotifyPlugin.m"],
            publicHeadersPath: "."
        ),
        .target(
            name: "FlybuyCapacitorPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "FlyBuyPickup", package: "flybuy-ios"),
                .product(name: "FlyBuyNotify", package: "flybuy-ios"),
                "FlybuyCapacitorPluginObjC",
            ],
            path: "ios/Plugin",
            sources: ["FlybuyPlugin.swift", "FlybuyPickupPlugin.swift", "FlybuyNotifyPlugin.swift"]
        )
    ]
)