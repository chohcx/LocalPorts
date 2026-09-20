import AppKit
import SwiftUI
import PortsCore

extension AppDelegate {
    /// Real attached popover, targeted native mouse events, no global cursor movement.
    func jitterEvidence(at directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fixture = """
        [{"listener":{"pid":4201,"uid":501,"executable":"node","host":"*","port":8787},"metrics":{"cpu":1.2,"rssKB":65536,"elapsed":"02:34"},"cwd":"/example/web"},
         {"listener":{"pid":4202,"uid":501,"executable":"python3","host":"127.0.0.1","port":8000},"metrics":{"cpu":0.1,"rssKB":32768,"elapsed":"01:12:03"},"cwd":"/example/api"}]
        """
        store.entries = try JSONDecoder().decode([Entry].self, from: Data(fixture.utf8))
        var geometry: [String: [String: CGRect]] = [:]
        var headers: [String: NSView] = [:]
        popover.contentViewController = PopoverContentController(content: PortsView(store: store, onRowGeometry: { geometry[$0] = $1 }, onNativeHeader: { headers[$0] = $1 }), popover: popover)
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        toggle()
        func pump(_ seconds: Double) { RunLoop.current.run(until: Date().addingTimeInterval(seconds)) }
        pump(0.3)
        let host = popover.contentViewController!.view
        let window = host.window!
        var samples: [[String: Any]] = []
        func sample(_ phase: String, _ time: Double) {
            let f = window.frame
            let top = host.convert(NSPoint(x: 0, y: host.isFlipped ? 0 : host.bounds.height), to: nil)
            let screenTop = window.convertPoint(toScreen: top)
            let header = headers[store.entries[0].id]!
            let native = window.convertToScreen(header.convert(header.bounds, to: nil))
            samples.append(["detailHeight": geometry[store.entries[0].id]?["detailViewport"]?.height ?? -1, "nativeHeaderScreenY": native.midY, "phase": phase, "time": time, "x": f.minX, "y": f.minY, "width": f.width, "height": f.height, "top": f.maxY, "contentTop": screenTop.y, "firstHeaderY": geometry[store.entries[0].id]?["header"]?.midY ?? -1, "firstHeaderScreenY": screenTop.y - (geometry[store.entries[0].id]?["header"]?.midY ?? -1)])
        }
        func record(_ phase: String, _ duration: Double) {
            let start = ProcessInfo.processInfo.systemUptime
            repeat {
                sample(phase, ProcessInfo.processInfo.systemUptime - start)
                pump(0.004)
            } while ProcessInfo.processInfo.systemUptime - start < duration
        }
        func click(_ index: Int, _ phase: String) throws {
            let entry = store.entries[index]
            guard let header = headers[entry.id] else { throw NSError(domain: "Missing header", code: 1) }
            sample(phase, 0)
            let point = header.convert(NSPoint(x: header.bounds.midX, y: header.bounds.midY), to: nil)
            let wasExpanded = store.expanded.contains(entry.id)
            for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                window.sendEvent(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0)!)
            }
            record(phase, 0.8)
            sample(phase, 0.8)
            guard store.expanded.contains(entry.id) != wasExpanded else { throw NSError(domain: "Native row click failed: \(phase)", code: 2) }
        }
        record("idle", 0.15)
        try click(0, "first-open")
        try click(1, "both-open")
        // Exercise the real scroll view, not expansion state or stale panel coordinates.
        guard let scroll = headers[store.entries[1].id]?.enclosingScrollView,
              let document = scroll.documentView else { throw NSError(domain: "Missing scroll view", code: 3) }
        scroll.contentView.scroll(to: NSPoint(x: 0, y: max(0, document.bounds.height - scroll.contentView.bounds.height)))
        scroll.reflectScrolledClipView(scroll.contentView)
        pump(0.15)
        guard scroll.contentView.bounds.origin.y > 0,
              let actions = geometry[store.entries[1].id]?["actions"] else { throw NSError(domain: "Missing overflow actions", code: 4) }
        let actionPoint = host.convert(NSPoint(x: actions.midX, y: host.isFlipped ? actions.midY : host.bounds.height - actions.midY), to: scroll.contentView)
        guard scroll.contentView.bounds.contains(actionPoint) else { throw NSError(domain: "Overflow actions not reachable", code: 5) }
        record("scrolled-idle", 0.15)
        scroll.contentView.scroll(to: .zero)
        scroll.reflectScrolledClipView(scroll.contentView)
        pump(0.15)
        try click(0, "first-close")
        try click(1, "second-close")
        try click(1, "second-open")
        // The same published invalidations as a completed poll, with deterministic data.
        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            self.store.busy = true
            self.store.entries = try! JSONDecoder().decode([Entry].self, from: Data(fixture.utf8))
            self.store.updated = Date()
            self.store.busy = false
        }
        record("polling", 4.3)
        timer.invalidate()
        try click(1, "final-close")
        sample("search", 0)
        store.query = "node"
        record("search", 0.3)
        store.query = ""
        record("search", 0.3)
        try JSONSerialization.data(withJSONObject: samples, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("frames.json"))
        popover.performClose(nil)
    }
}
