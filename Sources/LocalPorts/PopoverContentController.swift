import AppKit
import SwiftUI

/// The viewport is fixed; disclosure, search and polling only update its contents.
final class PopoverContentController: NSHostingController<PortsView> {
    init(content: PortsView, popover: NSPopover) {
        super.init(rootView: content)
        preferredContentSize = NSSize(width: 500, height: 430)
        popover.contentSize = preferredContentSize
    }
    @MainActor required dynamic init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
