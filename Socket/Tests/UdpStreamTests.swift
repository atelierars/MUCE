import XCTest
@testable import Socket
final class UdpStreamTests: XCTestCase {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 32) {
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
		let server = try UdpStream.Incoming(on: endpoint).get()
		Task {
			for try await (data, endpoint) in server.values.prefix(1) where data == req {
				request.fulfill()
				let sent = try server.send(data: res, to: endpoint).get()
				XCTAssertEqual(sent, res.count)
			}
		}
		try await Task.sleep(for: Duration.milliseconds(1))
		let client = try UdpStream<Endpoint>.Any().get()
		let sent = try client.send(data: req, to: endpoint).get()
		Task {
			for try await (data, endpoint) in client.values.prefix(1) where data == res {
				XCTAssertEqual(data, res)
				response.fulfill()
			}
		}
		XCTAssertEqual(sent, req.count)
		await fulfillment(of: [request, response], timeout: 6)
	}
	func testScenarioV4() async throws {
		try await scenario(for: IPv4Endpoint(addr: .loopback, port: 2048))
	}
	func testScenarioV6() async throws {
		try await scenario(for: IPv6Endpoint(addr: .loopback, port: 2049))
	}
}
