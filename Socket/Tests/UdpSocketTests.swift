import XCTest
import Combine
@testable import Socket
final class UdpSocketTests: XCTestCase {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 32) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	func scenario<Endpoint: IPEndpoint>(for endpoint: Endpoint) throws {
		let request = XCTestExpectation(description: "request")
		let response = XCTestExpectation(description: "response")
		let server = try UdpSocket<Endpoint>.new.get()
		try server.set(reuseAddr: true).get()
		try server.set(reusePort: true).get()
		try server.bind(on: endpoint).get()
		Task {
			let(packet, client) = try server.recv(count: 1024).get()
			XCTAssertEqual(packet, req)
			let sent = server.send(data: res, to: client)
			XCTAssertEqual(sent, .success(res.count))
			request.fulfill()
		}
		let client = try UdpSocket<Endpoint>.new.get()
		let sent = client.send(data: req, to: endpoint)
		XCTAssertEqual(sent, .success(req.count))
		let(packet, _) = try client.recv(count: 1024).get()
		XCTAssertEqual(packet, res)
		response.fulfill()
		wait(for: [request, response], timeout: 30)
	}
	func testScenarioV4() throws {
		try scenario(for: IPv4Endpoint(addr: .loopback, port: 2048))
	}
	func testScenarioV6() throws {
		try scenario(for: IPv6Endpoint(addr: .loopback, port: 2049))
	}
}
