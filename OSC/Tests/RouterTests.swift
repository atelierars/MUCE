import XCTest
@testable import OSC
final class RouterTests: XCTestCase {
	func testScenario() {
		let helloworld = XCTestExpectation(description: "hello world")
		helloworld.expectedFulfillmentCount = 2
		let send = XCTestExpectation(description: "send")
//		let recv = XCTestExpectation(description: "recv")
//		var vtable = Router()
//		vtable.append(for: "/hello/world") {
//			XCTAssertTrue($1.isEmpty)
//			helloworld.fulfill()
//		}
//		vtable.append(for: /^\/hello\/world$/) {
//			XCTAssertTrue($1.isEmpty)
//			helloworld.fulfill()
//		}
//		vtable.append(for: /^\/(send)\/hello\/([a-z]+)/) {
//			XCTAssertEqual($0.1, "send")
//			XCTAssertEqual($0.2, "value")
//			XCTAssertEqual($1.dropFirst(0).first, 1)
//			XCTAssertEqual($1.dropFirst(1).first, 2.0)
//			XCTAssertEqual($1.dropFirst(2).first, "test")
//			send.fulfill()
//		}
//		vtable.append(for: /^\/(recv)\/hello\/([a-z]+)/) {(k, v)in
//			XCTFail()
//		}
//		vtable.dispatch(message: .init(address: "/hello/world", arguments: []))
//		vtable.dispatch(message: .init(address: "/send/hello/value", arguments: [1, 2.0, "test"]))
////		vtable.dispatch(message: .init(address: "/recv/hello/value", arguments: []))
//		wait(for: [helloworld, send], timeout: 0)
	}
}
