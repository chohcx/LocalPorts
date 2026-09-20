#!/usr/bin/env python3
"""UI contracts and action safety regression checks; native rendering is separate."""
import pathlib
import re
root = pathlib.Path(__file__).resolve().parent.parent
source = '\n'.join(p.read_text() for p in (root / 'Sources/LocalPorts').glob('*.swift'))
assert 'Text("LocalPorts").font(.system(size: 14, weight: .semibold))' in source, 'Compact title'
feedback = (root / 'Sources/LocalPorts/ActionFeedbackStyle.swift').read_text()
assert '.background(Color.black' in feedback and 'Color.accentColor' not in feedback, 'Neutral dark action backgrounds'
assert '.frame(height: 330)' in source, 'User-approved fixed scroll viewport must not resize with disclosure/search/polling'
assert 'Text(":\\(String(entry.listener.port))")' in source, 'Port identifiers must not receive locale thousands separators'
assert 'Image(systemName: StatusArtwork.symbol)' not in (root / 'Sources/LocalPorts/main.swift').read_text(), 'Panel header must be text-only'
assert 'detail("Binding", entry.listener.host)' in source, 'Expanded binding must preserve wildcard hosts'
assert 'Text(entry.listener.displayHost)' in source, 'Compact port column must visibly identify its host'
assert 'detail("Endpoint", entry.listener.displayEndpoint)' in source, 'Full host:port must be visible in details'
assert 'HStack(alignment: .center, spacing: 10)' in source, 'Explicit header vertical alignment'
assert '.frame(width: 500)' in source, 'Keep the panel compact on a 13-inch display'
for symbol in ['terminal', 'cpu', 'memorychip', 'clock', 'chevron.right']:
    assert f'"{symbol}"' in source, f'Missing compact metadata/chevron icon: {symbol}'
assert 'Divider().padding(.horizontal, 12).opacity(0.30)' in source, 'Row separators must end inside rounded hover corners without changing vertical geometry'
assert 'Color.primary.opacity(0.045) : Color.clear, in: RoundedRectangle(cornerRadius: 8)' in source, 'Subtle neutral rounded row hover'
assert '.contentShape(Rectangle())' in source and '.onHover' in source
assert '.frame(width: 24, height: 24)' in source, 'Centered trailing chevron target'
assert 'minHeight: 56' in source, 'Full-width header must have a comfortable hit target'
for action in ['NSWorkspace.shared.open(entry.listener.localURL)', 'NSPasteboard.general.setString(entry.listener.localURL.absoluteString, forType: .string)', 'NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cwd)', 'store.terminal(entry)', 'store.stop(entry)', 'guard alert.runModal() == .alertSecondButtonReturn', 'Inspector.terminate(pid: entry.listener.pid, expected: identity)', 'entry.identity?.uid != getuid() || entry.listener.pid <= 1 || entry.listener.pid == getpid()']:
    assert action in source, action
assert 'DisclosureGroup(' not in source, 'Header must be one whole-width button, not the arrow-only native disclosure'
assert '.accessibilityIdentifier("row-header-' in source
assert '.accessibilityIdentifier("copy-url-' in source
assert 'Text("DEV")' not in source, 'Runtime badge must not claim a deployment environment'
assert 'ProgressView()' not in source, 'Polling must not flash a spinner'
assert '@Published var expanded = Set<String>()' in source, 'Expansion belongs to listener identity, not row position'
assert 'popoverDidClose' in source and 'setPanelOpen(false)' in source, 'Closing outside the panel must slow polling'
assert 'panelOpen ? 2 : 10' in source and 'timer?.invalidate()' in source, 'Adaptive timer must replace its predecessor'
assert '@Environment(\.accessibilityReduceMotion)' in source, 'Respect reduced motion'
assert 'ActionFeedbackStyle(destructive:' in source, 'Action controls need explicit hover/press feedback'
assert '.onHover { hovered = $0 }' in source and 'configuration.isPressed' in source
assert '.easeOut(duration: 0.12)' in source, 'Keep microanimation brief and interaction-only'
assert 'compactElapsed(metrics.elapsed)' in source, 'Readable uptime'
assert '.easeInOut(duration: 0.18)' in source and 'withAnimation(reduceMotion ? nil' in source, 'Interaction-only disclosure animation'
assert '.clipped()' in source and '.allowsHitTesting(store.expanded.contains(entry.id))' in source, 'Hidden details clipped and noninteractive'
for path in (root / 'Sources').rglob('*.swift'):
    assert not re.search(r'[\u3400-\u9fff]', path.read_text()), f'English-first source strings: {path.name}'
assert 'alert.addButton(withTitle: "Cancel"); alert.addButton(withTitle: "Send SIGTERM")' in source, 'Cancel remains the default confirmation action'
assert '.help("Refresh").accessibilityLabel("Refresh")' in source
assert '.help("Options").accessibilityLabel("Options")' in source
print('PASS: shared icon, compact panel, metric columns, external-action/safe-stop wiring preserved (source contract, not end-to-end clicks)')
