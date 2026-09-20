import AppKit
import SwiftUI
import PortsCore
import Darwin

final class Store: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var query = ""
    @Published var devOnly = false
    @Published var busy = false
    @Published var error: String?
    @Published var updated: Date?
    @Published var expanded = Set<String>()
    private var panelOpen = false
    var timer: Timer?
    var onCount: ((Int) -> Void)?
    var visible: [Entry] {
        entries.filter { entry in
            let project = entry.cwd.map { URL(fileURLWithPath: $0).lastPathComponent } ?? ""
            return (!devOnly || entry.listener.isDeveloper) && (entry.listener.matches(query, devOnly: false) || project.localizedCaseInsensitiveContains(query))
        }
    }
    func start() {
        setPanelOpen(false)
        refresh()
    }
    func setPanelOpen(_ open: Bool) {
        panelOpen = open
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: panelOpen ? 2 : 10, repeats: true) { [weak self] _ in self?.refresh() }
        if open { refresh() }
    }
    deinit { timer?.invalidate() }
    func refresh() {
        guard !busy else { return }; busy = true
        DispatchQueue.global(qos: .utility).async {
            let result = Result { try Inspector.scan() }
            DispatchQueue.main.async {
                self.busy = false
                switch result {
                case .success(let rows): self.expanded.formIntersection(Set(rows.map(\.id))); self.entries = rows; self.error = nil; self.updated = Date(); self.onCount?(rows.count)
                case .failure(let error): self.error = error.localizedDescription
                }
            }
        }
    }
    func stop(_ entry: Entry) {
        guard let identity = entry.identity else { return }
        let alert = NSAlert()
        alert.messageText = "Stop \(entry.listener.executable) (PID \(entry.listener.pid))?"
        alert.informativeText = "Send SIGTERM to the entire process. All its ports may close and unsaved work may be lost. Only processes you own with an unchanged identity can be stopped."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel"); alert.addButton(withTitle: "Send SIGTERM")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertSecondButtonReturn else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try Inspector.terminate(pid: entry.listener.pid, expected: identity) }
            DispatchQueue.main.async {
                if case .failure(let error) = result { self.error = error.localizedDescription }
                else { self.error = "SIGTERM sent. The process may take time to exit or ignore the signal." }
                self.refresh()
            }
        }
    }
    func terminal(_ entry: Entry) {
        guard let cwd = entry.cwd else { return }
        // Open a new Terminal window at the directory; do not pretend to locate its original terminal.
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([URL(fileURLWithPath: cwd, isDirectory: true)], withApplicationAt: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"), configuration: config) { _, error in
            if let error = error { DispatchQueue.main.async { self.error = error.localizedDescription } }
        }
    }
}

