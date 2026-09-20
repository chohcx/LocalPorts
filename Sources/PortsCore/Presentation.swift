import Foundation

/// Display-only ps [[dd-]hh:]mm:ss abbreviation; invalid input stays diagnosable.
public func compactElapsed(_ raw: String) -> String {
    let dayParts = raw.split(separator: "-", omittingEmptySubsequences: false)
    guard dayParts.count <= 2 else { return raw }
    let clock = dayParts.last!.split(separator: ":", omittingEmptySubsequences: false)
    guard (2...3).contains(clock.count), dayParts.count == 1 || clock.count == 3 else { return raw }
    func number(_ text: Substring) -> Int? {
        guard !text.isEmpty, text.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
        return Int(text)
    }
    guard let seconds = number(clock.last!), seconds < 60,
          let minutes = number(clock[clock.count - 2]), minutes < 60,
          let hours = clock.count == 3 ? number(clock[0]) : 0,
          let days = dayParts.count == 2 ? number(dayParts[0]) : 0,
          hours < 24 else { return raw }
    if days > 0 { return "\(days)d\(hours)h" }
    if hours > 0 { return "\(hours)h\(minutes)m" }
    if minutes > 0 { return "\(minutes)m\(seconds)s" }
    return "\(seconds)s"
}
public extension Listener {
    var isDeveloper: Bool {
        let name = executable.lowercased()
        return ["node", "vite", "next", "python", "ruby", "rails", "bun", "deno", "uvicorn", "gunicorn", "puma"].contains { name.hasPrefix($0) } || name == "go"
    }
    func matches(_ query: String, devOnly: Bool) -> Bool {
        (!devOnly || isDeveloper) && (query.isEmpty || "\(executable) \(pid) \(host) \(port)".localizedCaseInsensitiveContains(query))
    }
    // Display aliases are not protocol detection; URL actions retain the exact loopback family.
    var displayHost: String {
        if ["*", "0.0.0.0", "::", "127.0.0.1", "::1"].contains(host) { return "localhost" }
        return host.contains(":") ? "[\(host)]" : host
    }
    var displayEndpoint: String { "\(displayHost):\(String(port))" }
    var localURL: URL {
        let address = host == "::1" ? "[::1]" : (host == "*" || host == "0.0.0.0" || host == "::" ? "localhost" : (host.contains(":") ? "[\(host)]" : host))
        return URL(string: "http://\(address):\(port)")!
    }
}
