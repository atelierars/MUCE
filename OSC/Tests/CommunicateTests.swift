import XCTest
@testable import OSC
final class CommunicationTests: XCTestCase {
	func testUdp() async throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 2
		let receiver = OSC.UdpReceiver(on: IPv4Endpoint(addr: .loopback, port: 5598))
		Task {
			for try await (message, endpoint) in receiver.values.prefix(1) {
				XCTAssertEqual(endpoint.addr, .loopback)
				switch message {
				case "/address":
					XCTAssertEqual(message.arguments, [1,2.0,"3",false,true,nil])
					expectation.fulfill()
				default:
					XCTFail()
				}
			}
		}
		Task {
			for try await (message, endpoint) in receiver.values.prefix(1) {
				XCTAssertEqual(endpoint.addr, .loopback)
				switch message {
				case "/address":
					XCTAssertEqual(message.arguments, [1,2.0,"3",false,true,nil])
					expectation.fulfill()
				default:
					XCTFail()
				}
			}
		}
		let sender = OSC.UdpSender<IPv4Endpoint>()
		try await Task.sleep(for: Duration.milliseconds(1)) // dispatch coroutine
		sender.send(packet: .Bundle(at: 0, packets: [
			.Message(address: "/address", arguments: [1,2.0,"3",false,true,nil])
		]), to: .init(addr: .loopback, port: 5598))
		try await Task.sleep(for: Duration.milliseconds(1)) // dispatch coroutine
		sender.send(packet: .Bundle(at: 0, packets: [
			.Message(address: "/address", arguments: [1,2.0,"3",false,true,nil])
		]), to: .init(addr: .loopback, port: 5598))
		await fulfillment(of: [expectation], timeout: 3)
	}
}
