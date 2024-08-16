import XCTest
import Network
import Combine
@testable import Socket
final class IPEndpointTestCases: XCTestCase {
	func testIPv4Endpoint() {
		let origin = IPv4Address("1.2.3.4").unsafelyUnwrapped
		let eval = IPv4Endpoint(addr: origin, port: .http)
		XCTAssertEqual(eval.addr, origin)
		XCTAssertEqual(eval.port, 80)
		XCTAssertEqual(UInt32(bigEndian: eval.sin_addr.s_addr), 0x01020304)
		XCTAssertEqual(UInt16(bigEndian: eval.sin_port), 80)
	}
}
