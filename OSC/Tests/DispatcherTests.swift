import XCTest
@testable import OSC
final class RouterTests: XCTestCase {
	func testScenario() {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 4
		let dispatcher = Dispatcher<IPv4Endpoint>()
		dispatcher.add(for: /root\/sub?/) { _, _, _ in
			expectation.fulfill()
		}
		dispatcher.add(for: /root\/sub?/) { _, _, _ in
			expectation.fulfill()
		}
		dispatcher.receive(("/root/sub1", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub2", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub3", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub4", IPv4Endpoint(addr: .any, port: .any)))
		wait(for: [expectation], timeout: 1)
	}
}
