import XCTest
@testable import PortsCore
final class PresentationTests: XCTestCase {
    func testElapsedAbbreviations() {
        for (raw, expected) in [("08-02:34:56", "8d2h"), ("07:20:00", "7h20m"), ("43:12", "43m12s"), ("00:09", "9s"), ("00:00", "0s"), ("01:00:00", "1h0m"), ("01-00:00:00", "1d0h"), ("00-00:00:01", "1s")] {
            XCTAssertEqual(compactElapsed(raw), expected, raw)
        }
        for raw in ["", "unknown", "08-02:99:00", "1-24:00:00", "1-02:03", "-02:03", "00:60", "1:2:3:4", "999999999999999999999-00:00:00"] {
            XCTAssertEqual(compactElapsed(raw), raw)
        }
    }
    func testDisplayEndpointUsesLocalhostWithoutInventingDomainsOrPaths() {
        for (host, expected) in [("*", "localhost"), ("0.0.0.0", "localhost"), ("::", "localhost"), ("127.0.0.1", "localhost"), ("::1", "localhost"), ("192.168.1.20", "192.168.1.20"), ("2001:db8::1", "[2001:db8::1]")] {
            let listener = Listener.parse("p5\ncnode\nu501\nn\(host):8787\n")[0]
            XCTAssertEqual(listener.displayHost, expected)
            XCTAssertEqual(listener.displayEndpoint, "\(expected):8787")
            XCTAssertEqual(listener.host, host, "Raw Binding must be preserved")
            XCTAssertEqual(listener.localURL.scheme, "http")
            XCTAssertTrue(listener.localURL.path.isEmpty)
        }
    }
    func testRowIdentityPersistsAcrossMetricsButNotPIDReuse() {
        let listener = Listener.parse("p5\ncnode\nu501\nn*:3000\n")[0]
        let first = ProcessIdentity(uid: 501, startSeconds: 10, startMicroseconds: 20)
        let original = Entry(listener: listener, identity: first, metrics: nil, cwd: nil)
        let refreshed = Entry(listener: listener, identity: first, metrics: Metrics(cpu: 9, rssKB: 42, elapsed: "00:02"), cwd: "/example")
        let reused = Entry(listener: listener, identity: ProcessIdentity(uid: 501, startSeconds: 11, startMicroseconds: 20), metrics: nil, cwd: nil)
        XCTAssertEqual(original.id, refreshed.id)
        XCTAssertNotEqual(original.id, reused.id)
    }
    func testDeveloperFilterSearchAndSafeLocalURLs() {
        let node = Listener.parse("p5\ncnode\nu501\nn*:3000\n")[0]
        XCTAssertTrue(node.isDeveloper)
        XCTAssertTrue(node.matches("3000", devOnly: true))
        XCTAssertTrue(node.matches("NODE", devOnly: true))
        XCTAssertFalse(node.matches("8000", devOnly: true))
        XCTAssertEqual(node.localURL.absoluteString, "http://localhost:3000")
        let ipv6 = Listener.parse("p6\ncpostgres\nu501\nn[::1]:5432\n")[0]
        XCTAssertEqual(ipv6.localURL.absoluteString, "http://[::1]:5432")
        XCTAssertFalse(ipv6.isDeveloper)
        for name in ["node", "vite", "next-server", "python3.11", "ruby", "rails", "go", "bun", "deno", "uvicorn"] {
            XCTAssertTrue(Listener.parse("p5\nc\(name)\nu501\nn*:3000\n")[0].isDeveloper, name)
        }
    }
}
