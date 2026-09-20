#!/usr/bin/env swift
// Render the deliberately small rectangle-only SVG vocabulary with native AppKit.
import AppKit
import Foundation

final class Logo: NSObject, XMLParserDelegate {
    var rectangles: [[String: String]] = []
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        if elementName == "rect" { rectangles.append(attributeDict) }
    }
}
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let brand = root.appendingPathComponent("assets/brand")
let logo = Logo()
let parser = XMLParser(contentsOf: brand.appendingPathComponent("localports.svg"))!
parser.delegate = logo
precondition(parser.parse() && logo.rectangles.count == 5, "Invalid logo source")
let scratch = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let iconset = scratch.appendingPathComponent("localports.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: scratch) }
func png(_ size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(size) / 1024
    for rectangle in logo.rectangles {
        func n(_ key: String) -> CGFloat { CGFloat(Double(rectangle[key]!)!) }
        let hex = UInt32(rectangle["fill"]!.dropFirst(), radix: 16)!
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1).setFill()
        let rect = NSRect(x: n("x") * scale, y: (1024 - n("y") - n("height")) * scale,
                          width: n("width") * scale, height: n("height") * scale)
        NSBezierPath(roundedRect: rect, xRadius: n("rx") * scale, yRadius: n("rx") * scale).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
try png(1024).write(to: brand.appendingPathComponent("localports.png"))
for size in [16, 32, 128, 256, 512] {
    try png(size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try png(size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", brand.appendingPathComponent("localports.icns").path]
try task.run()
task.waitUntilExit()
precondition(task.terminationStatus == 0, "iconutil failed")
// Windows Vista+ supports PNG-compressed ICO frames.
let sizes = [16, 24, 32, 48, 64, 128, 256]
let frames = sizes.map { png($0) }
var ico = Data()
func word(_ value: Int) { var v = UInt16(value).littleEndian; withUnsafeBytes(of: &v) { ico.append(contentsOf: $0) } }
func dword(_ value: Int) { var v = UInt32(value).littleEndian; withUnsafeBytes(of: &v) { ico.append(contentsOf: $0) } }
word(0); word(1); word(sizes.count)
var offset = 6 + sizes.count * 16
for (size, frame) in zip(sizes, frames) {
    ico.append(contentsOf: [UInt8(size % 256), UInt8(size % 256), 0, 0])
    word(1); word(32); dword(frame.count); dword(offset)
    offset += frame.count
}
for frame in frames { ico.append(frame) }
try ico.write(to: brand.appendingPathComponent("localports.ico"))
print("Generated PNG (1024), ICNS (16–1024), ICO (16–256) from localports.svg")
