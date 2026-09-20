import Foundation
import Darwin

public struct ProcessIdentity: Codable, Equatable {
    public let uid: UInt32
    public let startSeconds: UInt64
    public var startMicroseconds: UInt64
}
public struct Metrics: Codable {
    public let cpu: Double
    public let rssKB: Int
    public let elapsed: String
}
public struct Entry: Codable, Identifiable {
    public let listener: Listener
    public let identity: ProcessIdentity?
    public let metrics: Metrics?
    public let cwd: String?
    public var id: String {
        guard let identity = identity else { return listener.id + ":unknown" }
        return listener.id + ":\(identity.startSeconds):\(identity.startMicroseconds)"
    }
}
public enum InspectionError: LocalizedError {
    case failed(String)
    public var errorDescription: String? { if case let .failed(message) = self { return message }; return nil }
}
public enum Inspector {
    static func run(_ path: String, _ args: [String], allowed: Set<Int32> = [0]) throws -> String {
        let task = Process(), output = Pipe()
        task.executableURL = URL(fileURLWithPath: path); task.arguments = args
        task.standardOutput = output; task.standardError = FileHandle.nullDevice
        var env = ProcessInfo.processInfo.environment; env["LC_ALL"] = "C"; task.environment = env
        try task.run()
        let timeout = DispatchWorkItem { if task.isRunning { task.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 8, execute: timeout)
        let data = output.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit(); timeout.cancel()
        guard allowed.contains(task.terminationStatus) else { throw InspectionError.failed("\(URL(fileURLWithPath: path).lastPathComponent) failed (exit \(task.terminationStatus))") }
        return String(decoding: data, as: UTF8.self)
    }
    public static func identity(_ pid: Int32) -> ProcessIdentity? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return ProcessIdentity(uid: info.pbi_uid, startSeconds: info.pbi_start_tvsec, startMicroseconds: info.pbi_start_tvusec)
    }
    public static func scan() throws -> [Entry] {
        let listeners = Listener.parse(try run("/usr/sbin/lsof", ["-nP", "-w", "-iTCP", "-sTCP:LISTEN", "-Fpcun"], allowed: [0, 1]))
        guard !listeners.isEmpty else { return [] }
        let pids = Set(listeners.map(\.pid)).sorted()
        var metrics: [Int32: Metrics] = [:], identities: [Int32: ProcessIdentity] = [:], dirs: [Int32: String] = [:]
        for pid in pids { identities[pid] = identity(pid) }
        let ps = try run("/bin/ps", ["-p", pids.map(String.init).joined(separator: ","), "-o", "pid=,%cpu=,rss=,etime="], allowed: [0, 1])
        for line in ps.split(separator: "\n") {
            let fields = line.split(whereSeparator: \.isWhitespace)
            if fields.count == 4, let pid = Int32(fields[0]), let cpu = Double(fields[1]), let rss = Int(fields[2]) {
                metrics[pid] = Metrics(cpu: cpu, rssKB: rss, elapsed: String(fields[3]))
            }
        }
        let cwdText = try run("/usr/sbin/lsof", ["-a", "-p", pids.map(String.init).joined(separator: ","), "-d", "cwd", "-Fn"], allowed: [0, 1])
        var pid: Int32 = 0
        for line in cwdText.split(separator: "\n") {
            if line.first == "p" { pid = Int32(line.dropFirst()) ?? 0 }
            if line.first == "n" { dirs[pid] = String(line.dropFirst()) }
        }
        return listeners.map { row in
            let stable = identities[row.pid] != nil && identities[row.pid] == identity(row.pid)
            return Entry(listener: row, identity: stable ? identities[row.pid] : nil, metrics: stable ? metrics[row.pid] : nil, cwd: stable ? dirs[row.pid] : nil)
        }
    }
    public static func terminate(pid: Int32, expected: ProcessIdentity) throws {
        guard pid > 1, pid != getpid(), expected.uid == getuid(), identity(pid) == expected else {
            throw InspectionError.failed("Stop refused: process identity changed, permission denied, or protected process.")
        }
        guard Darwin.kill(pid, SIGTERM) == 0 else { throw InspectionError.failed("SIGTERM failed: \(String(cString: strerror(errno)))") }
    }
}
