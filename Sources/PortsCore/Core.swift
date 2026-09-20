import Foundation
import Darwin

public struct Listener: Codable, Identifiable, Equatable {
    public let pid: Int32
    public let uid: UInt32
    public let executable: String
    public let host: String
    public let port: Int
    public var id: String { "\(pid):\(host):\(port)" }
    public static func parse(_ text: String) -> [Listener] {
        var pid: Int32 = 0, uid: UInt32 = UInt32.max, name = ""
        var rows: [Listener] = [], seen = Set<String>()
        for line in text.split(separator: "\n") {
            let value = String(line.dropFirst())
            switch line.first {
            case "p": pid = Int32(value) ?? 0; uid = UInt32.max; name = ""
            case "c": name = value
            case "u": uid = UInt32(value) ?? UInt32.max
            case "n":
                guard pid > 0, let colon = value.lastIndex(of: ":"), let port = Int(value[value.index(after: colon)...]), (1...65535).contains(port) else { continue }
                let host = String(value[..<colon]).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                let row = Listener(pid: pid, uid: uid, executable: name, host: host, port: port)
                if seen.insert(row.id).inserted { rows.append(row) }
            default: break
            }
        }
        return rows.sorted { ($0.pid, $0.port, $0.host) < ($1.pid, $1.port, $1.host) }
    }
}