struct PortsView: View {
    @ObservedObject var store: Store
    var onRowGeometry: ((String, [String: CGRect]) -> Void)? = nil
    var onNativeHeader: ((String, NSView) -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text("LocalPorts").font(.system(size: 14, weight: .semibold))
                Text(String(store.visible.count)).font(.caption.monospacedDigit()).foregroundColor(.secondary)
                Spacer()
                Button { store.refresh() } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.plain).help("Refresh").accessibilityLabel("Refresh")
                Menu {
                    Toggle("Developer processes only", isOn: $store.devOnly)
                    Divider()
                    Button("Quit LocalPorts") { NSApp.terminate(nil) }
                } label: { Image(systemName: "ellipsis.circle") }
                    .menuStyle(.borderlessButton).fixedSize().help("Options").accessibilityLabel("Options")
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search", text: $store.query).textFieldStyle(.plain)
            }.font(.system(size: 12)).padding(8)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let error = store.error { Text(error).font(.caption).foregroundColor(.orange).textSelection(.enabled) }
                    if store.visible.isEmpty {
                        Text(store.updated == nil ? "No listener data yet" : "No matching listeners")
                            .foregroundColor(.secondary).frame(maxWidth: .infinity).padding(30)
                    }
                    ForEach(store.visible) { entry in
                        row(entry)
                        Divider().opacity(0.45)
                    }
                }
            }.frame(height: 330)
        }.padding(16).frame(width: 500)
            .coordinateSpace(name: "ports-panel")

    }
    func row(_ entry: Entry) -> some View { PortRow(store: store, entry: entry, onGeometry: onRowGeometry.map { callback in { callback(entry.id, $0) } }, onNativeHeader: onNativeHeader.map { callback in { callback(entry.id, $0) } }) }

}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let store = Store()
    var status: NSStatusItem!
    let popover = NSPopover()
    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateCount("…")
        status.button?.target = self; status.button?.action = #selector(toggle)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = PopoverContentController(content: PortsView(store: store), popover: popover)
        store.onCount = { [weak self] count in self?.updateCount(String(count)) }
        if let index = CommandLine.arguments.firstIndex(of: "--layout-evidence"), CommandLine.arguments.count > index + 1 {
            do { try layoutEvidence(at: URL(fileURLWithPath: CommandLine.arguments[index + 1])); NSApp.terminate(nil) }
            catch { fputs("Layout evidence failed: \(error)\n", stderr); exit(4) }
            return
        }
        if let index = CommandLine.arguments.firstIndex(of: "--jitter-evidence"), CommandLine.arguments.count > index + 1 {
            do { try jitterEvidence(at: URL(fileURLWithPath: CommandLine.arguments[index + 1])); NSApp.terminate(nil) }
            catch { fputs("Jitter evidence failed: \(error)\n", stderr); exit(5) }
            return
        }
        store.start()
        if CommandLine.arguments.contains("--ui-smoke-test") {
            toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                guard self.status.button != nil, self.popover.isShown, self.popover.contentViewController?.view.window != nil else { exit(2) }
                guard let button = self.status.button,
                      button.image?.isTemplate == true,
                      button.image?.size.height == 18,
                      button.imagePosition == .imageOnly,
                      button.imageScaling == .scaleNone else { exit(3) }
                self.store.query = "3000"; self.store.devOnly = true
                self.popover.contentViewController?.view.layoutSubtreeIfNeeded()
                self.store.query = ""; self.store.devOnly = false
                print("UI_SMOKE_OK"); NSApp.terminate(nil)
            }
        }
    }
    func updateCount(_ text: String) {
        let artwork = StatusArtwork.make(text)
        status.length = ceil(artwork.image.size.width + 12)
        status.button?.title = ""
        status.button?.image = artwork.image
        status.button?.imagePosition = .imageOnly
        status.button?.imageScaling = .scaleNone
        status.button?.setAccessibilityLabel("LocalPorts, \(text) TCP listeners")
        status.button?.toolTip = "LocalPorts · \(text) TCP listeners"
    }
    func popoverDidShow(_ notification: Notification) { if !CommandLine.arguments.contains("--layout-evidence") && !CommandLine.arguments.contains("--jitter-evidence") { store.setPanelOpen(true) } }
    func popoverDidClose(_ notification: Notification) { if !CommandLine.arguments.contains("--layout-evidence") && !CommandLine.arguments.contains("--jitter-evidence") { store.setPanelOpen(false) } }
    func applicationWillTerminate(_ notification: Notification) { store.timer?.invalidate() }
    @objc func toggle() {
        if popover.isShown { popover.performClose(nil) }
        else if let button = status.button { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY); NSApp.activate(ignoringOtherApps: true) }
    }
}

if CommandLine.arguments.contains("--diagnose") {
    struct Report: Encodable { let schemaVersion = 1; let listeners: [Entry] }
    do {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        print(String(decoding: try encoder.encode(Report(listeners: Inspector.scan())), as: UTF8.self))
    } catch { fputs("LocalPorts: \(error.localizedDescription)\n", stderr); exit(1) }
} else {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate(); app.delegate = delegate
    app.run()
}
