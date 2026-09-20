import XCTest
@testable import PortsCore
final class CoreTests: XCTestCase {
    func testListenersDeduplicateFamiliesButKeepAddresses() {
        let text = "p42\ncnode\nu501\nf1\nn*:3000\nf2\nn*:3000\nf3\nn127.0.0.1:3001\np43\ncpython\nu501\nf4\nn[::1]:8000\n"
        let rows = Listener.parse(text)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows.first?.port, 3000)
        XCTAssertEqual(rows.last?.host, "::1")
        XCTAssertEqual(rows.first?.pid, 42)
    }
}
