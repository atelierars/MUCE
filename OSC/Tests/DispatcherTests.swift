import XCTest
@testable import OSC
final class RouterTests: XCTestCase {
	func testServerRegex() throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 8
		let dispatcher = Dispatcher<IPv4Endpoint>()
		// accept multiple address, we can capture the elements by using regex
		dispatcher.invoke(for: /^\/root\/sub(?<number>.)$/) { address, _, _ in
			// evaluate captured values
			XCTAssertTrue(address.number.allSatisfy { $0.isNumber })
			expectation.fulfill()
		}
		dispatcher.invoke(for: /^\/root\/sud.$/) { _, _, _ in
			XCTFail()
		}
		// we can use glob style, same as osc
		dispatcher.invoke(for: try Regex(osc: "/root/sub?")) { _, _, _ in
			expectation.fulfill()
		}
		dispatcher.receive(("/root/sub1", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub2", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub3", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub4", IPv4Endpoint(addr: .any, port: .any)))
		wait(for: [expectation], timeout: 0)
	}
	// In this scenario, a message will be accepted by multiple handlers
	// a message /root/sub?/{foo,bar} will be accepted by multiple handlers /root/sub1/foo, /root/sub2/bar
	func testClientQuery() throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 2
		let dispatcher = Dispatcher<IPv4Endpoint>()
		dispatcher.invoke(for: "/root/sub1/foo") { _, _, _ in
			expectation.fulfill()
		}
		dispatcher.invoke(for: "/root/sub2/bar") { _, _, _ in
			expectation.fulfill()
		}
		// not recept
		dispatcher.invoke(for: "/root/sub3/foobar") { _, _, _ in
			XCTFail()
		}
		// call multiple resources like query, by using glob form
		dispatcher.receive(("/root/sub?/{foo,bar}", IPv4Endpoint(addr: .any, port: .any)))
		wait(for: [expectation], timeout: 0)
	}
}
