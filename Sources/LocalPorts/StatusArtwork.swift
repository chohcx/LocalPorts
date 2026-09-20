import AppKit

/// One symbol identity for the menu bar and panel. The status button remains native:
/// AppKit owns highlighting, hit testing, accessibility and popover anchoring.
enum StatusArtwork {
    static let symbol = "server.rack"
    struct Artwork {
        let image: NSImage
        let icon: NSRect
        let text: NSRect
    }
    // Crop transparent font/symbol padding BEFORE centering. A font line box is
    // not the visible digit bounds; SF Symbols also carry baseline padding.
    static func ink(_ draw: () -> Void) -> NSImage {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 64,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current!.cgContext.scaleBy(x: 2, y: 2)
        draw()
        NSGraphicsContext.restoreGraphicsState()
        var x0 = bitmap.pixelsWide, y0 = bitmap.pixelsHigh, x1 = 0, y1 = 0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide where bitmap.colorAt(x: x, y: y)!.alphaComponent > 0.01 {
                x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
            }
        }
        precondition(x1 >= x0 && y1 >= y0)
        let cg = bitmap.cgImage!.cropping(to: CGRect(x: x0, y: y0, width: x1-x0+1, height: y1-y0+1))!
        return NSImage(cgImage: cg, size: NSSize(width: CGFloat(cg.width)/2, height: CGFloat(cg.height)/2))
    }
    static func make(_ count: String) -> Artwork {
        let glyph = ink {
            let symbolImage = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)!
                .withSymbolConfiguration(.init(pointSize: 16, weight: .regular))!
            symbolImage.draw(in: NSRect(x: 4, y: 4, width: 18, height: 18))
        }
        let digits = ink {
            (count as NSString).draw(at: NSPoint(x: 4, y: 4), withAttributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.black])
        }
        let h: CGFloat = 18, gap: CGFloat = 5
        let icon = NSRect(x: 0, y: (h-glyph.size.height)/2, width: glyph.size.width, height: glyph.size.height)
        let text = NSRect(x: icon.maxX+gap, y: (h-digits.size.height)/2, width: digits.size.width, height: digits.size.height)
        let image = NSImage(size: NSSize(width: text.maxX, height: h), flipped: false) { _ in
            glyph.draw(in: icon); digits.draw(in: text); return true
        }
        image.isTemplate = true
        return Artwork(image: image, icon: icon, text: text)
    }
}
