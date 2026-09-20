// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "LocalPorts", platforms: [.macOS(.v13)], products: [.executable(name: "LocalPorts", targets: ["LocalPorts"])], targets: [.target(name: "PortsCore"), .executableTarget(name: "LocalPorts", dependencies: ["PortsCore"]), .testTarget(name: "PortsCoreTests", dependencies: ["PortsCore"])])
