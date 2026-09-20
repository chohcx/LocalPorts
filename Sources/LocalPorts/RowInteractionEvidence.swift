import AppKit
import SwiftUI

extension AppDelegate {
    func rowInteractionEvidence(at directory: URL) throws {
        let entry = store.entries[0]
        store.expanded = []
        var measured: [String: CGRect] = [:]
        let host = NSHostingView(rootView: PortRow(store: store, entry: entry, onGeometry: { measured = $0 }).frame(width: 468).frame(maxHeight: .infinity, alignment: .top))
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 468, height: 230), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        func settle() { RunLoop.current.run(until: Date().addingTimeInterval(0.25)); host.layoutSubtreeIfNeeded() }
        func click(_ x: CGFloat, _ top: CGFloat) {
            let point = NSPoint(x: x, y: window.contentView!.bounds.height - top)
            for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                let event = NSEvent.mouseEvent(with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0)!
                window.sendEvent(event)
            }
            settle()
        }
        settle()
        var geometryRows: [[String: Any]] = []
        for (theme, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            window.appearance = NSAppearance(named: appearance)
            for expanded in [false, true] {
                store.expanded = expanded ? [entry.id] : []; settle()
                var row: [String: Any] = ["appearance": theme, "expanded": expanded]
                for part in ["port", "metadata", "chevron", "header"] {
                    guard let frame = measured[part] else { throw NSError(domain: "Missing row geometry: \(part)", code: 1) }
                    row[part + "MidY"] = frame.midY
                    row[part + "Width"] = frame.width
                    row[part + "Frame"] = NSStringFromRect(frame)
                }
                geometryRows.append(row)
            }
        }
        try JSONSerialization.data(withJSONObject: geometryRows, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("row-geometry.json"))
        var results: [String: Bool] = [:]
        for (name, x, top) in [("name", CGFloat(150), CGFloat(18)), ("whitespace", 390, 48), ("chevron", 448, 28)] {
            store.expanded = []; settle()
            click(x, top)
            let opened = store.expanded.contains(entry.id)
            click(x, top)
            results[name] = opened && !store.expanded.contains(entry.id)
        }
        store.expanded = [entry.id]; settle()
        let pasteboard = NSPasteboard.general
        let saved = pasteboard.pasteboardItems?.map { item in
            item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
                guard let data = item.data(forType: type) else { return nil }; return (type, data)
            }
        } ?? []
        // Five detail rows (including Endpoint), then the independent action row.
        click(65, 179)
        results["copyDoesNotToggle"] = store.expanded.contains(entry.id)
        results["copyURL"] = pasteboard.string(forType: .string) == entry.listener.localURL.absoluteString
        pasteboard.clearContents()
        let restored = saved.map { values -> NSPasteboardItem in
            let item = NSPasteboardItem(); for (type, data) in values { item.setData(data, forType: type) }; return item
        }
        pasteboard.writeObjects(restored)
        window.orderOut(nil)
        try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("interaction.json"))
    }
}
