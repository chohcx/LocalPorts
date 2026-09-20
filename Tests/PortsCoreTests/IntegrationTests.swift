import XCTest
import Darwin
@testable import PortsCore
final class IntegrationTests: XCTestCase {
    func testOwnServerDiscoveryMetricsAndSafeTermination() throws {
        let child = Process(), pipe = Pipe()
        child.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        child.arguments = ["-u", "-c", "import socket,time; s=socket.socket(); s.bind(('127.0.0.1',0)); s.listen(); print(s.getsockname()[1],flush=True); time.sleep(60)"]
        child.standardOutput = pipe
        try child.run()
        defer { if child.isRunning { child.terminate() }; child.waitUntilExit() }
        let port = Int(String(decoding: pipe.fileHandleForReading.availableData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))!
        let row = try XCTUnwrap(Inspector.scan().first { $0.listener.pid == child.processIdentifier && $0.listener.port == port })
        XCTAssertGreaterThan(row.metrics?.rssKB ?? 0, 0)
        XCTAssertNotNil(row.metrics?.cpu)
        XCTAssertNotNil(row.identity)
        XCTAssertNotNil(row.cwd)
        var wrong = try XCTUnwrap(row.identity)
        wrong.startMicroseconds += 1
        XCTAssertThrowsError(try Inspector.terminate(pid: child.processIdentifier, expected: wrong))
        XCTAssertTrue(child.isRunning)
        try Inspector.terminate(pid: child.processIdentifier, expected: try XCTUnwrap(row.identity))
        child.waitUntilExit()
        XCTAssertFalse(try Inspector.scan().contains { $0.listener.pid == child.processIdentifier })
    }
}
