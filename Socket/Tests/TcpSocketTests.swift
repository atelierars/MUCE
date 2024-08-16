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
	func scenario<Endpoint: IPEndpoint>(for endpoint: Endpoint) async throws {
		let request = XCTestExpectation(description: "request")
		let response = XCTestExpectation(description: "response")
		let server = try TcpSocket<Endpoint>.new.get()
		try await server.set(timeoutRecv: .seconds(1)).get()
		try await server.set(timeoutSend: .seconds(1)).get()
		try await server.set(reuseAddr: true).get()
		try await server.set(reusePort: true).get()
		try await server.bind(on: endpoint).get()
		try await server.listen(count: 1).get()
		Task {
			let (socket, client) = try await server.accept().get()
			XCTAssertEqual(client.addr, endpoint.addr)
			let packet = try await socket.recv(count: 1024).get()
			XCTAssertEqual(packet, req)
			let sent = await socket.send(data: res)
			XCTAssertEqual(sent, .success(res.count))
			request.fulfill()
		}
		let client = try TcpSocket<Endpoint>.new.get()
		await client.connect(to: endpoint)
		let sent = await client.send(data: req)
		XCTAssertEqual(sent, .success(req.count))
		let packet = try await client.recv(count: 1024).get()
		XCTAssertEqual(packet, res)
		response.fulfill()
		await fulfillment(of: [request, response], timeout: 30)
	}
	func testScenarioV4() async throws {
		try await scenario(for: IPv4Endpoint(addr: .loopback, port: 2048))
	}
	func testScenarioV6() async throws {
		try await scenario(for: IPv6Endpoint(addr: .loopback, port: 2049))
	}
}
