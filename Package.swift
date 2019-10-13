// swift-tools-version:5.0

import PackageDescription

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
            dependencies: ["Cdns_sd"]),
        .testTarget(
            name: "dns_sdTests",
            dependencies: ["dns_sd"]),
    ]
)
