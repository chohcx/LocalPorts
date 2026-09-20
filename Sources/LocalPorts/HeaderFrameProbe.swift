import AppKit
import SwiftUI

/// Native geometry witness, enabled only by the disclosure regression harness.
struct HeaderFrameProbe: NSViewRepresentable {
    let receive: (NSView) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        receive(view)
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
