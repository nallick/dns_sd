// swift-tools-version:5.0

import PackageDescription

#if os(Linux)
let platformDependencies: [PackageDescription.Target.Dependency] = ["Cdns_sd"]
#else
let platformDependencies: [PackageDescription.Target.Dependency] = []
#endif

let package = Package(
    name: "dns_sd",
    products: [
        .library(
            name: "dns_sd",
            targets: ["dns_sd"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(
            name: "Cdns_sd",
            path: "Cdns_sd",
            pkgConfig: "avahi-compat-libdns_sd",
            providers: [
                .apt(["libavahi-compat-libdnssd-dev"]),
            ]),
        .target(
            name: "dns_sd",
            dependencies: platformDependencies),
        .testTarget(
            name: "dns_sdTests",
            dependencies: ["dns_sd"]),
    ]
)
