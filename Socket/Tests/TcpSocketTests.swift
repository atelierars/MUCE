import XCTest
@testable import Socket
final class TcpSocketTests: XCTestCase {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
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
		let server = try TcpSocket<Endpoint>.new.get()
		try server.set(timeoutRecv: .seconds(1)).get()
		try server.set(timeoutSend: .seconds(1)).get()
		try server.set(reuseAddr: true).get()
		try server.set(reusePort: true).get()
		try server.bind(on: endpoint).get()
		try server.listen(count: 1).get()
		Task {
			let (socket, client) = try server.accept().get()
			XCTAssertEqual(client.addr, endpoint.addr)
			let packet = try socket.recv(count: 1024).get()
			XCTAssertEqual(packet, req)
			let sent = socket.send(data: res)
			XCTAssertEqual(sent, .success(res.count))
			request.fulfill()
		}
		let client = try TcpSocket<Endpoint>.new.get()
		client.connect(to: endpoint)
		let sent = client.send(data: req)
		XCTAssertEqual(sent, .success(req.count))
		let packet = try client.recv(count: 1024).get()
		XCTAssertEqual(packet, res)
		response.fulfill()
		wait(for: [request, response], timeout: 30)
	}
//	func testScenarioV4() throws {
//		try scenario(for: IPv4Endpoint(addr: .loopback, port: 2044))
//	}
//	func testScenarioV6() throws {
//		try scenario(for: IPv6Endpoint(addr: .loopback, port: 2046))
//	}
}
