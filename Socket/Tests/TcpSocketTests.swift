import Testing
import Foundation
@testable import Socket
@Suite
struct TcpSocketTests {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	func scenario<Endpoint: IPEndpoint>(for endpoint: Endpoint) async throws {
		try await withThrowingDiscardingTaskGroup { group in
			let server = try TcpSocket<Endpoint>.new.get()
			try server.set(timeoutRecv: .seconds(1)).get()
			try server.set(timeoutSend: .seconds(1)).get()
			try server.set(reuseAddr: true).get()
			try server.set(reusePort: true).get()
			try server.bind(on: endpoint).get()
			try server.listen(count: 1).get()
			group.addTask {
				let (socket, client) = try server.accept().get()
				#expect(client.addr == endpoint.addr)
				let packet = try socket.recv(count: 1024).get()
				#expect(packet == req)
				let sent = socket.send(data: res)
				#expect(sent ==  .success(res.count))
			}
			let client = try TcpSocket<Endpoint>.new.get()
			client.connect(to: endpoint)
			let sent = client.send(data: req)
			#expect(sent == .success(req.count))
			let packet = try client.recv(count: 1024).get()
			#expect(packet == res)
		}
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func testScenarioV4() async throws {
		try await scenario(for: IPv4Endpoint(addr: .loopback, port: 2044))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func testScenarioV6() async throws {
		try await scenario(for: IPv6Endpoint(addr: .loopback, port: 2046))
	}
}
