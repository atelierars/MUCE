import Testing
import Combine
import Foundation
import Async_
@testable import Socket
@Suite
struct UdpSocketTests {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 32) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	func scenario<Endpoint: IPEndpoint>(for endpoint: Endpoint) async throws {
		try await withThrowingDiscardingTaskGroup { group in
			let server = try UdpSocket<Endpoint>.new.get()
			try server.set(reuseAddr: true).get()
			try server.set(reusePort: true).get()
			try server.bind(on: endpoint).get()
			#expect(group.isEmpty)
			group.addTask {
				let (packet, client) = try server.recv(count: 1024).get()
				#expect(packet == req)
				let sent = server.send(data: res, to: client)
				#expect(sent == .success(res.count))
			}
			try await Task.sleep(for: .milliseconds(42))
			group.addTask {
				let client = try UdpSocket<Endpoint>.new.get()
				let sent = client.send(data: req, to: endpoint)
				#expect(sent == .success(req.count))
				let (packet, target) = try client.recv(count: 1024).get()
				#expect(packet == res)
				#expect(target == endpoint)
			}
			#expect(!group.isEmpty)
		}
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v4() async throws {
		try await scenario(for: IPv4Endpoint(addr: .loopback, port: 2048))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v6() async throws {
		try await scenario(for: IPv6Endpoint(addr: .loopback, port: 2049))
	}
}
