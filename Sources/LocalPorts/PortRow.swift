import AppKit
import SwiftUI
import PortsCore

private struct RowGeometryKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct DetailReveal: AnimatableModifier {
    var height: CGFloat
    var opacity: Double
    var animatableData: AnimatablePair<CGFloat, Double> {
        get { AnimatablePair(height, opacity) }
        set { height = newValue.first; opacity = newValue.second }
    }
    func body(content: Content) -> some View {
        content.frame(height: height, alignment: .top).clipped().opacity(opacity)
    }
}

struct PortRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var store: Store
    let entry: Entry
    @State private var hovered = false
    @State private var detailHeight: CGFloat = 0
    var onGeometry: (([String: CGRect]) -> Void)? = nil
    var onNativeHeader: ((NSView) -> Void)? = nil
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                    if store.expanded.contains(entry.id) { store.expanded.remove(entry.id) }
                    else { store.expanded.insert(entry.id) }
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(":\(String(entry.listener.port))")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.accentColor)
                        Text(entry.listener.displayHost)
                            .font(.system(size: 9)).foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.middle)
                    }.frame(width: 65, alignment: .leading)
                        .help(entry.listener.displayEndpoint)
                        .background(geometry("port"))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.cwd.map { URL(fileURLWithPath: $0).lastPathComponent }.flatMap { $0.isEmpty ? nil : $0 } ?? entry.listener.executable)
                            .font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                            .lineLimit(1).truncationMode(.middle)
                        HStack(spacing: 8) {
                            metadata("terminal", entry.listener.executable.lowercased(), "Process / runtime; not the original Terminal tab")
                            if let metrics = entry.metrics {
                                metadata("clock", compactElapsed(metrics.elapsed), "Process uptime (not port uptime): \(metrics.elapsed); format [[days-]hours:]minutes:seconds")
                                metadata("cpu", String(format: "%.1f%%", metrics.cpu), "Process CPU reported by ps")
                                metadata("memorychip", String(format: "%.0f MB", Double(metrics.rssKB) / 1024), "Process resident memory")
                            }
                        }.font(.system(size: 9)).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                        .background(geometry("metadata"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(store.expanded.contains(entry.id) ? 90 : 0))
                        .foregroundColor(.secondary).frame(width: 24, height: 24)
                        .background(geometry("chevron"))
                }.padding(.horizontal, 8).frame(maxWidth: .infinity, minHeight: 56)
                    .background(geometry("header"))
                    .background { if let receive = onNativeHeader { HeaderFrameProbe(receive: receive) } }
                    .contentShape(Rectangle())
                    .background(hovered ? Color.primary.opacity(0.07) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
            }.buttonStyle(.plain)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
                .accessibilityIdentifier("row-header-\(entry.listener.port)")
                .accessibilityLabel("\(entry.listener.displayEndpoint), \(entry.listener.executable), details")
                .accessibilityValue(store.expanded.contains(entry.id) ? "Expanded" : "Collapsed")
            VStack(alignment: .leading, spacing: 8) {
                    detail("PID", String(entry.listener.pid))
                    detail("Command", entry.listener.executable)
                    detail("Directory", entry.cwd ?? "Unavailable")
                    detail("Binding", entry.listener.host)
                    detail("Endpoint", entry.listener.displayEndpoint)
                    HStack(spacing: 8) {
                        action("arrow.up.right.square", "Open HTTP URL (non-HTTP services may not respond)") { NSWorkspace.shared.open(entry.listener.localURL) }
                        action("doc.on.doc", "Copy URL") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(entry.listener.localURL.absoluteString, forType: .string) }
                            .accessibilityIdentifier("copy-url-\(entry.listener.port)")
                        action("folder", "Reveal working directory in Finder") { if let cwd = entry.cwd { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cwd) } }.disabled(entry.cwd == nil)
                        action("terminal", "Open a new Terminal window in the working directory") { store.terminal(entry) }.disabled(entry.cwd == nil)
                        Spacer()
                        action("stop.circle", "Stop process (SIGTERM, confirmation required)") { store.stop(entry) }
                            .foregroundColor(.red)
                            .disabled(entry.identity?.uid != getuid() || entry.listener.pid <= 1 || entry.listener.pid == getpid())
                    }.padding(.top, 2).background(geometry("actions"))
                }.padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 12)
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { proxy in
                    Color.clear.onAppear { detailHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { detailHeight = $0 }
                })
                .modifier(DetailReveal(height: store.expanded.contains(entry.id) ? detailHeight : 0,
                                       opacity: store.expanded.contains(entry.id) ? 1 : 0))
                .allowsHitTesting(store.expanded.contains(entry.id))
                .accessibilityHidden(!store.expanded.contains(entry.id))
                .background(geometry("detailViewport"))
        }.onPreferenceChange(RowGeometryKey.self) { onGeometry?($0) }
    }
    @ViewBuilder private func geometry(_ part: String) -> some View {
        if onGeometry != nil {
            GeometryReader { proxy in
                Color.clear.preference(key: RowGeometryKey.self, value: [part: proxy.frame(in: .named("ports-panel"))])
            }
        }
    }
    func metadata(_ icon: String, _ value: String, _ help: String) -> some View {
        HStack(spacing: 3) { Image(systemName: icon); Text(value).lineLimit(1) }.help(help)
    }
    func detail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label).foregroundColor(.secondary).frame(width: 64, alignment: .leading)
            Text(value).textSelection(.enabled).lineLimit(2).truncationMode(.middle)
        }.font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading)
    }
    func action(_ icon: String, _ title: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Image(systemName: icon).font(.system(size: 14)).frame(width: 30, height: 28)
                .contentShape(Rectangle())

        }.buttonStyle(ActionFeedbackStyle(destructive: icon == "stop.circle")).help(title).accessibilityLabel(title)
    }
}
