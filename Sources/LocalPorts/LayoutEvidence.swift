import AppKit
import SwiftUI
import PortsCore

extension AppDelegate {
    func layoutEvidence(at directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var rows: [[String: Any]] = []
        let button = status.button!
        popover.animates = false
        for (theme, name) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            button.appearance = NSAppearance(named: name)
            for count in [0, 1, 99, 1000] {
                updateCount(String(count))
                button.window?.displayIfNeeded()
                button.layoutSubtreeIfNeeded()
                let artwork = StatusArtwork.make(String(count))
                let frame = button.cell!.imageRect(forBounds: button.bounds)
                let icon = artwork.icon.offsetBy(dx: frame.minX, dy: frame.minY)
                let text = artwork.text.offsetBy(dx: frame.minX, dy: frame.minY)
                button.performClick(nil)
                let opened = popover.isShown
                button.performClick(nil)
                let closed = !popover.isShown
                let png = "status-\(theme)-\(count).png"
                let rep = button.bitmapImageRepForCachingDisplay(in: button.bounds)!
                button.cacheDisplay(in: button.bounds, to: rep)
                try rep.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("native-" + png))
                // Menu-bar vibrancy cannot be captured reliably with cacheDisplay.
                // Render the identical template mask on explicit theme backgrounds.
                let canvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(button.bounds.width * 4), pixelsHigh: Int(button.bounds.height * 4), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
                NSGraphicsContext.current!.cgContext.scaleBy(x: 4, y: 4)
                (theme == "dark" ? NSColor(calibratedWhite: 0.13, alpha: 1) : NSColor(calibratedWhite: 0.96, alpha: 1)).setFill()
                button.bounds.fill()
                let tinted = NSImage(size: artwork.image.size, flipped: false) { bounds in
                    artwork.image.draw(in: bounds)
                    (theme == "dark" ? NSColor.white : NSColor.black).setFill()
                    bounds.fill(using: .sourceIn)
                    return true
                }
                tinted.draw(in: frame)
                NSGraphicsContext.restoreGraphicsState()
                try canvas.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(png))
                rows.append(["count": count, "appearance": theme, "iconMidY": icon.midY,
                             "textMidY": text.midY, "buttonMidY": button.bounds.midY,
                             "leftInset": icon.minX, "rightInset": button.bounds.maxX-text.maxX,
                             "gap": text.minX-icon.maxX, "imageWidth": frame.width,
                             "buttonWidth": button.bounds.width, "buttonHeight": button.bounds.height,
                             "iconFrame": NSStringFromRect(icon), "textFrame": NSStringFromRect(text),
                             "nativeClickOpened": opened, "nativeClickClosed": closed,
                             "accessible": button.accessibilityLabel()?.contains(String(count)) == true, "png": png])
            }
        }
        try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
            .write(to: directory.appendingPathComponent("geometry.json"))
        // Synthetic, explicitly labelled fixtures avoid exposing project paths.
        let fixture = """
        [{"listener":{"pid":4201,"uid":501,"executable":"node","host":"*","port":8787},"metrics":{"cpu":1.2,"rssKB":65536,"elapsed":"02:34"},"cwd":"/example/web-studio"},
         {"listener":{"pid":4202,"uid":501,"executable":"python3","host":"127.0.0.1","port":8000},"metrics":{"cpu":0.1,"rssKB":32768,"elapsed":"01:12:03"},"cwd":"/example/api-service"}]
        """
        store.entries = try JSONDecoder().decode([PortsCore.Entry].self, from: Data(fixture.utf8))
        try rowInteractionEvidence(at: directory)
        for expanded in [false, true] {
        store.expanded = expanded ? Set(store.entries.map(\.id)) : []
        for (theme, name) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            NSApp.appearance = NSAppearance(named: name)
            let host = NSHostingView(rootView: PortsView(store: store).environment(\.colorScheme, theme == "dark" ? .dark : .light).background(theme == "dark" ? Color(NSColor.windowBackgroundColor) : Color.white))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 530), styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: name)
            window.contentView = host
            host.frame.size = host.fittingSize
            host.layoutSubtreeIfNeeded()
            let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
            NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
                host.cacheDisplay(in: host.bounds, to: bitmap)
            }
            try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("panel-fixture-\(expanded ? "expanded" : "collapsed")-\(theme).png"))
        }
        }
    }
}
