import Testing
import Synchronization
import Foundation
@testable import Socket
@Suite
struct UdpStreamTests {
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
			let server = try UdpStream.Incoming(on: endpoint).get()
			group.addTask {
				let status = Atomic(false)
				for try await (data, endpoint) in server.values.prefix(1) {
					#expect(data == req)
					let sent = try server.send(data: res, to: endpoint).get()
					#expect(sent == res.count)
					status.store(true, ordering: .releasing)
				}
				let done = status.load(ordering: .acquiring)
				#expect(done)
			}
			try await Task.sleep(for: Duration.milliseconds(42))
			let client = try UdpStream<Endpoint>.Any().get()
			group.addTask {
				let status = Atomic(false)
				for try await (data, receiver) in client.values.prefix(1) {
					#expect(data == res)
					#expect(endpoint.addr == receiver.addr)
					#expect(endpoint.port == receiver.port)
					status.store(true, ordering: .releasing)
				}
				let done = status.load(ordering: .acquiring)
				#expect(done)
			}
			let sent = try client.send(data: req, to: endpoint).get()
			#expect(sent == req.count)
			#expect(!group.isEmpty)
		}
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func testScenarioV4() async throws {
		try await scenario(for: IPv4Endpoint(addr: .loopback, port: 2048))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func testScenarioV6() async throws {
		try await scenario(for: IPv6Endpoint(addr: .loopback, port: 2049))
	}
}
